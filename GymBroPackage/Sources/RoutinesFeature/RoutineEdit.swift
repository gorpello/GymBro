import ComposableArchitecture
import Database
import Foundation
import Routing
import SQLiteData

/// Build or change a routine: name, days, group, ordered exercises with sets and supersets,
/// and a library list to add from. Changes stay in a `RoutineDraft` until Save or Start writes
/// them, so backing out discards them.
@Reducer
public struct RoutineEdit: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var draft = RoutineDraft()
        /// The routine being edited; `nil` until a new one is first saved.
        public var routineID: Routine.ID?
        /// The saved routine still has to be read into `draft`.
        public var isLoading: Bool
        @ObservationStateIgnored
        @Fetch public var library: [RoutineLibraryRow] = []
        public var searchText = ""

        public init(id: Routine.ID?) {
            self.routineID = id
            self.isLoading = id != nil
        }

        /// Library exercises matching the search that aren't in the routine yet.
        public var addable: [RoutineLibraryRow] {
            let added = Set(draft.exercises.map(\.id))
            return library.filter { !added.contains($0.id) }
        }
    }

    public enum Action: BindableAction {
        case addExerciseTapped(id: Exercise.ID)
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case draftLoaded(RoutineDraft)
        case moveExercises(from: IndexSet, to: Int)
        case removeExerciseTapped(id: Exercise.ID)
        case saveButtonTapped
        case setsChanged(id: Exercise.ID, delta: Int)
        case startButtonTapped
        case supersetToggled(id: Exercise.ID)
        case task
        /// 1 = Monday … 7 = Sunday.
        case weekdayTapped(Int)

        @CasePathable
        public enum Delegate {
            case navigate(Route)
        }
    }

    @Dependency(\.defaultDatabase) var database
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
            .onChange(of: \.searchText) { _, search in
                Reduce { state, _ in loadLibrary(state, search: search) }
            }
        Reduce { state, action in
            switch action {
            case let .addExerciseTapped(id):
                guard let row = state.library.first(where: { $0.id == id }),
                    !state.draft.exercises.contains(where: { $0.id == id })
                else { return .none }
                state.draft.exercises.append(
                    RoutineDraft.Item(
                        id: row.id,
                        art: row.art,
                        name: row.name,
                        setCount: row.mode == .cardio ? 1 : RoutineDraft.defaultSetCount
                    )
                )
                return .none
            case .binding, .delegate:
                return .none
            case let .draftLoaded(draft):
                state.draft = draft
                state.isLoading = false
                return .none
            case let .moveExercises(from, to):
                state.draft.exercises.move(fromOffsets: from, toOffset: to)
                return .none
            case let .removeExerciseTapped(id):
                state.draft.exercises.removeAll { $0.id == id }
                return .none
            case .saveButtonTapped:
                let write = save(&state)
                return .run { [dismiss] _ in
                    await withErrorReporting {
                        try await write()
                        await dismiss()
                    }
                }
            case let .setsChanged(id, delta):
                guard let index = state.draft.exercises.firstIndex(where: { $0.id == id }) else { return .none }
                let range = RoutineDraft.setRange
                let count = state.draft.exercises[index].setCount + delta
                state.draft.exercises[index].setCount = min(max(count, range.lowerBound), range.upperBound)
                return .none
            case .startButtonTapped:
                guard !state.draft.exercises.isEmpty else { return .none }
                let write = save(&state)
                return .run { [now, routineID = state.routineID] send in
                    await withErrorReporting {
                        try await write()
                        guard let routineID else { return }
                        // A workout already in progress is resumed instead (see `LiveWorkout.start`).
                        _ = try await database.write { db in
                            try LiveWorkout.start(db, routineID: routineID, now: now)
                        }
                        await send(.delegate(.navigate(.session)))
                    }
                }
            case let .supersetToggled(id):
                guard let index = state.draft.exercises.firstIndex(where: { $0.id == id }) else { return .none }
                state.draft.exercises[index].isChainedToNext.toggle()
                return .none
            case .task:
                let library = loadLibrary(state, search: state.searchText)
                guard state.isLoading, let routineID = state.routineID else { return library }
                return .merge(
                    library,
                    .run { send in
                        await withErrorReporting {
                            let draft = try await database.read { db in try RoutineDraft.fetch(db, id: routineID) }
                            await send(.draftLoaded(draft ?? RoutineDraft()))
                        }
                    }
                )
            case let .weekdayTapped(weekday):
                if state.draft.weekdays.remove(weekday) == nil { state.draft.weekdays.insert(weekday) }
                return .none
            }
        }
    }

    /// Gives a new routine its id, then returns the write that saves the draft under it.
    private func save(_ state: inout State) -> @Sendable () async throws -> Void {
        let routineID = state.routineID ?? uuid()
        state.routineID = routineID
        let draft = state.draft
        return { [database] in
            try await database.write { db in try draft.save(db, id: routineID) }
        }
    }

    /// Points the library at `search`; it keeps following the database from there.
    private func loadLibrary(_ state: State, search: String) -> Effect<Action> {
        .run { [library = state.$library] _ in
            await withErrorReporting {
                try await library.load(RoutineLibraryRow.Request(search: search)).task
            }
        }
        .cancellable(id: CancelID.library, cancelInFlight: true)
    }

    private enum CancelID { case library }
}

/// An exercise the editor offers to add.
@Selection
public struct RoutineLibraryRow: Equatable, Identifiable, Sendable {
    public var id: Exercise.ID
    /// Illustration name under `Art/`; empty for custom exercises.
    public var art: String
    public var equipment: Equipment
    public var mode: ExerciseMode
    public var name: String
    public var primaryMuscle: Muscle
}

extension RoutineLibraryRow {
    /// Every active exercise whose name contains `search` (ignoring case and accents), by name.
    public struct Request: FetchKeyRequest {
        public var search: String

        public init(search: String) {
            self.search = search
        }

        public func fetch(_ db: Database) throws -> [RoutineLibraryRow] {
            let query = search.trimmingCharacters(in: .whitespaces)
            return
                try Exercise
                .where { !$0.isArchived }
                .order(by: \.name)
                .select {
                    RoutineLibraryRow.Columns(
                        id: $0.id,
                        art: $0.art,
                        equipment: $0.equipment,
                        mode: $0.mode,
                        name: $0.name,
                        primaryMuscle: $0.primaryMuscle
                    )
                }
                .fetchAll(db)
                .filter { query.isEmpty || $0.name.localizedStandardContains(query) }
        }
    }
}

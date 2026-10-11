import ComposableArchitecture
import Database
import Foundation
import Routing
import SQLiteData

/// Quick workout builder. Step 1: tap muscles on the body map (or pick warm-up / cardio).
/// Step 2: review the exercises that fit, with GymMane's suggested picks ticked, and start.
@Reducer
public struct Train: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var equipmentFilter: Equipment?
        public var focus: TrainFocus?
        public var muscleFilter: String?
        public var options = TrainOptions()
        public var picked: Set<Exercise.ID> = []
        public var searchText = ""
        /// Body-map ids of the muscles tapped in step 1.
        public var selectedMuscles: Set<String> = []
        public var step: Step = .focus

        public init() {}
    }

    public enum Step: Hashable, Sendable {
        case focus, build
    }

    public enum Action: BindableAction {
        case backButtonTapped
        case binding(BindingAction<State>)
        case cardioButtonTapped
        case closeButtonTapped
        case continueButtonTapped
        case delegate(Delegate)
        case exerciseTapped(id: Exercise.ID)
        case muscleTapped(String)
        case optionsLoaded(TrainOptions)
        case startButtonTapped
        case warmupButtonTapped

        @CasePathable
        public enum Delegate {
            case navigate(Route)
        }
    }

    @Dependency(\.defaultDatabase) var database
    @Dependency(\.date.now) var now
    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                state.step = .focus
                state.focus = nil
                return .none
            case .binding, .delegate:
                return .none
            case .cardioButtonTapped:
                return choose(.cardio, &state)
            case .closeButtonTapped:
                return .run { [dismiss] _ in await dismiss() }
            case .continueButtonTapped:
                guard !state.selectedMuscles.isEmpty else { return .none }
                let muscles = Muscle.all.filter { state.selectedMuscles.contains($0.rawValue) }
                return choose(.muscles(muscles), &state)
            case let .exerciseTapped(id):
                if state.picked.remove(id) == nil { state.picked.insert(id) }
                return .none
            case let .muscleTapped(id):
                if state.selectedMuscles.remove(id) == nil { state.selectedMuscles.insert(id) }
                return .none
            case let .optionsLoaded(options):
                state.options = options
                state.picked = Set(options.defaultPicks)
                return .none
            case .startButtonTapped:
                let exerciseIDs = state.startOrder
                guard !exerciseIDs.isEmpty else { return .none }
                return .run { [now] send in
                    await withErrorReporting {
                        _ = try await database.write { db in
                            try LiveWorkout.start(db, exerciseIDs: exerciseIDs, now: now)
                        }
                        await send(.delegate(.navigate(.session)))
                    }
                }
            case .warmupButtonTapped:
                return choose(.warmup, &state)
            }
        }
    }

    /// Moves on to step 2 for `focus` and reads what it offers.
    private func choose(_ focus: TrainFocus, _ state: inout State) -> Effect<Action> {
        state.focus = focus
        state.step = .build
        state.equipmentFilter = nil
        state.muscleFilter = nil
        state.searchText = ""
        return .run { send in
            await withErrorReporting {
                let options = try await database.read { db in try TrainOptions.fetch(db, focus: focus) }
                await send(.optionsLoaded(options))
            }
        }
        .cancellable(id: CancelID.options, cancelInFlight: true)
    }

    private enum CancelID { case options }
}

extension Train.State {
    /// Suggested picks that pass the filters, in list order.
    public var suggestions: [TrainExercise] {
        let seed = Set(options.defaultPicks)
        return focusRows.filter { seed.contains($0.id) }.filter(passesFilters)
    }

    /// The rest of the focus, then anything picked from search, filtered.
    public var moreOptions: [TrainExercise] {
        let seed = Set(options.defaultPicks)
        return (focusRows.filter { !seed.contains($0.id) } + pickedElsewhere).filter(passesFilters)
    }

    /// Every active exercise whose name matches the search, up to 40.
    public var searchResults: [TrainExercise] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }
        return Array(options.exercises.filter { $0.name.localizedStandardContains(query) }.prefix(40))
    }

    /// Equipment found among the focus exercises, in picker order.
    public var equipmentOptions: [Equipment] {
        let present = Set((focusRows + pickedElsewhere).map(\.equipment))
        return Equipment.all.filter(present.contains)
    }

    /// Picked exercises in the order they're listed, filters aside.
    var startOrder: [Exercise.ID] {
        let seed = Set(options.defaultPicks)
        let listed = focusRows.filter { seed.contains($0.id) } + focusRows.filter { !seed.contains($0.id) }
        return (listed + pickedElsewhere).map(\.id).filter(picked.contains)
    }

    private var focusRows: [TrainExercise] {
        let byID = Dictionary(options.exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return options.pool.compactMap { byID[$0] }
    }

    /// Picked exercises that aren't part of the focus, found by searching.
    private var pickedElsewhere: [TrainExercise] {
        let pool = Set(options.pool)
        return options.exercises.filter { picked.contains($0.id) && !pool.contains($0.id) }
    }

    private func passesFilters(_ exercise: TrainExercise) -> Bool {
        if let muscleFilter, exercise.primaryMuscle.rawValue != muscleFilter { return false }
        if let equipmentFilter, exercise.equipment != equipmentFilter { return false }
        return true
    }
}

import ComposableArchitecture
import Database
import Foundation
import L10n
import Routing
import SQLiteData

/// One exercise: live demo, muscles, next-time target, record, goal, history, notes, steps,
/// similar moves and per-exercise settings. Read from the database (see `ExerciseOverview`);
/// every setting is saved as soon as it changes.
@Reducer
public struct ExerciseDetail: Sendable {
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        @Presents public var editor: ExerciseEditor.State?
        public let id: Exercise.ID
        @ObservationStateIgnored
        @Fetch public var overview = ExerciseOverview()

        public init(id: Exercise.ID) {
            self.id = id
        }
    }

    public enum Action {
        case alert(PresentationAction<Alert>)
        case archiveButtonTapped
        case autoProgressToggled(Bool)
        case autoWarmupToggled(Bool)
        case delegate(Delegate)
        case deleteButtonTapped
        case editButtonTapped
        case editor(PresentationAction<ExerciseEditor.Action>)
        case notesButtonTapped
        case restDecrementButtonTapped
        case restIncrementButtonTapped
        case similarTapped(id: Exercise.ID)
        case suggestInWorkoutsToggled(Bool)
        case task

        @CasePathable
        public enum Alert: Equatable, Sendable {
            case confirmDeleteButtonTapped
        }

        @CasePathable
        public enum Delegate {
            case navigate(Route)
        }
    }

    @Dependency(\.defaultDatabase) var database
    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .alert(.presented(.confirmDeleteButtonTapped)):
                return .run { [id = state.id] _ in
                    await withErrorReporting {
                        let isDeleted = try await database.write { db in try Exercise.deleteCustom(db, id: id) }
                        if isDeleted { await dismiss() }
                    }
                }
            case .alert, .delegate, .editor:
                return .none
            case .archiveButtonTapped:
                return write(state) { db, id in
                    try Exercise.find(id).update { $0.isArchived.toggle() }.execute(db)
                }
            case let .autoProgressToggled(isOn):
                let stepKg = state.overview.units == .kg ? Progression.defaultStepKg : 5 * WeightUnit.lb.kilograms
                return editPreference(state) { $0.progressStepKg = isOn ? stepKg : nil }
            case let .autoWarmupToggled(isOn):
                return editPreference(state) { $0.autoWarmup = isOn }
            case .deleteButtonTapped:
                state.alert = .deleteExercise(name: state.name)
                return .none
            case .editButtonTapped:
                guard let exercise = state.overview.exercise, exercise.isCustom else { return .none }
                state.editor = ExerciseEditor.State(exercise: exercise)
                return .none
            case .notesButtonTapped:
                return .send(.delegate(.navigate(.notes)))
            case .restDecrementButtonTapped:
                let seconds = max(state.restSeconds - AppSettings.restStep, AppSettings.restRange.lowerBound)
                return editPreference(state) { $0.restSeconds = seconds }
            case .restIncrementButtonTapped:
                let seconds = min(state.restSeconds + AppSettings.restStep, AppSettings.restRange.upperBound)
                return editPreference(state) { $0.restSeconds = seconds }
            case let .similarTapped(id):
                return .send(.delegate(.navigate(.exerciseDetail(id: id))))
            case let .suggestInWorkoutsToggled(isOn):
                return editPreference(state) { $0.isSuggested = isOn }
            case .task:
                return .run { [overview = state.$overview, id = state.id] _ in
                    await withErrorReporting {
                        try await overview.load(ExerciseOverview.Request(exerciseID: id)).task
                    }
                }
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$editor, action: \.editor) {
            ExerciseEditor()
        }
    }

    private func editPreference(
        _ state: State,
        _ change: @escaping @Sendable (inout ExercisePreference) -> Void
    ) -> Effect<Action> {
        write(state) { db, id in try ExercisePreference.edit(db, exerciseID: id, change) }
    }

    private func write(
        _ state: State,
        _ change: @escaping @Sendable (Database, Exercise.ID) throws -> Void
    ) -> Effect<Action> {
        .run { [id = state.id] _ in
            await withErrorReporting {
                try await database.write { db in try change(db, id) }
            }
        }
    }
}

extension ExerciseDetail.State {
    public var name: String { overview.exercise?.name ?? "" }
    public var isCustom: Bool { overview.exercise?.isCustom ?? false }
    public var isArchived: Bool { overview.exercise?.isArchived ?? false }

    private var preference: ExercisePreference { overview.preference ?? .defaults(for: id) }
    public var autoProgress: Bool { preference.progressStepKg != nil }
    public var autoWarmup: Bool { preference.autoWarmup }
    public var suggestInWorkouts: Bool { preference.isSuggested }
    /// The exercise's own rest, or the default from Settings; 0 is off.
    public var restSeconds: Int { preference.restSeconds ?? overview.defaultRestSeconds }

    /// How far the record is towards the goal, 0…1; `nil` without a goal.
    public var goalProgress: Double? {
        guard let goalKg = preference.goalTargetKg, goalKg > 0 else { return nil }
        guard let record = overview.record, record.kind == .weight else { return 0 }
        return min(record.best / goalKg, 1)
    }
}

extension AlertState where Action == ExerciseDetail.Action.Alert {
    public static func deleteExercise(name: String) -> Self {
        AlertState {
            TextState(L10n.deleteExerciseTitle)
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeleteButtonTapped) {
                TextState(L10n.delete)
            }
            ButtonState(role: .cancel) {
                TextState(L10n.cancel)
            }
        } message: {
            TextState(L10n.deleteExerciseBody(name))
        }
    }
}

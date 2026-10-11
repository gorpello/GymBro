import ComposableArchitecture
import Database
import Foundation
import SQLiteData

/// Create or edit a custom exercise: name, muscles, equipment, level, how it's logged, steps.
@Reducer
public struct ExerciseEditor : Sendable{
    @ObservableState
    public struct State: Equatable {
        /// `nil` while creating a new exercise.
        public var exerciseID: Exercise.ID?
        public var difficulty: Difficulty = .beginner
        public var equipment: Equipment = .barbell
        public var howTo = ""
        public var mode: ExerciseMode = .weight
        public var name = ""
        public var primary: Muscle = .chest
        public var secondary: Set<Muscle> = []

        /// A new exercise, optionally named after the search that found nothing.
        public init(name: String = "") {
            self.name = name
        }

        /// Editing an existing custom exercise.
        public init(exercise: Exercise) {
            self.exerciseID = exercise.id
            self.difficulty = exercise.difficulty
            self.equipment = exercise.equipment
            self.howTo = exercise.steps.joined(separator: "\n")
            self.mode = exercise.mode
            self.name = exercise.name
            self.primary = exercise.primaryMuscle
            self.secondary = Set(exercise.secondaryMuscles)
        }

        public var isNew: Bool { exerciseID == nil }
        public var canSave: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case cancelButtonTapped
        case saveButtonTapped
        case secondaryMuscleTapped(Muscle)
    }

    @Dependency(\.defaultDatabase) var database
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.uuid) var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
            .onChange(of: \.primary) { _, primary in
                Reduce { state, _ in
                    state.secondary.remove(primary)
                    return .none
                }
            }
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .cancelButtonTapped:
                return .run { _ in await dismiss() }
            case .saveButtonTapped:
                guard state.canSave else { return .none }
                var exercise = Exercise.custom(id: state.exerciseID ?? "custom-\(uuid().uuidString.lowercased())")
                exercise.name = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
                exercise.primaryMuscle = state.primary
                exercise.secondaryMuscles = Exercise.secondaryMuscles(state.secondary, primary: state.primary)
                exercise.equipment = state.equipment
                exercise.difficulty = state.difficulty
                exercise.steps = Exercise.steps(from: state.howTo)
                exercise.mode = state.mode
                return .run { [exercise] _ in
                    await withErrorReporting {
                        try await database.write { db in try Exercise.saveCustom(db, exercise) }
                    }
                    await dismiss()
                }
            case let .secondaryMuscleTapped(muscle):
                guard muscle != state.primary else { return .none }
                if state.secondary.remove(muscle) == nil { state.secondary.insert(muscle) }
                return .none
            }
        }
    }
}

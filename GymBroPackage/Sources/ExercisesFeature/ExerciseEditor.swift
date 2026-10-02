import ComposableArchitecture

/// Create or edit a custom exercise: name, muscles, equipment, level, how it's logged, steps.
@Reducer
public struct ExerciseEditor {
    @ObservableState
    public struct State: Equatable {
        public var difficulty = "Beginner"
        public var equipment = "Barbell"
        public var howTo = ""
        public var logBy: LogBy = .reps
        public var name = ""
        public var primary = "chest"
        public var secondary: Set<String> = []
        
        public init() {}
    }
    
    public enum LogBy: String, CaseIterable, Hashable, Sendable {
        case reps, time, cardio
    }
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case cancelButtonTapped
        case saveButtonTapped
        case secondaryMuscleTapped(String)
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .cancelButtonTapped, .saveButtonTapped:
                return .run { [dismiss] _ in await dismiss() }
            case let .secondaryMuscleTapped(id):
                if state.secondary.remove(id) == nil { state.secondary.insert(id) }
                return .none
            }
        }
    }
}

/// Muscle ids in body-map order (`kMuscles`).
public let muscleIDs = [
    "chest", "shoulders", "biceps", "abdomen", "obliques", "quads", "forearm",
    "trapezius", "back", "triceps", "glutes", "hamstrings", "calves",
]

/// Equipment ids (`kEquipment`).
public let equipmentIDs = [
    "Barbell", "Dumbbell", "Cable", "Machine", "Bodyweight", "Weighted", "Band", "Kettlebell", "Rings", "Other",
]

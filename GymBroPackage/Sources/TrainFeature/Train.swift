import ComposableArchitecture
import Routing

/// Quick workout builder. Step 1: tap muscles on the body map (or pick warm-up / cardio).
/// Step 2: review the suggested exercises and start.
@Reducer
public struct Train {
    @ObservableState
    public struct State: Equatable {
        public var equipmentFilter: String?
        public var muscleFilter: String?
        public var picked: Set<String> = []
        public var searchText = ""
        public var selectedMuscles: Set<String> = []
        public var step: Step = .focus

        /// Exercises suggested for the chosen focus.
        public var suggestions: [TrainExercise] = [
            .init(id: "EIeI8Vf", art: "bench-press", detail: "Chest · Barbell", name: "Barbell Bench Press"),
            .init(
                id: "ns0SIbU", art: "incline-dumbbell-press", detail: "Chest · Dumbbell",
                name: "Dumbbell Incline Bench Press"),
            .init(id: "tri1", art: "rope-tricep-pushdown", detail: "Triceps · Cable", name: "Rope Triceps Pushdown"),
            .init(id: "tri2", art: "skull-crusher", detail: "Triceps · Barbell", name: "Skull Crusher"),
        ]
        /// Further matches shown under "More options".
        public var moreOptions: [TrainExercise] = [
            .init(id: "9WTm7dq", art: "chest-dip", detail: "Chest · Bodyweight", name: "Chest Dip"),
            .init(id: "pec", art: "pec-deck", detail: "Chest · Machine", name: "Pec Deck"),
        ]
        /// Equipment ids available for the chosen focus.
        public var equipmentOptions: [String] = ["Barbell", "Dumbbell", "Cable", "Machine", "Bodyweight"]

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
        case exerciseTapped(id: String)
        case muscleTapped(String)
        case startButtonTapped
        case warmupButtonTapped

        public enum Delegate {
            case navigate(Route)
        }
    }

    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                state.step = .focus
                return .none
            case .binding, .delegate:
                return .none
            case .cardioButtonTapped, .warmupButtonTapped:
                state.step = .build
                return .none
            case .closeButtonTapped:
                return .run { [dismiss] _ in await dismiss() }
            case .continueButtonTapped:
                guard !state.selectedMuscles.isEmpty else { return .none }
                state.step = .build
                state.picked = Set(state.suggestions.map(\.id))
                return .none
            case let .exerciseTapped(id):
                if state.picked.remove(id) == nil { state.picked.insert(id) }
                return .none
            case let .muscleTapped(id):
                if state.selectedMuscles.remove(id) == nil { state.selectedMuscles.insert(id) }
                return .none
            case .startButtonTapped:
                return .send(.delegate(.navigate(.session)))
            }
        }
    }
}

public struct TrainExercise: Equatable, Identifiable, Sendable {
    public var id: String
    public var art: String
    public var detail: String
    public var name: String

    public init(id: String, art: String, detail: String, name: String) {
        self.id = id
        self.art = art
        self.detail = detail
        self.name = name
    }
}

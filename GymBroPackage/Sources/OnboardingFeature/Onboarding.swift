import ComposableArchitecture

/// First run: welcome, name, body numbers, weekly goal, units and places.
@Reducer
public struct Onboarding {
    @ObservableState
    public struct State: Equatable {
        public var age = 28
        public var heightCm = 175.0
        public var name = ""
        public var places: Set<String> = ["gym"]
        public var sex = "male"
        public var step: Step = .welcome
        public var units = "kg"
        public var weeklyGoal = 4
        public var weightKg = 75.0

        public init() {}
    }

    public enum Step: Int, CaseIterable, Sendable {
        case welcome, name, body, goal, units, places
    }

    public enum Action: BindableAction {
        case backButtonTapped
        case binding(BindingAction<State>)
        case nextButtonTapped
        case placeTapped(String)
        case skipButtonTapped
    }

    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                state.step = Step(rawValue: state.step.rawValue - 1) ?? .welcome
                return .none
            case .binding:
                return .none
            case .nextButtonTapped:
                guard let next = Step(rawValue: state.step.rawValue + 1) else {
                    return .run { [dismiss] _ in await dismiss() }
                }
                state.step = next
                return .none
            case let .placeTapped(id):
                if state.places.remove(id) == nil { state.places.insert(id) }
                return .none
            case .skipButtonTapped:
                return .run { [dismiss] _ in await dismiss() }
            }
        }
    }
}

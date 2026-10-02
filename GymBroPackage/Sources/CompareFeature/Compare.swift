import ComposableArchitecture
import Routing

/// Before and after: the same pose on two days, with a drag-to-reveal divider.
@Reducer
public struct Compare {
    
    @ObservableState
    public struct State: Equatable {
        public var pose = "front"
        public var reveal = 0.5
        
        public var afterDate: String = "Sep 19"
        public var beforeDate: String = "Jun 22"
        public var daysApart: Int = 89
        
        public init() {}
    }
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case shareButtonTapped
        
        public enum Delegate {
            case navigate(Route)
        }
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { _, action in
            switch action {
            case .binding, .delegate:
                return .none
            case .shareButtonTapped:
                return .send(.delegate(.navigate(.share)))
            }
        }
    }
}

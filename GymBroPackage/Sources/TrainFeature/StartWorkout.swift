import ComposableArchitecture
import Routing

/// "Start workout" sheet from the tab bar accessory: today's routine, your routines, or pick / focus.
/// Switches to "Log a workout" for sessions done without the timer.
@Reducer
public struct StartWorkout {
    @ObservableState
    public struct State: Equatable {
        public var isLogging = false
        
        public var dateTitle: String = "Saturday, Sep 19"
        public var routines: [StartRoutineRow] = [
            .init(id: "pull", exerciseCount: 4, hue: 2, name: "Pull"),
            .init(id: "legs", exerciseCount: 4, hue: 5, name: "Legs"),
        ]
        public var todayRoutine: StartRoutineRow? = StartRoutineRow(id: "push", exerciseCount: 4, hue: 3, name: "Push")
        
        public init() {}
    }
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case chooseFocusButtonTapped
        case delegate(Delegate)
        case pickExercisesButtonTapped
        case routineTapped(id: String)
        
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
            case .chooseFocusButtonTapped, .pickExercisesButtonTapped:
                return .send(.delegate(.navigate(.train)))
            case .routineTapped:
                return .send(.delegate(.navigate(.session)))
            }
        }
    }
}

public struct StartRoutineRow: Equatable, Identifiable, Sendable {
    public var id: String
    public var exerciseCount: Int
    /// Index into the folder hues.
    public var hue: Int
    public var name: String
    
    public init(id: String, exerciseCount: Int, hue: Int, name: String) {
        self.id = id
        self.exerciseCount = exerciseCount
        self.hue = hue
        self.name = name
    }
}

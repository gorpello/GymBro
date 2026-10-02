import ComposableArchitecture
import Routing

/// Today: the routine due today, the week at a glance, this week's numbers and the activity map.
@Reducer
public struct Home {
    @ObservableState
    public struct State: Equatable {
        /// Last twelve weeks of activity, `activity[week][weekday]`, levels 0…4.
        public var activity: [[Int]] = [[0, 4, 0, 0, 0, 4, 4], [4, 0, 4, 4, 0, 0, 0], [4, 0, 4, 0, 3, 0, 4], [0, 3, 0, 4, 4, 4, 0], [0, 4, 4, 0, 0, 4, 0], [4, 0, 0, 4, 2, 0, 4], [0, 4, 0, 4, 0, 4, 0], [4, 4, 0, 0, 4, 0, 4], [0, 0, 4, 3, 0, 4, 4], [4, 0, 4, 4, 4, 0, 0], [0, 4, 0, 4, 0, 4, 4], [0, 0, 0, 4, 4, 4, 4]]
        public var dateTitle: String = "Saturday, Sep 19"
        public var noteCount: Int = 3
        public var prCount: Int = 3
        public var routineCount: Int = 3
        public var setsToday: Int = 10
        public var streak: Int = 4
        public var todayExerciseCount: Int = 4
        /// Name of today's routine; `nil` shows the "first session" hint.
        public var todayRoutineName: String? = "Push"
        public var todayWeekdayIndex: Int = 5
        public var volume: String = "28.8"
        public var volumeUnit: String = "t"
        public var weekDone: [Bool] = [false, false, true, true, true, true, false]
        public var weeklyGoal: Int = 4
        public var weeklySessions: Int = 4
        
        public init() {}
    }
    
    public enum Action {
        case activityButtonTapped
        case delegate(Delegate)
        case journalButtonTapped
        case routinesButtonTapped
        case startWorkoutButtonTapped
        case toolsButtonTapped
        
        public enum Delegate {
            case navigate(Route)
        }
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .activityButtonTapped:
                return .send(.delegate(.navigate(.timeline)))
            case .delegate:
                return .none
            case .journalButtonTapped:
                return .send(.delegate(.navigate(.notes)))
            case .routinesButtonTapped:
                return .send(.delegate(.navigate(.routines)))
            case .startWorkoutButtonTapped:
                return .send(.delegate(.navigate(state.todayRoutineName == nil ? .train : .start)))
            case .toolsButtonTapped:
                return .send(.delegate(.navigate(.tools)))
            }
        }
    }
}

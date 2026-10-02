import ComposableArchitecture
import Routing

/// Settings: general, training, reminders, home, data & backup, support.
@Reducer
public struct Preferences {
    @ObservableState
    public struct State: Equatable {
        public var alarmSoundName: String = "Default"
        /// `loud`, `quiet` (follow silent mode) or `vibrate`.
        public var alarmStyle: String = "quiet"
        public var autoAdvance: Bool = true
        public var background: String = "dots"
        public var countdown: Bool = true
        /// `large`, `small` or `off`.
        public var demoSize: String = "large"
        /// `rpe`, `rir` or `off`.
        public var effort: String = "off"
        public var focusCard: Bool = true
        public var gamification: Bool = true
        public var heatmapLabels: Bool = false
        public var homeRecommended: Bool = true
        public var keepScreenOn: Bool = true
        public var languageName: String = "English"
        public var levelHints: Bool = true
        public var multiPlan: Bool = false
        public var restSeconds: Int = 90
        /// `auto`, `dark` or `light`.
        public var theme: String = "dark"
        public var trainReminder: String = "Never"
        /// `kg` or `lb`.
        public var units: String = "kg"
        public var weekStart: String = "Monday"
        
        public init() {}
    }
    
    public enum Action: BindableAction {
        case aboutButtonTapped
        case binding(BindingAction<State>)
        case buyCoffeeButtonTapped
        case delegate(Delegate)
        case deleteAllButtonTapped
        case exportBackupButtonTapped
        case exportCsvButtonTapped
        case importBackupButtonTapped
        case importFromAppButtonTapped
        case placesButtonTapped
        case reportBugButtonTapped
        case requestFeatureButtonTapped
        case restDecrementButtonTapped
        case restIncrementButtonTapped
        case starButtonTapped
        case stravaButtonTapped
        
        public enum Delegate {
            case navigate(Route)
        }
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .aboutButtonTapped:
                return .send(.delegate(.navigate(.about)))
            case .binding, .buyCoffeeButtonTapped, .delegate, .deleteAllButtonTapped, .exportBackupButtonTapped,
                    .exportCsvButtonTapped, .importBackupButtonTapped, .importFromAppButtonTapped, .reportBugButtonTapped,
                    .requestFeatureButtonTapped, .starButtonTapped:
                return .none
            case .placesButtonTapped:
                return .send(.delegate(.navigate(.places)))
            case .restDecrementButtonTapped:
                state.restSeconds = max(0, state.restSeconds - 15)
                return .none
            case .restIncrementButtonTapped:
                state.restSeconds = min(600, state.restSeconds + 15)
                return .none
            case .stravaButtonTapped:
                return .send(.delegate(.navigate(.strava)))
            }
        }
    }
}

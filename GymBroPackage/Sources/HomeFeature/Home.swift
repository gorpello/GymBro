import ComposableArchitecture
import Foundation
import Routing
import SQLiteData

/// Today: the routine due today, the week at a glance, this week's numbers and the activity map.
@Reducer
public struct Home {

    @ObservableState
    public struct State: Equatable {
        @ObservationStateIgnored
        @Fetch public var summary = HomeSummary()

        /// Start of the day Home was last shown for; `nil` until it appears.
        public var today: Date?

        public init() {}
    }

    public enum Action {
        case activityButtonTapped
        case delegate(Delegate)
        case journalButtonTapped
        case routinesButtonTapped
        case startWorkoutButtonTapped
        case task
        case toolsButtonTapped

        @CasePathable
        public enum Delegate {
            case navigate(Route)
        }
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now

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
                return .send(.delegate(.navigate(state.summary.todayRoutineName == nil ? .train : .start)))
            case .task:
                let today = calendar.startOfDay(for: now)
                state.today = today
                return .run { [summary = state.$summary, calendar] _ in
                    await withErrorReporting {
                        try await summary.load(HomeSummary.Request(today: today, calendar: calendar)).task
                    }
                }
            case .toolsButtonTapped:
                return .send(.delegate(.navigate(.tools)))
            }
        }
    }
}

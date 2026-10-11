import ComposableArchitecture
import Database
import Foundation
import Routing
import SQLiteData

/// The Progress tab: volume and weight tiles, consistency, all-time totals, muscle map,
/// strength curves, records, photo timeline and body measurements.
///
/// Everything is read from the database (see `ProgressSummary`) and follows it as workouts,
/// measurements and photos are logged.
@Reducer
public struct ProgressOverview {
    @ObservableState
    public struct State: Equatable {
        public var muscleRange: MuscleRange = .days7
        @ObservationStateIgnored
        @Fetch public var summary = ProgressSummary()

        public init() {}
    }

    public enum MuscleRange: Hashable, Sendable {
        case days7, days30, recovery
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case compareButtonTapped
        case delegate(Delegate)
        case exerciseTapped(id: Exercise.ID)
        case measuresButtonTapped
        case shareButtonTapped
        case task
        case timelineButtonTapped

        @CasePathable
        public enum Delegate {
            case navigate(Route)
        }
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .delegate:
                return .none
            case .compareButtonTapped:
                return .send(.delegate(.navigate(.compare)))
            case let .exerciseTapped(id):
                return .send(.delegate(.navigate(.exerciseDetail(id: id))))
            case .measuresButtonTapped:
                return .send(.delegate(.navigate(.measures)))
            case .shareButtonTapped:
                return .send(.delegate(.navigate(.share)))
            case .task:
                return .run { [summary = state.$summary, calendar, now] _ in
                    await withErrorReporting {
                        try await summary.load(ProgressSummary.Request(now: now, calendar: calendar)).task
                    }
                }
            case .timelineButtonTapped:
                return .send(.delegate(.navigate(.timeline)))
            }
        }
    }
}

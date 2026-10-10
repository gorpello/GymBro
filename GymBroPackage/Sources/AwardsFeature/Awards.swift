import ComposableArchitecture
import Database
import Foundation
import SQLiteData

/// All 20 medals, earned first. Opening the screen awards any medal already deserved and marks
/// every medal as seen.
@Reducer
public struct Awards {
    @ObservableState
    public struct State: Equatable {
        @ObservationStateIgnored
        @Fetch public var board = AwardsBoard()

        public init() {}
    }

    public enum Action {
        case medalTapped(AwardKind)
        case task
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.defaultDatabase) var database
    @Dependency(\.date.now) var now

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .medalTapped:
                return .none
            case .task:
                return .run { [board = state.$board, calendar, now] _ in
                    await withErrorReporting {
                        try await database.write { db in
                            try Award.refresh(db, now: now, calendar: calendar)
                            try Award.markAllSeen(db)
                        }
                        try await board.load(AwardsBoard.Request(today: now, calendar: calendar)).task
                    }
                }
            }
        }
    }
}

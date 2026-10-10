import Database
import Foundation
import SQLiteData

/// Every medal with when it was earned or how close it is. Read by `AwardsBoard.Request` and
/// re-read whenever an award or the training data behind the totals changes.
public struct AwardsBoard: Equatable, Sendable {
    public var medals: [Medal]

    public init(medals: [Medal] = AwardKind.allCases.map { Medal(kind: $0) }) {
        self.medals = medals
    }

    public var earned: [Medal] { medals.filter { $0.earnedAt != nil } }
    public var locked: [Medal] { medals.filter { $0.earnedAt == nil } }

    public struct Medal: Equatable, Identifiable, Sendable {
        public var kind: AwardKind
        public var earnedAt: Date?
        /// Current value of the medal's metric, capped at its goal.
        public var progress = 0

        public init(kind: AwardKind, earnedAt: Date? = nil, progress: Int = 0) {
            self.kind = kind
            self.earnedAt = earnedAt
            self.progress = progress
        }

        public var id: AwardKind { kind }
    }
}

extension AwardsBoard {
    public struct Request: FetchKeyRequest {
        public var today: Date
        public var calendar: Calendar

        public init(today: Date, calendar: Calendar) {
            self.today = today
            self.calendar = calendar
        }

        public func fetch(_ db: Database) throws -> AwardsBoard {
            let earnedAt = try Dictionary(
                uniqueKeysWithValues: Award.select { ($0.id, $0.earnedAt) }.fetchAll(db)
            )
            let totals = try TrainingTotals.fetch(db, today: today, calendar: calendar)
            return AwardsBoard(
                medals: AwardKind.allCases.map { kind in
                    Medal(
                        kind: kind,
                        earnedAt: earnedAt[kind.rawValue],
                        progress: min(totals.value(of: kind.metric), kind.goal)
                    )
                }
            )
        }
    }
}

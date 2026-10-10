import Foundation
import SQLiteData

extension Award {
    /// Saves every medal whose goal has been reached and that isn't earned yet, dated `now`.
    /// Earned medals are never taken back, even if the data behind them is deleted later.
    ///
    /// New medals are unseen, so they can be celebrated, unless gamification is turned off.
    ///
    /// - Returns: The medals earned by this call, easiest first.
    @discardableResult
    public static func refresh(_ db: Database, now: Date, calendar: Calendar) throws -> [AwardKind] {
        let earned = try Set(Award.select(\.id).fetchAll(db))
        let totals = try TrainingTotals.fetch(db, today: now, calendar: calendar)
        let reached = AwardKind.allCases.filter { kind in
            !earned.contains(kind.rawValue) && totals.value(of: kind.metric) >= kind.goal
        }
        guard !reached.isEmpty else { return [] }

        let isCelebrated =
            try AppSettings.find(AppSettings.singletonID).select(\.gamification).fetchOne(db)
            ?? AppSettings().gamification
        for kind in reached {
            try Award.insert {
                Award(id: kind.rawValue, earnedAt: now, isSeen: !isCelebrated)
            }
            .execute(db)
        }
        return reached
    }

    /// Marks every earned medal as seen, e.g. once the Awards screen has shown them.
    public static func markAllSeen(_ db: Database) throws {
        try Award.where { !$0.isSeen }.update { $0.isSeen = true }.execute(db)
    }
}

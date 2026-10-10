import Database
import Foundation
import SQLiteData

/// Everything the Profile tab shows. Read in one transaction by `ProfileSummary.Request` and
/// re-read whenever the profile, settings, awards, moments or training data change.
public struct ProfileSummary: Equatable, Sendable {
    public static let shelfSize = 4
    public static let workoutsPerLevel = 10

    public var profile = UserProfile()
    public var units = AppSettings().units
    /// Levels and medals are hidden when gamification is off.
    public var gamification = AppSettings().gamification
    public var totals = TrainingTotals()
    public var medalCount = 0
    /// Earned medals first, then the easiest locked ones.
    public var shelf = AwardKind.allCases.prefix(shelfSize).map { ShelfMedal(kind: $0) }
    public var momentCount = 0
    /// Finished workouts per month of the current year, January first.
    public var yearMonths = Array(repeating: 0, count: 12)

    public init() {}

    /// One level per ten workouts, starting at 1.
    public var level: Int { 1 + totals.workoutCount / Self.workoutsPerLevel }
    public var workoutsToNextLevel: Int { Self.workoutsPerLevel - totals.workoutCount % Self.workoutsPerLevel }

    public struct ShelfMedal: Equatable, Identifiable, Sendable {
        public var kind: AwardKind
        public var isEarned = false
        /// Earned but not looked at yet.
        public var isNew = false

        public var id: AwardKind { kind }
    }
}

extension ProfileSummary {
    public struct Request: FetchKeyRequest {
        public var today: Date
        public var calendar: Calendar

        public init(today: Date, calendar: Calendar) {
            self.today = today
            self.calendar = calendar
        }

        public func fetch(_ db: Database) throws -> ProfileSummary {
            var summary = ProfileSummary()
            if let profile = try UserProfile.find(UserProfile.singletonID).fetchOne(db) {
                summary.profile = profile
            }
            if let settings = try AppSettings.find(AppSettings.singletonID).fetchOne(db) {
                summary.units = settings.units
                summary.gamification = settings.gamification
            }
            summary.totals = try TrainingTotals.fetch(db, today: today, calendar: calendar)
            summary.momentCount = try Moment.all.fetchCount(db)

            let awards = try Award.all.fetchAll(db)
            summary.medalCount = awards.count
            let unseen = Set(awards.filter { !$0.isSeen }.map(\.id))
            let earned = Set(awards.map(\.id))
            let isEarned = { (kind: AwardKind) in earned.contains(kind.rawValue) }
            let shelfOrder = AwardKind.allCases.filter(isEarned) + AwardKind.allCases.filter { !isEarned($0) }
            summary.shelf = shelfOrder.prefix(ProfileSummary.shelfSize).map { kind in
                ShelfMedal(kind: kind, isEarned: isEarned(kind), isNew: unseen.contains(kind.rawValue))
            }

            if let year = calendar.dateInterval(of: .year, for: today) {
                let workoutDates =
                    try Workout
                    .where { $0.finishedAt.isNot(nil) && $0.startedAt.gte(year.start) && $0.startedAt.lt(year.end) }
                    .select(\.startedAt)
                    .fetchAll(db)
                for date in workoutDates {
                    summary.yearMonths[calendar.component(.month, from: date) - 1] += 1
                }
            }
            return summary
        }
    }
}

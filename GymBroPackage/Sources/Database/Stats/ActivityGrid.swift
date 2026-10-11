import Foundation
import SQLiteData

/// The consistency heat map shared by Home and Progress: twelve weeks of days, Monday first,
/// each scored 0…4 against the busiest day.
public enum ActivityGrid {
    public static let weeks = 12

    /// Each day's load is its working sets (at least 1 per workout) plus 1 for a check-in, scaled
    /// against the busiest day in the window.
    ///
    /// - Parameters:
    ///   - start: Monday of the oldest week.
    ///   - today: Start of the current day; later days stay empty.
    ///   - sessionDays: Start of the day of every finished workout.
    ///   - checkInDays: Start of every day marked as trained by hand.
    ///   - setCounts: Working sets per workout; workouts without one count as 1.
    /// - Returns: `levels[week][weekday]`, oldest week first.
    public static func levels(
        from start: Date,
        through today: Date,
        sessionDays: [Workout.ID: Date],
        checkInDays: Set<Date>,
        setCounts: [Workout.ID: Int],
        calendar: Calendar
    ) -> [[Int]] {
        var load: [Date: Double] = [:]
        for day in checkInDays where day >= start && day <= today {
            load[day] = 1
        }
        for (id, day) in sessionDays where day >= start && day <= today {
            load[day, default: 0] += Double(max(1, setCounts[id] ?? 0))
        }
        let busiest = load.values.max() ?? 0
        return (0..<weeks).map { week in
            (0..<7).map { weekday in
                let day = calendar.day(byAdding: week * 7 + weekday, to: start)
                guard busiest > 0, let value = load[day] else { return 0 }
                return HeatLevel.of(value / busiest)
            }
        }
    }
}

extension ActivityGrid {
    /// The twelve weeks up to the one containing `today`, read from finished workouts and
    /// check-ins.
    public static func fetch(_ db: Database, today: Date, calendar: Calendar) throws -> [[Int]] {
        let today = calendar.startOfDay(for: today)
        let weekStart = calendar.day(byAdding: -calendar.mondayIndex(of: today), to: today)
        let start = calendar.day(byAdding: -7 * (weeks - 1), to: weekStart)
        let workouts =
            try Workout
            .where { $0.finishedAt.isNot(nil) && $0.startedAt.gte(start) }
            .select { ($0.id, $0.startedAt) }
            .fetchAll(db)
        let checkInDays = try CheckIn.where { $0.day.gte(start) }.select(\.day).fetchAll(db)
        let totals = try WorkoutTotal.fetch(db, from: start)
        return levels(
            from: start,
            through: today,
            sessionDays: Dictionary(
                workouts.map { ($0.0, calendar.startOfDay(for: $0.1)) },
                uniquingKeysWith: { first, _ in first }
            ),
            checkInDays: Set(checkInDays.map { calendar.startOfDay(for: $0) }),
            setCounts: Dictionary(totals.map { ($0.id, $0.setCount) }, uniquingKeysWith: { first, _ in first }),
            calendar: calendar
        )
    }
}

/// The five shades every heat map uses.
public enum HeatLevel {
    /// 0 for nothing, then 1…4 in quarters of `fraction`.
    public static func of(_ fraction: Double) -> Int {
        switch fraction {
        case ...0: 0
        case ..<0.25: 1
        case ..<0.5: 2
        case ..<0.75: 3
        default: 4
        }
    }
}

import Foundation

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

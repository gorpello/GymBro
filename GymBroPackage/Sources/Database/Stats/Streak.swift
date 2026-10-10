import Foundation
import SQLiteData

/// Consecutive training days. A day counts when it has a finished workout or a check-in.
public enum Streak {
    /// The streak up to `today`, read from the database.
    public static func fetch(_ db: Database, today: Date, calendar: Calendar) throws -> Int {
        let workoutDays = try Workout.where { $0.finishedAt.isNot(nil) }.select(\.startedAt).fetchAll(db)
        let checkInDays = try CheckIn.select(\.day).fetchAll(db)
        let scheduledWeekdays = try Set(RoutineSchedule.select(\.weekday).fetchAll(db))
        return count(
            endingOn: calendar.startOfDay(for: today),
            trainedDays: Set((workoutDays + checkInDays).map { calendar.startOfDay(for: $0) }),
            scheduledWeekdays: scheduledWeekdays,
            calendar: calendar
        )
    }

    /// Counts back from `today` (or yesterday, if today isn't trained yet). Once any routine is
    /// scheduled, days with nothing scheduled are rest days and are skipped instead of ending it.
    ///
    /// - Parameters:
    ///   - today: Start of the current day.
    ///   - trainedDays: Start of every day with a workout or check-in.
    ///   - scheduledWeekdays: Weekdays with a routine planned, 1 = Monday … 7 = Sunday.
    public static func count(
        endingOn today: Date,
        trainedDays: Set<Date>,
        scheduledWeekdays: Set<Int>,
        calendar: Calendar
    ) -> Int {
        guard let first = trainedDays.min() else { return 0 }
        var day = trainedDays.contains(today) ? today : calendar.day(byAdding: -1, to: today)
        var streak = 0
        while day >= first {
            if trainedDays.contains(day) {
                streak += 1
            } else if scheduledWeekdays.isEmpty || scheduledWeekdays.contains(calendar.mondayIndex(of: day) + 1) {
                break
            }
            day = calendar.day(byAdding: -1, to: day)
        }
        return streak
    }
}

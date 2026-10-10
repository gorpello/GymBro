import DependenciesTestSupport
import Foundation
import ProfileFeature
import SQLiteData
import Testing

@testable import Database

/// Every Profile suite runs on a fresh database, on Wednesday 7 October 2026 at 20:00 UTC.
@Suite(
    .dependencies {
        $0.calendar = calendar
        $0.date.now = now
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct ProfileFeatureSuite {}

let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

let now = date(2026, 10, 7, hour: 20)
let request = ProfileSummary.Request(today: now, calendar: calendar)
let alex = UserProfile(id: UserProfile.singletonID, name: "Alex", handle: "alex", weightKg: 78.5)

func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 10) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
}

/// Alex, who weighs in pounds: a workout last December, two in January, one today (5 × 100 kg,
/// an hour), a moment, and two medals, one not seen yet.
func seedAlex(_ db: Database) throws {
    try db.seed {
        alex
        AppSettings(id: AppSettings.singletonID, units: .lb)
        Moment(id: UUID(-1), date: date(2026, 9, 1))
        Award(id: "firstWorkout", earnedAt: date(2025, 12, 30), isSeen: true)
        Award(id: "firstStep", earnedAt: date(2025, 12, 30))
        for (index, day) in [date(2025, 12, 30), date(2026, 1, 5), date(2026, 1, 20), date(2026, 10, 7)].enumerated() {
            Workout(
                id: UUID(-index - 1),
                startedAt: day,
                finishedAt: day.addingTimeInterval(3_600),
                durationSeconds: 3_600
            )
        }
        WorkoutExercise(id: UUID(-1), workoutID: UUID(-4), exerciseID: "EIeI8Vf")
        WorkoutSet(id: UUID(-1), workoutExerciseID: UUID(-1), reps: 5, weightKg: 100, isCompleted: true)
    }
}

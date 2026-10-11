import DependenciesTestSupport
import Foundation
import ProgressFeature
import SQLiteData
import Testing

@testable import Database

/// Every Progress suite runs on a fresh database, on Wednesday 7 October 2026 at 20:00 UTC.
@Suite(
    .dependencies {
        $0.calendar = calendar
        $0.date.now = now
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct ProgressFeatureSuite {}

let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

let now = date(2026, 10, 7, hour: 20)
let request = ProgressSummary.Request(now: now, calendar: calendar)

/// Chest, with triceps.
let bench: Exercise.ID = "EIeI8Vf"
/// Shoulders, with triceps and back.
let press: Exercise.ID = "kTbSH9h"

func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 10) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
}

/// A bench workout five weeks ago, two this week (Monday and today, with the overhead press),
/// a workout still in progress, a check-in on Tuesday, bodyweight, two measurements and a
/// check-in with two photos.
func seedTraining(_ db: Database) throws {
    try db.seed {
        // 1 September, outside the last 30 days: 500 kg.
        Workout(id: UUID(-1), startedAt: date(2026, 9, 1), finishedAt: date(2026, 9, 1, hour: 11))
        WorkoutExercise(id: UUID(-1), workoutID: UUID(-1), exerciseID: bench)
        WorkoutSet(id: UUID(-1), workoutExerciseID: UUID(-1), reps: 5, weightKg: 100, isCompleted: true)

        // Monday: a warm-up and two working sets, 1,000 kg.
        Workout(id: UUID(-2), startedAt: date(2026, 10, 5), finishedAt: date(2026, 10, 5, hour: 11))
        WorkoutExercise(id: UUID(-2), workoutID: UUID(-2), exerciseID: bench)
        WorkoutSet(
            id: UUID(-2), workoutExerciseID: UUID(-2), reps: 10, weightKg: 40, kind: .warmup, isCompleted: true
        )
        WorkoutSet(
            id: UUID(-3), workoutExerciseID: UUID(-2), position: 1, reps: 5, weightKg: 100, isCompleted: true
        )
        WorkoutSet(
            id: UUID(-4), workoutExerciseID: UUID(-2), position: 2, reps: 5, weightKg: 100, isCompleted: true
        )

        // Today: a heavier triple and the overhead press, 715 kg.
        Workout(id: UUID(-3), startedAt: date(2026, 10, 7), finishedAt: date(2026, 10, 7, hour: 11))
        WorkoutExercise(id: UUID(-3), workoutID: UUID(-3), exerciseID: bench)
        WorkoutExercise(id: UUID(-4), workoutID: UUID(-3), exerciseID: press, position: 1)
        WorkoutSet(id: UUID(-5), workoutExerciseID: UUID(-3), reps: 3, weightKg: 105, isCompleted: true)
        WorkoutSet(id: UUID(-6), workoutExerciseID: UUID(-4), reps: 8, weightKg: 50, isCompleted: true)

        // Still in progress, so it doesn't count yet.
        Workout(id: UUID(-4), startedAt: date(2026, 10, 7, hour: 17))
        WorkoutExercise(id: UUID(-5), workoutID: UUID(-4), exerciseID: bench)
        WorkoutSet(id: UUID(-7), workoutExerciseID: UUID(-5), reps: 10, weightKg: 100, isCompleted: true)

        CheckIn(id: UUID(-1), day: date(2026, 10, 6, hour: 0))

        BodyMeasurement(id: UUID(-1), date: date(2026, 9, 20), kind: .bodyweight, value: 80)
        BodyMeasurement(id: UUID(-2), date: date(2026, 10, 6), kind: .bodyweight, value: 81.4)
        BodyMeasurement(id: UUID(-3), date: date(2026, 9, 1), kind: .waist, value: 83)
        BodyMeasurement(id: UUID(-4), date: date(2026, 10, 1), kind: .waist, value: 82)
        BodyMeasurement(id: UUID(-5), date: date(2026, 10, 1), kind: .bodyFat, value: 14)

        ProgressEntry(id: UUID(-1), date: date(2026, 10, 1), frontPhoto: "front.jpg", sidePhoto: "side.jpg")
    }
}

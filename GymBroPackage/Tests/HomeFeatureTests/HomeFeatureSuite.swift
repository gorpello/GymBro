import DependenciesTestSupport
import Foundation
import HomeFeature
import SQLiteData
import Testing

@testable import Database

/// Every Home suite runs on a fresh database, on Wednesday 7 October 2026 at 20:00 UTC.
@Suite(
    .dependencies {
        $0.calendar = calendar
        $0.date.now = now
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct HomeFeatureSuite {}

let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

let now = date(2026, 10, 7, hour: 20)
let request = HomeSummary.Request(today: now, calendar: calendar)

let bench: Exercise.ID = "EIeI8Vf"
let press: Exercise.ID = "kTbSH9h"

func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 10) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
}

/// A Push routine planned on Wednesdays, a workout last Tuesday, one on Monday and one today,
/// a workout still in progress and a check-in on Tuesday.
func seedTrainingWeek(_ db: Database) throws {
    try db.seed {
        Routine(id: UUID(-1), name: "Push")
        RoutineSchedule(id: UUID(-1), routineID: UUID(-1), weekday: 3)
        RoutineExercise(id: UUID(-1), routineID: UUID(-1), exerciseID: bench)
        RoutineExercise(id: UUID(-2), routineID: UUID(-1), exerciseID: press, position: 1)

        // Last week.
        Workout(id: UUID(-1), startedAt: date(2026, 9, 29), finishedAt: date(2026, 9, 29, hour: 11))
        WorkoutExercise(id: UUID(-1), workoutID: UUID(-1), exerciseID: bench)
        WorkoutSet(id: UUID(-1), workoutExerciseID: UUID(-1), reps: 5, weightKg: 90, isCompleted: true)

        // Monday: a warm-up, a working set and a set never ticked.
        Workout(id: UUID(-2), startedAt: date(2026, 10, 5), finishedAt: date(2026, 10, 5, hour: 11))
        WorkoutExercise(id: UUID(-2), workoutID: UUID(-2), exerciseID: bench)
        WorkoutSet(
            id: UUID(-2), workoutExerciseID: UUID(-2), reps: 10, weightKg: 40, kind: .warmup, isCompleted: true
        )
        WorkoutSet(
            id: UUID(-3), workoutExerciseID: UUID(-2), position: 1, reps: 5, weightKg: 100, isCompleted: true
        )
        WorkoutSet(id: UUID(-4), workoutExerciseID: UUID(-2), position: 2, reps: 5, weightKg: 100)

        // Today: a lighter set, then a workout still in progress.
        Workout(id: UUID(-3), startedAt: date(2026, 10, 7), finishedAt: date(2026, 10, 7, hour: 11))
        WorkoutExercise(id: UUID(-3), workoutID: UUID(-3), exerciseID: bench)
        WorkoutSet(id: UUID(-5), workoutExerciseID: UUID(-3), reps: 3, weightKg: 100, isCompleted: true)
        Workout(id: UUID(-4), startedAt: date(2026, 10, 7, hour: 17))
        WorkoutExercise(id: UUID(-4), workoutID: UUID(-4), exerciseID: bench)
        WorkoutSet(id: UUID(-6), workoutExerciseID: UUID(-4), reps: 10, weightKg: 100, isCompleted: true)

        // Tuesday, trained without logging.
        CheckIn(id: UUID(-1), day: date(2026, 10, 6, hour: 0))
    }
}

import Clocks
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import Database

/// Every Session suite runs on a fresh database, on Wednesday 7 October 2026 at 18:00 UTC, with a
/// clock that only moves when a test advances it.
@Suite(
    .dependencies {
        $0.calendar = calendar
        $0.continuousClock = TestClock()
        $0.date.now = now
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct SessionFeatureSuite {}

let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 18))!

let bench: Exercise.ID = "EIeI8Vf"
let press: Exercise.ID = "kTbSH9h"

/// Push on Wednesdays (bench, then press) and Pull, unscheduled, plus last Monday's bench press:
/// 8 × 90 kg twice.
func seedRoutinesAndHistory(_ db: Database) throws {
    let monday = now.addingTimeInterval(-2 * 86_400)
    try db.seed {
        Routine(id: UUID(-1), name: "Push")
        RoutineSchedule(id: UUID(-1), routineID: UUID(-1), weekday: 3)
        RoutineExercise(id: UUID(-1), routineID: UUID(-1), exerciseID: bench)
        RoutineExercise(id: UUID(-2), routineID: UUID(-1), exerciseID: press, position: 1, setCount: 2)
        Routine(id: UUID(-2), name: "Pull", position: 1)

        Workout(id: UUID(-1), startedAt: monday, finishedAt: monday.addingTimeInterval(3_600))
        WorkoutExercise(id: UUID(-1), workoutID: UUID(-1), exerciseID: bench)
        WorkoutSet(id: UUID(-1), workoutExerciseID: UUID(-1), reps: 8, weightKg: 90, isCompleted: true)
        WorkoutSet(id: UUID(-2), workoutExerciseID: UUID(-1), position: 1, reps: 8, weightKg: 90, isCompleted: true)
    }
}

/// Seeds routines and history, then starts Push.
func startPush(_ db: Database) throws {
    try seedRoutinesAndHistory(db)
    try LiveWorkout.start(db, routineID: UUID(-1), now: now)
}

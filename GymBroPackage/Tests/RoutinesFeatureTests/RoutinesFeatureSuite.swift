import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import Database

/// Every Routines suite runs on a fresh database (with the bundled catalogue), on Wednesday
/// 7 October 2026 at 20:00 UTC.
@Suite(
    .dependencies {
        $0.date.now = now
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct RoutinesFeatureSuite {}

let now: Date = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 20))!
}()

let push = UUID(-1)
let pull = UUID(-2)
let legs = UUID(-3)
/// Chest, barbell.
let bench: Exercise.ID = "EIeI8Vf"
/// Shoulders, barbell.
let press: Exercise.ID = "kTbSH9h"

/// "Push" and "Pull" in the "PPL" folder, an unnamed ungrouped routine, and a plan of Push on
/// Monday, Pull on Wednesday and both on Friday.
func seedRoutines(_ db: Database) throws {
    try db.seed {
        Routine(id: push, name: "Push", group: "PPL", position: 0)
        Routine(id: legs, name: "", position: 1)
        Routine(id: pull, name: "Pull", group: "PPL", colorIndex: 4, position: 2)
        RoutineExercise(id: UUID(-1), routineID: push, exerciseID: bench, position: 0)
        RoutineExercise(id: UUID(-2), routineID: push, exerciseID: press, position: 1, setCount: 4)
        PlannedSet(id: UUID(-1), routineExerciseID: UUID(-1), position: 0, reps: 8)
        RoutineSchedule(id: UUID(-1), routineID: push, weekday: 1)
        RoutineSchedule(id: UUID(-2), routineID: pull, weekday: 3)
        RoutineSchedule(id: UUID(-3), routineID: pull, weekday: 5)
        RoutineSchedule(id: UUID(-4), routineID: push, weekday: 5)
    }
}

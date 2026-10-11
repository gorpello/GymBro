import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import Database

/// Every Exercises suite runs on a fresh database (with the bundled catalogue), on Wednesday
/// 7 October 2026 at 20:00 UTC.
@Suite(
    .dependencies {
        $0.date.now = now
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct ExercisesFeatureSuite {}

let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

let now = date(2026, 10, 7, hour: 20)

/// Chest, with triceps; barbell, intermediate.
let bench: Exercise.ID = "EIeI8Vf"

func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 10) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
}

/// Three bench workouts (1 September, Monday and today), a favourite, a note on the bench and a
/// custom exercise that's never been trained.
func seedBench(_ db: Database) throws {
    try db.seed {
        Workout(id: UUID(-1), startedAt: date(2026, 9, 1), finishedAt: date(2026, 9, 1, hour: 11))
        WorkoutExercise(id: UUID(-1), workoutID: UUID(-1), exerciseID: bench)
        WorkoutSet(id: UUID(-1), workoutExerciseID: UUID(-1), reps: 5, weightKg: 100, isCompleted: true)

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

        Workout(id: UUID(-3), startedAt: date(2026, 10, 7), finishedAt: date(2026, 10, 7, hour: 11))
        WorkoutExercise(id: UUID(-3), workoutID: UUID(-3), exerciseID: bench)
        WorkoutSet(id: UUID(-5), workoutExerciseID: UUID(-3), reps: 3, weightKg: 105, isCompleted: true)

        ExercisePreference(exerciseID: bench, isFavorite: true)
        Note(id: UUID(-1), exerciseID: bench, text: "Elbows in")

        Exercise(
            id: "custom-sled",
            name: "Sled Push",
            primaryMuscle: .quads,
            secondaryMuscles: [.glutes],
            equipment: .other,
            isCustom: true
        )
    }
}

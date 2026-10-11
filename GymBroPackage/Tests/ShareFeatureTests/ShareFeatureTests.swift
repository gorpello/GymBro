import DependenciesTestSupport
import Foundation
import SQLiteData
import ShareFeature
import Testing

@testable import Database

/// Share cards and the Strava list, on a fresh database, on Wednesday 7 October 2026 at 20:00 UTC.
@Suite(
    .dependencies {
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
        try $0.defaultDatabase.write(seedWeek)
    }
)
struct ShareFeatureTests {
    @Dependency(\.defaultDatabase) var database

    @Test func shareCardsReadTheStreakTheGridAndTheWeeksMuscles() throws {
        let summary = try database.read { db in
            try ShareSummary.Request(today: date(7, hour: 20), calendar: calendar).fetch(db)
        }

        #expect(summary.streak == 2)
        // The last row is this week; Monday and Tuesday are trained.
        let thisWeek = try #require(summary.activity.last)
        #expect(thisWeek.map { $0 > 0 } == [true, true, false, false, false, false, false])
        #expect(summary.muscleLevels.keys.sorted() == ["back", "chest", "shoulders", "triceps"])
    }

    @Test func stravaListsFinishedWorkoutsNewestFirst() throws {
        let workouts = try database.read { db in try StravaWorkout.Request().fetch(db) }

        #expect(workouts.map(\.id) == [UUID(-2), UUID(-1)])
        #expect(workouts.map(\.routineName) == [nil, "Push"])
        #expect(workouts.map(\.setCount) == [1, 2])
        #expect(workouts.map(\.durationSeconds) == [1_800, 3_600])
    }
}

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

/// A day of October 2026, in UTC. The 5th is a Monday.
private func date(_ day: Int, hour: Int = 10) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
}

/// Monday: "Push", two bench sets. Tuesday: the seated press after a warm-up. Today: a
/// workout still in progress.
private func seedWeek(_ db: Database) throws {
    try db.seed {
        Routine(id: UUID(-1), name: "Push")
        Workout(
            id: UUID(-1), startedAt: date(5), finishedAt: date(5, hour: 11), durationSeconds: 3_600,
            routineID: UUID(-1)
        )
        WorkoutExercise(id: UUID(-1), workoutID: UUID(-1), exerciseID: "EIeI8Vf")
        WorkoutSet(id: UUID(-1), workoutExerciseID: UUID(-1), reps: 5, weightKg: 100, isCompleted: true)
        WorkoutSet(id: UUID(-2), workoutExerciseID: UUID(-1), position: 1, reps: 5, weightKg: 100, isCompleted: true)

        Workout(id: UUID(-2), startedAt: date(6), finishedAt: date(6, hour: 11), durationSeconds: 1_800)
        WorkoutExercise(id: UUID(-2), workoutID: UUID(-2), exerciseID: "kTbSH9h")
        WorkoutSet(id: UUID(-3), workoutExerciseID: UUID(-2), reps: 10, weightKg: 20, kind: .warmup, isCompleted: true)
        WorkoutSet(id: UUID(-4), workoutExerciseID: UUID(-2), position: 1, reps: 8, weightKg: 40, isCompleted: true)

        Workout(id: UUID(-3), startedAt: date(7))
        WorkoutExercise(id: UUID(-3), workoutID: UUID(-3), exerciseID: "EIeI8Vf")
        WorkoutSet(id: UUID(-5), workoutExerciseID: UUID(-3), reps: 5, weightKg: 100, isCompleted: true)
    }
}

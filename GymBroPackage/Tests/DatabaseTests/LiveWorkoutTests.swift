import Dependencies
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import Database

/// The workout in progress, on a fresh database, on Wednesday 7 October 2026 at 18:00 UTC.
@Suite(
    .dependencies {
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct LiveWorkoutTests {
    @Dependency(\.defaultDatabase) var database

    @Test func routineOpensWithItsPlanFilledInFromHistory() throws {
        let sets = try database.write { db in
            try seedHistory(db, bench: [(5, 100), (5, 100)])
            try db.seed {
                Routine(id: UUID(-1), name: "Push")
                RoutineExercise(id: UUID(-1), routineID: UUID(-1), exerciseID: bench)
                PlannedSet(id: UUID(-1), routineExerciseID: UUID(-1), reps: 3)
                PlannedSet(id: UUID(-2), routineExerciseID: UUID(-1), position: 1)
                RoutineExercise(id: UUID(-2), routineID: UUID(-1), exerciseID: press, position: 1, setCount: 2)
            }
            try LiveWorkout.start(db, routineID: UUID(-1), now: now)
            return try openedSets(db)
        }
        #expect(sets[bench] == [Pair(3, 100), Pair(5, 100)])
        #expect(sets[press] == [Pair(10, 20), Pair(10, 20)])

        let workout = try #require(try database.read { db in try LiveWorkout.fetch(db) })
        #expect(workout.routineID == UUID(-1))
        #expect(workout.startedAt == now)
        #expect(workout.resumedAt == now)
    }

    @Test func startingAgainResumesTheWorkoutInProgress() throws {
        let (first, second) = try database.write { db in
            (
                try LiveWorkout.start(db, exerciseIDs: [bench], now: now),
                try LiveWorkout.start(db, exerciseIDs: [press], now: now.addingTimeInterval(60))
            )
        }
        #expect(first == second)
        #expect(try database.read { db in try Workout.all.fetchCount(db) } == 1)
    }

    @Test func unknownExercisesAreSkipped() throws {
        let exerciseIDs = try database.write { db in
            try LiveWorkout.start(db, exerciseIDs: ["not-an-exercise", press, bench], now: now)
            return try WorkoutExercise.order(by: \.position).select(\.exerciseID).fetchAll(db)
        }
        #expect(exerciseIDs == [press, bench])
    }

    @Test func pausingBanksTheClock() throws {
        let workout = try database.write { db in
            let id = try LiveWorkout.start(db, exerciseIDs: [bench], now: now)
            try LiveWorkout.pause(db, workoutID: id, now: now.addingTimeInterval(60))
            return try Workout.find(id).fetchOne(db)
        }
        let paused = try #require(workout)
        #expect(paused.isPaused)
        #expect(paused.elapsedSeconds(at: now.addingTimeInterval(600)) == 60)

        let resumed = try database.write { db in
            try LiveWorkout.resume(db, workoutID: paused.id, now: now.addingTimeInterval(600))
            return try Workout.find(paused.id).fetchOne(db)
        }
        #expect(resumed?.elapsedSeconds(at: now.addingTimeInterval(630)) == 90)
    }

    @Test func restStopsWhileThePauseIsOnAndCanBeNudged() throws {
        let id = try database.write { db in
            let id = try LiveWorkout.start(db, exerciseIDs: [bench], now: now)
            try LiveWorkout.startRest(db, workoutID: id, seconds: 90, now: now)
            try LiveWorkout.pause(db, workoutID: id, now: now.addingTimeInterval(30))
            try LiveWorkout.resume(db, workoutID: id, now: now.addingTimeInterval(100))
            return id
        }
        var workout = try #require(try database.read { db in try Workout.find(id).fetchOne(db) })
        #expect(workout.restRemainingSeconds(at: now.addingTimeInterval(110)) == 50)

        try database.write { db in
            try LiveWorkout.adjustRest(db, workoutID: id, by: -60, now: now.addingTimeInterval(110))
        }
        workout = try #require(try database.read { db in try Workout.find(id).fetchOne(db) })
        #expect(workout.restRemainingSeconds(at: now.addingTimeInterval(110)) == 5)
        #expect(workout.restRemainingSeconds(at: now.addingTimeInterval(115)) == nil)
    }

    @Test func restIsTheExercisesOwnOrTheDefault() throws {
        let (own, fallback) = try database.write { db in
            try db.seed {
                AppSettings(id: AppSettings.singletonID, restSeconds: 120)
                ExercisePreference(exerciseID: bench, restSeconds: 60)
            }
            return (
                try LiveWorkout.restSeconds(db, exerciseID: bench),
                try LiveWorkout.restSeconds(db, exerciseID: press)
            )
        }
        #expect(own == 60)
        #expect(fallback == 120)
    }

    @Test func addedSetsCopyTheLastOneAndWarmUpsGoFirst() throws {
        let sets = try database.write { db in
            try LiveWorkout.start(db, exerciseIDs: [bench], now: now)
            let exerciseID = try #require(try WorkoutExercise.select(\.id).fetchOne(db))
            let last = try #require(try WorkoutSet.order { $0.position.desc() }.fetchOne(db))
            try LiveWorkout.adjustSet(db, id: last.id, reps: -2, weightKg: 40)
            try LiveWorkout.addSet(db, to: exerciseID)
            try LiveWorkout.addWarmup(db, to: exerciseID)
            return try WorkoutSet.order(by: \.position).fetchAll(db)
        }
        #expect(sets.map(\.kind) == [.warmup, .normal, .normal, .normal, .normal])
        #expect(
            sets.map { Pair($0.reps, $0.weightKg) } == [
                Pair(10, 10), Pair(10, 20), Pair(10, 20), Pair(8, 60), Pair(8, 60),
            ])
    }

    @Test func finishingFilesOnlyTickedSets() throws {
        let finished = try database.write { db in
            let id = try LiveWorkout.start(db, exerciseIDs: [bench, press], now: now)
            let firstBenchSet = try #require(
                try WorkoutSet
                    .join(WorkoutExercise.all) { $0.workoutExerciseID.eq($1.id) }
                    .where { _, workoutExercises in workoutExercises.exerciseID.eq(bench) }
                    .order { workoutSets, _ in workoutSets.position }
                    .select { workoutSets, _ in workoutSets }
                    .fetchOne(db)
            )
            try LiveWorkout.toggleSet(db, id: firstBenchSet.id)
            return try LiveWorkout.finish(db, workoutID: id, now: now.addingTimeInterval(2_700), calendar: calendar)
        }
        #expect(
            finished
                == FinishedWorkout(
                    durationSeconds: 2_700,
                    setCount: 1,
                    volumeKg: 200,
                    recordCount: 1,
                    previousVolumeKg: nil,
                    newAwards: [.firstWorkout, .firstRecord]
                )
        )
        try database.read { db in
            #expect(try LiveWorkout.fetch(db) == nil)
            #expect(try WorkoutExercise.select(\.exerciseID).fetchAll(db) == [bench])
            #expect(try WorkoutSet.all.fetchCount(db) == 1)
        }
    }

    @Test func finishingWithNothingTickedLogsNothing() throws {
        let finished = try database.write { db in
            let id = try LiveWorkout.start(db, exerciseIDs: [bench], now: now)
            return try LiveWorkout.finish(db, workoutID: id, now: now.addingTimeInterval(60), calendar: calendar)
        }
        #expect(finished == nil)
        #expect(try database.read { db in try Workout.all.fetchCount(db) } == 0)
    }

    @Test func aSecondWorkoutIsComparedWithTheFirst() throws {
        let finished = try database.write { db in
            try seedHistory(db, bench: [(5, 100), (5, 100)])
            let id = try LiveWorkout.start(db, exerciseIDs: [bench], now: now)
            for set in try WorkoutSet.where({ $0.workoutExerciseID.neq(UUID(-1)) }).fetchAll(db) {
                try LiveWorkout.toggleSet(db, id: set.id)
            }
            return try LiveWorkout.finish(db, workoutID: id, now: now.addingTimeInterval(60), calendar: calendar)
        }
        // Same sets as last time: no record, same volume.
        #expect(finished?.recordCount == 0)
        #expect(finished?.volumeKg == 1_000)
        #expect(finished?.previousVolumeKg == 1_000)
    }

    @Test func historyIsTheLastFinishedWorkoutsWorkingSets() throws {
        let sets = try database.write { db in
            try seedHistory(db, bench: [(5, 100), (3, 105)])
            try db.seed {
                WorkoutSet(
                    id: UUID(-10), workoutExerciseID: UUID(-1), reps: 10, weightKg: 40, kind: .warmup, isCompleted: true
                )
            }
            try LiveWorkout.start(db, exerciseIDs: [bench], now: now)
            return try ExerciseHistory.lastWorkingSets(db, exerciseID: bench)
        }
        #expect(sets.map { Pair($0.reps, $0.weightKg) } == [Pair(5, 100), Pair(3, 105)])
    }
}

private let bench: Exercise.ID = "EIeI8Vf"
private let press: Exercise.ID = "kTbSH9h"

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 18))!

/// Reps and weight of a set, for comparing.
private struct Pair: Equatable {
    var reps: Int
    var weightKg: Double

    init(_ reps: Int, _ weightKg: Double) {
        self.reps = reps
        self.weightKg = weightKg
    }
}

/// A bench press workout finished on Monday with these completed sets, `(reps, weightKg)` each.
private func seedHistory(_ db: Database, bench sets: [(Int, Double)]) throws {
    let monday = now.addingTimeInterval(-2 * 86_400)
    try db.seed {
        Workout(id: UUID(-1), startedAt: monday, finishedAt: monday.addingTimeInterval(3_600))
        WorkoutExercise(id: UUID(-1), workoutID: UUID(-1), exerciseID: bench)
        for (position, set) in sets.enumerated() {
            WorkoutSet(
                id: UUID(-100 - position),
                workoutExerciseID: UUID(-1),
                position: position,
                reps: set.0,
                weightKg: set.1,
                isCompleted: true
            )
        }
    }
}

/// The live workout's sets, by exercise, in order.
private func openedSets(_ db: Database) throws -> [Exercise.ID: [Pair]] {
    let workoutID = try #require(try LiveWorkout.fetch(db)?.id)
    let rows =
        try WorkoutSet
        .join(WorkoutExercise.all) { $0.workoutExerciseID.eq($1.id) }
        .where { _, workoutExercises in workoutExercises.workoutID.eq(workoutID) }
        .order { workoutSets, _ in workoutSets.position }
        .select { workoutSets, workoutExercises in
            (workoutExercises.exerciseID, workoutSets.reps, workoutSets.weightKg)
        }
        .fetchAll(db)
    return Dictionary(grouping: rows, by: \.0).mapValues { $0.map { Pair($0.1, $0.2) } }
}

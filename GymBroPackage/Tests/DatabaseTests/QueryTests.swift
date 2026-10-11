import Dependencies
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import Database

/// The core reads behind Home, Progress, Session and the medals, run against a saved history:
/// only completed working sets of finished workouts may count.
@Suite(
    .dependencies {
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
        try $0.defaultDatabase.write(seedHistory)
    }
)
struct QueryTests {
    @Dependency(\.defaultDatabase) var database

    // MARK: History

    @Test func historyIsOldestFirstAndOnlyCountsFinishedWorkingSets() throws {
        let sets = try database.read { db in try PersonalRecord.fetchSets(db) }
        #expect(sets.map(\.workoutID) == [lastWeek, monday, monday, tuesday])
        #expect(sets.map(\.exerciseID) == [bench, bench, bench, press])
        #expect(sets.map(\.weightKg) == [90, 100, 100, 50])
    }

    @Test func historyCanBeNarrowedToSomeExercises() throws {
        let sets = try database.read { db in try PersonalRecord.fetchSets(db, exerciseIDs: [press]) }
        #expect(sets.map(\.workoutID) == [tuesday])
        #expect(try database.read { db in try PersonalRecord.fetchSets(db, exerciseIDs: []) }.isEmpty)
    }

    @Test func lastTimeIsTheLatestFinishedWorkout() throws {
        // The bench in today's unfinished workout doesn't count yet.
        let sets = try database.read { db in try ExerciseHistory.lastWorkingSets(db, exerciseID: bench) }
        #expect(sets.map(\.weightKg) == [100, 100])
        #expect(try database.read { db in try ExerciseHistory.lastWorkingSets(db, exerciseID: "never") }.isEmpty)
    }

    // MARK: PRs

    @Test func recordsComeFromSavedSetsOnly() throws {
        let records = try database.read { db in PersonalRecord.records(from: try PersonalRecord.fetchSets(db)) }
        #expect(records.map(\.exerciseID) == [bench, press])
        // 5 × 100 kg on Monday beats 5 × 90 kg; the unfinished 5 × 110 kg doesn't exist yet.
        #expect(records[0].best == 100)
        #expect(records[0].date == date(5))
        #expect(records[1].best == 50)
    }

    // MARK: Weekly volume

    @Test func weeklyVolumeCountsOnlyThatWeek() throws {
        let week = try database.read { db in try WorkoutTotal.fetch(db, from: date(5), to: date(12)) }
        // Tuesday's warm-up-only workout has no working sets, so it isn't listed.
        #expect(
            week == [
                WorkoutTotal(id: monday, startedAt: date(5), setCount: 2, volumeKg: 1_000),
                WorkoutTotal(id: tuesday, startedAt: date(6), setCount: 1, volumeKg: 400),
            ]
        )
        #expect(week.reduce(0) { $0 + $1.volumeKg } == 1_400)
    }

    @Test func volumeWithNoEndReadsUpToNow() throws {
        let totals = try database.read { db in try WorkoutTotal.fetch(db, from: date(1)) }
        #expect(totals.map(\.id) == [lastWeek, monday, tuesday])
    }

    // MARK: Muscles, totals and streak

    @Test func trainedSetsCarryTheirMuscles() throws {
        let sets = try database.read { db in try MuscleLoad.fetchSets(db, since: date(5)) }
        #expect(sets.map(\.primaryMuscle).sorted { $0.rawValue < $1.rawValue } == [.chest, .chest, .shoulders])
    }

    @Test func allTimeTotals() throws {
        let totals = try database.read { db in try TrainingTotals.fetch(db, today: date(7), calendar: calendar) }
        #expect(totals.workoutCount == 4)
        #expect(totals.setCount == 4)
        #expect(totals.volumeKg == 450 + 1_000 + 400)
        #expect(totals.recordCount == 2)
        #expect(totals.trainingSeconds == 4 * 3_600)
    }

    @Test func streakCountsBackFromYesterdayAndIncludesCheckIns() throws {
        // Sunday, Monday and Tuesday are trained; today isn't yet.
        #expect(try database.read { db in try Streak.fetch(db, today: date(7, hour: 20), calendar: calendar) } == 3)

        try database.write { db in try db.seed { CheckIn(id: UUID(-1), day: date(7, hour: 0)) } }
        #expect(try database.read { db in try Streak.fetch(db, today: date(7, hour: 20), calendar: calendar) } == 4)
    }
}

private let bench: Exercise.ID = "EIeI8Vf"
private let press: Exercise.ID = "kTbSH9h"
private let lastWeek = UUID(-1)
private let monday = UUID(-2)
private let tuesday = UUID(-3)
private let warmupOnly = UUID(-4)
private let inProgress = UUID(-5)

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

/// A day of October 2026, in UTC. The 5th is a Monday.
private func date(_ day: Int, hour: Int = 10) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
}

/// Sunday 4 October: bench 5 × 90 kg. Monday: bench 2 × 5 × 100 kg after a warm-up, plus a set
/// left unticked. Tuesday: press 8 × 50 kg, and a second workout with only a warm-up. Today
/// (Wednesday): bench 5 × 110 kg in a workout that isn't finished.
private func seedHistory(_ db: Database) throws {
    try db.seed {
        Workout(id: lastWeek, startedAt: date(4), finishedAt: date(4, hour: 11), durationSeconds: 3_600)
        WorkoutExercise(id: UUID(-1), workoutID: lastWeek, exerciseID: bench)
        WorkoutSet(id: UUID(-1), workoutExerciseID: UUID(-1), reps: 5, weightKg: 90, isCompleted: true)

        Workout(id: monday, startedAt: date(5), finishedAt: date(5, hour: 11), durationSeconds: 3_600)
        WorkoutExercise(id: UUID(-2), workoutID: monday, exerciseID: bench)
        WorkoutSet(
            id: UUID(-2), workoutExerciseID: UUID(-2), reps: 10, weightKg: 40, kind: .warmup, isCompleted: true
        )
        WorkoutSet(id: UUID(-3), workoutExerciseID: UUID(-2), position: 1, reps: 5, weightKg: 100, isCompleted: true)
        WorkoutSet(id: UUID(-4), workoutExerciseID: UUID(-2), position: 2, reps: 5, weightKg: 100, isCompleted: true)
        WorkoutSet(id: UUID(-5), workoutExerciseID: UUID(-2), position: 3, reps: 5, weightKg: 100)

        Workout(id: tuesday, startedAt: date(6), finishedAt: date(6, hour: 11), durationSeconds: 3_600)
        WorkoutExercise(id: UUID(-3), workoutID: tuesday, exerciseID: press)
        WorkoutSet(id: UUID(-6), workoutExerciseID: UUID(-3), reps: 8, weightKg: 50, isCompleted: true)

        Workout(id: warmupOnly, startedAt: date(6, hour: 18), finishedAt: date(6, hour: 19), durationSeconds: 3_600)
        WorkoutExercise(id: UUID(-4), workoutID: warmupOnly, exerciseID: bench)
        WorkoutSet(
            id: UUID(-7), workoutExerciseID: UUID(-4), reps: 10, weightKg: 40, kind: .warmup, isCompleted: true
        )

        Workout(id: inProgress, startedAt: date(7))
        WorkoutExercise(id: UUID(-5), workoutID: inProgress, exerciseID: bench)
        WorkoutSet(id: UUID(-8), workoutExerciseID: UUID(-5), reps: 5, weightKg: 110, isCompleted: true)
    }
}

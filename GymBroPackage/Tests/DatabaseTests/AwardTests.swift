import Dependencies
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import Database

/// Medal rules, on a fresh database, on Wednesday 7 October 2026 at 20:00 UTC.
@Suite(
    .dependencies {
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct AwardTests {
    @Dependency(\.defaultDatabase) var database

    @Test func emptyDatabaseEarnsNothing() throws {
        let earned = try database.write { db in try refresh(db) }
        #expect(earned.isEmpty)
        #expect(try database.read { db in try Award.all.fetchCount(db) } == 0)
    }

    @Test func firstSessionEarnsTheFirstMedals() throws {
        let earned = try database.write { db in
            try db.seed {
                UserProfile(id: UserProfile.singletonID)
                Routine(id: UUID(-1), name: "Push")
            }
            try seedWorkout(db, id: -1, day: 7, sets: [(5, 100)])
            return try refresh(db)
        }
        #expect(earned == [.firstStep, .firstWorkout, .firstRoutine, .firstRecord])

        let awards = try database.read { db in try Award.order(by: \.id).fetchAll(db) }
        #expect(awards.map(\.id) == ["firstRecord", "firstRoutine", "firstStep", "firstWorkout"])
        #expect(awards.allSatisfy { $0.earnedAt == now && !$0.isSeen })
    }

    @Test func onlyFinishedWorkingSetsCount() throws {
        let totals = try database.write { db in
            try seedWorkout(db, id: -1, day: 6, sets: [(5, 100)], durationSeconds: 3_600)
            try db.seed {
                // A warm-up and a set never ticked.
                WorkoutSet(
                    id: UUID(-10), workoutExerciseID: UUID(-1), reps: 10, weightKg: 40, kind: .warmup, isCompleted: true
                )
                WorkoutSet(id: UUID(-11), workoutExerciseID: UUID(-1), reps: 5, weightKg: 100)
            }
            try seedWorkout(db, id: -2, day: 7, sets: [(5, 100)], isFinished: false)
            return try TrainingTotals.fetch(db, today: now, calendar: calendar)
        }
        var expected = TrainingTotals()
        expected.recordCount = 1
        expected.streak = 1
        expected.workoutCount = 1
        expected.setCount = 1
        expected.volumeKg = 500
        expected.trainingSeconds = 3_600
        #expect(totals == expected)
    }

    @Test func milestonesUnlockAtTheirGoal() throws {
        let earned = try database.write { db in
            // 10 hours and 1,000 kg over three days in a row, ending today.
            try seedWorkout(db, id: -1, day: 5, sets: [(10, 50)], durationSeconds: 18_000)
            try seedWorkout(db, id: -2, day: 6, sets: [(10, 49)], durationSeconds: 17_999)
            try db.seed { CheckIn(id: UUID(-1), day: date(7)) }
            return try refresh(db)
        }
        #expect(earned == [.firstWorkout, .firstRecord, .streak3])

        let more = try database.write { db in
            try seedWorkout(db, id: -3, day: 7, sets: [(1, 10)], durationSeconds: 1)
            return try refresh(db)
        }
        #expect(more == [.tonne1, .hours10])
    }

    @Test func medalsAreKeptWithTheDayTheyWereEarned() throws {
        try database.write { db in
            try seedWorkout(db, id: -1, day: 7, sets: [(5, 100)])
            try refresh(db)
            try Workout.delete().execute(db)
        }
        let later = now.addingTimeInterval(86_400)
        let earned = try database.write { db in try Award.refresh(db, now: later, calendar: calendar) }
        #expect(earned.isEmpty)
        let firstWorkout = try database.read { db in try Award.find("firstWorkout").fetchOne(db) }
        #expect(firstWorkout?.earnedAt == now)
    }

    @Test func withGamificationOffNewMedalsArentCelebrated() throws {
        try database.write { db in
            try db.seed { AppSettings(id: AppSettings.singletonID, gamification: false) }
            try seedWorkout(db, id: -1, day: 7, sets: [(5, 100)])
            try refresh(db)
        }
        let unseen = try database.read { db in try Award.where { !$0.isSeen }.fetchCount(db) }
        #expect(unseen == 0)
    }

    @Test func markAllSeen() throws {
        try database.write { db in
            try seedWorkout(db, id: -1, day: 7, sets: [(5, 100)])
            try refresh(db)
            try Award.markAllSeen(db)
        }
        let unseen = try database.read { db in try Award.where { !$0.isSeen }.fetchCount(db) }
        #expect(unseen == 0)
    }
}

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private let now = date(7, hour: 20)

/// A day in October 2026.
private func date(_ day: Int, hour: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
}

@discardableResult
private func refresh(_ db: Database) throws -> [AwardKind] {
    try Award.refresh(db, now: now, calendar: calendar)
}

/// A bench press workout on `day` with one completed working set per `(reps, weightKg)`.
private func seedWorkout(
    _ db: Database,
    id: Int,
    day: Int,
    sets: [(reps: Int, weightKg: Double)],
    durationSeconds: Int = 0,
    isFinished: Bool = true
) throws {
    try db.seed {
        Workout(
            id: UUID(id),
            startedAt: date(day, hour: 10),
            finishedAt: isFinished ? date(day, hour: 11) : nil,
            durationSeconds: durationSeconds
        )
        WorkoutExercise(id: UUID(id), workoutID: UUID(id), exerciseID: "EIeI8Vf")
        for (position, set) in sets.enumerated() {
            WorkoutSet(
                id: UUID(id * 100 - position),
                workoutExerciseID: UUID(id),
                position: position,
                reps: set.reps,
                weightKg: set.weightKg,
                isCompleted: true
            )
        }
    }
}

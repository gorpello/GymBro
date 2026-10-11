import DependenciesTestSupport
import Foundation
import SQLiteData
import StickerFeature
import Testing

@testable import Database

/// Sticker contents, on a fresh database, on Wednesday 7 October 2026 at 20:00 UTC.
@Suite(
    .dependencies {
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct StickerFeatureTests {
    @Dependency(\.defaultDatabase) var database
    let request = StickerSummary.Request(today: date(7, hour: 20), calendar: calendar)

    @Test func beforeTheFirstWorkoutItShowsToday() throws {
        let summary = try database.read { db in try request.fetch(db) }

        #expect(summary.workout == nil)
        #expect(summary.date == date(7, hour: 0))
        #expect(summary.weekDone == Array(repeating: false, count: 7))
    }

    @Test func showsTheLatestFinishedWorkout() throws {
        try database.write { db in
            try db.seed {
                Workout(id: UUID(-1), startedAt: date(5), finishedAt: date(5, hour: 11), durationSeconds: 3_480)
                WorkoutExercise(id: UUID(-1), workoutID: UUID(-1), exerciseID: "kTbSH9h", position: 1)
                WorkoutExercise(id: UUID(-2), workoutID: UUID(-1), exerciseID: "EIeI8Vf")
                WorkoutSet(id: UUID(-1), workoutExerciseID: UUID(-2), reps: 10, weightKg: 40, kind: .warmup)
                WorkoutSet(id: UUID(-2), workoutExerciseID: UUID(-2), reps: 5, weightKg: 100, isCompleted: true)
                WorkoutSet(id: UUID(-3), workoutExerciseID: UUID(-1), reps: 8, weightKg: 50, isCompleted: true)

                // Last week's doesn't light up this week; today's isn't finished.
                Workout(id: UUID(-2), startedAt: date(1), finishedAt: date(1, hour: 11))
                Workout(id: UUID(-3), startedAt: date(7))
            }
        }
        let summary = try database.read { db in try request.fetch(db) }

        #expect(summary.workout?.id == UUID(-1))
        #expect(summary.date == date(5))
        #expect(summary.exercises.map(\.id) == ["EIeI8Vf", "kTbSH9h"])
        #expect(summary.setCount == 2)
        #expect(summary.volumeKg == 900)
        #expect(summary.weekDone == [true, false, false, false, false, false, false])
        #expect(summary.streak == 0)
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

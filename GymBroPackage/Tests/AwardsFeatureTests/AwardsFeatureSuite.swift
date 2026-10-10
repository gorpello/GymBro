import AwardsFeature
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import Database

/// Every Awards suite runs on a fresh database, on Wednesday 7 October 2026 at 20:00 UTC.
@Suite(
    .dependencies {
        $0.calendar = calendar
        $0.date.now = now
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct AwardsFeatureSuite {}

let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 20))!
let request = AwardsBoard.Request(today: now, calendar: calendar)

/// A set-up profile and one finished bench press workout today: 5 × 100 kg, 45 minutes.
func seedFirstSession(_ db: Database) throws {
    try db.seed {
        UserProfile(id: UserProfile.singletonID)
        Workout(
            id: UUID(-1),
            startedAt: now.addingTimeInterval(-3_600),
            finishedAt: now.addingTimeInterval(-900),
            durationSeconds: 2_700
        )
        WorkoutExercise(id: UUID(-1), workoutID: UUID(-1), exerciseID: "EIeI8Vf")
        WorkoutSet(id: UUID(-1), workoutExerciseID: UUID(-1), reps: 5, weightKg: 100, isCompleted: true)
    }
}

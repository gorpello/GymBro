import CompareFeature
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import Database

/// Before and after, on a fresh database.
@Suite(
    .dependencies {
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct CompareFeatureTests {
    @Dependency(\.defaultDatabase) var database
    let request = Comparison.Request(calendar: calendar)

    @Test func oneCheckInIsNotEnough() throws {
        try database.write { db in
            try db.seed {
                ProgressEntry(id: UUID(-1), date: date(6, 22), frontPhoto: "a.jpg")
                ProgressEntry(id: UUID(-2), date: date(9, 1), weightKg: 80)
            }
        }
        #expect(try database.read { db in try request.fetch(db) } == Comparison())
    }

    @Test func comparesTheFirstAndLatestCheckInsWithPhotos() throws {
        try database.write { db in
            try db.seed {
                ProgressEntry(id: UUID(-1), date: date(6, 22), weightKg: 82, frontPhoto: "a.jpg", backPhoto: "b.jpg")
                ProgressEntry(id: UUID(-2), date: date(8, 5), sidePhoto: "c.jpg")
                ProgressEntry(id: UUID(-3), date: date(9, 19), weightKg: 79.5, frontPhoto: "d.jpg", backPhoto: "e.jpg")
                // A weigh-in without photos isn't part of the timeline.
                ProgressEntry(id: UUID(-4), date: date(9, 30), weightKg: 79)
            }
        }
        let pair = try #require(try database.read { db in try request.fetch(db) }.pair)

        #expect(pair.before.id == UUID(-1))
        #expect(pair.after.id == UUID(-3))
        #expect(pair.daysApart == 89)
        #expect(pair.weightChangeKg == -2.5)
        #expect(pair.poses == ["front", "back"])
    }

    @Test func aPoseMissingOnEitherDayFallsBackToOneTheyShare() {
        let pair = ComparePair(
            before: ProgressEntry(id: UUID(-1), frontPhoto: "a.jpg", backPhoto: "b.jpg"),
            after: ProgressEntry(id: UUID(-2), sidePhoto: "c.jpg", backPhoto: "d.jpg"),
            daysApart: 1
        )
        #expect(pair.shownPose(picked: "side") == "back")
        #expect(pair.shownPose(picked: "back") == "back")
        #expect(Compare.State().shownPose == nil)
    }
}

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private func date(_ month: Int, _ day: Int) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 9))!
}

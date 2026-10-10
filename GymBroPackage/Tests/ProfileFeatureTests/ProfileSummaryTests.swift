import CustomDump
import Dependencies
import Foundation
import L10n
import SQLiteData
import Testing

@testable import Database
@testable import ProfileFeature

extension ProfileFeatureSuite {
    @Suite struct ProfileSummaryTests {
        @Dependency(\.defaultDatabase) var database

        @Test func emptyDatabaseShowsTheDefaults() throws {
            let summary = try database.read { db in try request.fetch(db) }
            expectNoDifference(summary, ProfileSummary())
            #expect(summary.level == 1)
            #expect(summary.workoutsToNextLevel == 10)
        }

        @Test func summarisesProfileTotalsMedalsAndYear() throws {
            try database.write(seedAlex)
            let summary = try database.read { db in try request.fetch(db) }

            var expected = ProfileSummary()
            expected.profile = alex
            expected.units = .lb
            expected.totals.isOnboarded = true
            expected.totals.recordCount = 1
            expected.totals.streak = 1
            expected.totals.workoutCount = 4
            expected.totals.setCount = 1
            expected.totals.volumeKg = 500
            expected.totals.trainingSeconds = 14_400
            expected.medalCount = 2
            expected.shelf = [
                .init(kind: .firstStep, isEarned: true, isNew: true),
                .init(kind: .firstWorkout, isEarned: true),
                .init(kind: .firstRoutine),
                .init(kind: .firstRecord),
            ]
            expected.momentCount = 1
            expected.yearMonths = [2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
            expectNoDifference(summary, expected)
            #expect(summary.workoutsToNextLevel == 6)
        }

        @Test func everyTenWorkoutsIsALevel() {
            var summary = ProfileSummary()
            summary.totals.workoutCount = 19
            #expect(summary.level == 2)
            #expect(summary.workoutsToNextLevel == 1)
            summary.totals.workoutCount = 20
            #expect(summary.level == 3)
            #expect(summary.workoutsToNextLevel == 10)
        }
    }

    @Suite struct ProfileFormatTests {
        let english = Locale(identifier: "en_US")

        @Test func liftedSwitchesToTonnesAtAThousand() {
            #expect(ProfileFormat.lifted(kg: 950.4, units: .kg, locale: english) == ("950", "kg"))
            #expect(ProfileFormat.lifted(kg: 1_234, units: .kg, locale: english) == ("1.2", "t"))
            #expect(ProfileFormat.lifted(kg: 12_345, units: .kg, locale: english) == ("12", "t"))
            #expect(ProfileFormat.lifted(kg: 1_000, units: .lb, locale: english) == ("2.2", "k lb"))
        }

        @Test func trainedSwitchesToDaysAfterTwoDays() {
            #expect(ProfileFormat.trained(seconds: 47 * 3_600 + 3_599) == ("47", L10n.unitHours))
            #expect(ProfileFormat.trained(seconds: 48 * 3_600) == ("2", L10n.unitDays))
        }

        @Test func weightUsesTheChosenUnit() {
            #expect(ProfileFormat.weight(kg: 78.5, units: .kg, locale: english) == "78.5 kg")
            #expect(ProfileFormat.weight(kg: 100, units: .lb, locale: english) == "220.5 lb")
        }
    }
}

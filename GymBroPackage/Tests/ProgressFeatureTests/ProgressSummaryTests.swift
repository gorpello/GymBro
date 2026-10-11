import CustomDump
import Dependencies
import Foundation
import ProgressFeature
import SQLiteData
import Testing

@testable import Database

extension ProgressFeatureSuite {
    @Suite struct ProgressSummaryTests {
        @Dependency(\.defaultDatabase) var database

        @Test func emptyDatabase() throws {
            let summary = try database.read { db in try request.fetch(db) }
            expectNoDifference(summary, ProgressSummary())
        }

        @Test func volumeComparesTheLast30DaysWithThe30Before() throws {
            let summary = try seededSummary()

            #expect(summary.volume30Kg == 1_715)
            #expect(summary.volumeChangePercent == 243)
            expectNoDifference(summary.volumeTrendKg, Array(repeating: 0, count: 11) + [1_715])
        }

        @Test func weightIsTheLatestEntryWithItsHistory() throws {
            let summary = try seededSummary()

            #expect(summary.weight?.value == 81.4)
            #expect(summary.weight?.date == date(2026, 10, 6))
            #expect(summary.weightTrendKg == [80, 81.4])
        }

        @Test func consistencyAndTotals() throws {
            let summary = try seededSummary()

            #expect(summary.activity.last == [4, 3, 4, 0, 0, 0, 0])
            #expect(summary.streak == 3)
            #expect(summary.daysDoneThisWeek == 3)
            #expect(summary.weeklyGoal == 4)
            #expect(summary.setsThisWeek == [2, 0, 2, 0, 0, 0, 0])
            #expect(summary.totals.workoutCount == 3)
            #expect(summary.totals.setCount == 5)
        }

        @Test func muscleHeatAndRecovery() throws {
            let summary = try seededSummary()

            // Chest: 3 sets in 7 days against 12. Secondary muscles count half a set.
            expectNoDifference(summary.muscleHeat7, [.chest: 2, .triceps: 1, .shoulders: 1, .back: 1])
            expectNoDifference(summary.muscleHeat30, [.chest: 1, .triceps: 1, .shoulders: 1, .back: 1])
            expectNoDifference(summary.fatigueLevels, [.chest: 1, .triceps: 1, .shoulders: 1, .back: 1])
            #expect(summary.recoveryPercent == 90)
        }

        @Test func strengthFollowsExercisesTrainedTwiceOrMore() throws {
            let summary = try seededSummary()

            expectNoDifference(
                summary.strength,
                [
                    StrengthRow(
                        id: bench,
                        name: "Barbell Bench Press",
                        bestOneRepMaxKg: 116.7,
                        curveKg: [116.7, 116.7, 115.5]
                    )
                ]
            )
        }

        @Test func recordsStrongestFirst() throws {
            let summary = try seededSummary()

            expectNoDifference(
                summary.records,
                [
                    RecordRow(
                        name: "Barbell Bench Press",
                        record: PersonalRecord(
                            exerciseID: bench,
                            kind: .weight,
                            best: 105,
                            oneRepMaxKg: 100 * (1 + 5.0 / 30),
                            date: date(2026, 9, 1)
                        )
                    ),
                    RecordRow(
                        name: "Barbell Seated Overhead Press",
                        record: PersonalRecord(
                            exerciseID: press,
                            kind: .weight,
                            best: 50,
                            oneRepMaxKg: 50 * (1 + 8.0 / 30),
                            date: date(2026, 10, 7)
                        )
                    ),
                ]
            )
        }

        @Test func latestMeasuresAndPhotos() throws {
            let summary = try seededSummary()

            expectNoDifference(
                summary.measures,
                [
                    BodyMeasurement(id: UUID(-4), date: date(2026, 10, 1), kind: .waist, value: 82),
                    BodyMeasurement(id: UUID(-5), date: date(2026, 10, 1), kind: .bodyFat, value: 14),
                ]
            )
            #expect(summary.photoCount == 2)
        }

        @Test func unitsAndGoalComeFromSettingsAndProfile() throws {
            try database.write { db in
                try db.seed {
                    AppSettings(id: AppSettings.singletonID, units: .lb)
                    UserProfile(id: UserProfile.singletonID, weeklyGoal: 5)
                }
            }
            let summary = try database.read { db in try request.fetch(db) }

            #expect(summary.units == .lb)
            #expect(summary.weeklyGoal == 5)
        }

        private func seededSummary() throws -> ProgressSummary {
            try database.write(seedTraining)
            return try database.read { db in try request.fetch(db) }
        }
    }
}

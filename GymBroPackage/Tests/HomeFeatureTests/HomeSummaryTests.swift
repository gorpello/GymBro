import CustomDump
import Dependencies
import Foundation
import HomeFeature
import SQLiteData
import Testing

@testable import Database

extension HomeFeatureSuite {
    @Suite struct HomeSummaryTests {
        @Dependency(\.defaultDatabase) var database

        @Test func emptyDatabaseShowsNothing() throws {
            let summary = try database.read { db in try request.fetch(db) }
            var expected = HomeSummary()
            expected.todayWeekdayIndex = 2
            expectNoDifference(summary, expected)
        }

        @Test func summarisesFinishedWorkoutsAndCheckIns() throws {
            try database.write(seedTrainingWeek)
            let summary = try database.read { db in try request.fetch(db) }
            var expected = HomeSummary()
            expected.activity[10] = [0, 4, 0, 0, 0, 0, 0]
            expected.activity[11] = [4, 4, 4, 0, 0, 0, 0]
            expected.daysDoneThisWeek = 3
            expected.prCount = 1
            expected.routineCount = 1
            expected.setsToday = 1
            expected.streak = 3
            expected.todayExerciseCount = 2
            expected.todayRoutineName = "Push"
            expected.todayWeekdayIndex = 2
            expected.volumeThisWeekKg = 800
            expected.weekDone = [true, true, true, false, false, false, false]
            expectNoDifference(summary, expected)
        }

        @Test func secondWorkoutTodayMovesToTheNextPlannedRoutine() throws {
            try database.write { db in
                try seedTrainingWeek(db)
                try db.seed {
                    Routine(id: UUID(-2), name: "Pull", position: 1)
                    RoutineSchedule(id: UUID(-2), routineID: UUID(-2), weekday: 3)
                }
            }
            let summary = try database.read { db in try request.fetch(db) }
            #expect(summary.todayRoutineName == "Pull")
            #expect(summary.todayExerciseCount == 0)
            #expect(summary.routineCount == 2)
        }

        @Test func unscheduledDaysDontBreakTheStreak() throws {
            try database.write { db in
                try seedTrainingWeek(db)
                try db.seed {
                    CheckIn(id: UUID(-2), day: date(2026, 9, 30, hour: 0))
                }
            }
            let summary = try database.read { db in try request.fetch(db) }
            #expect(summary.streak == 5)

            try database.write { db in
                try RoutineSchedule.delete().execute(db)
            }
            let unscheduled = try database.read { db in try request.fetch(db) }
            #expect(unscheduled.streak == 3)
        }

        @Test func matchingAnOldBestIsNotARecord() throws {
            try database.write { db in
                try seedTrainingWeek(db)
                try WorkoutSet.find(UUID(-1)).update { $0.weightKg = 100 }.execute(db)
            }
            let summary = try database.read { db in try request.fetch(db) }
            #expect(summary.prCount == 0)
        }

        @Test func weeklyGoalComesFromTheProfile() throws {
            try database.write { db in
                try db.seed {
                    UserProfile(id: UserProfile.singletonID, weeklyGoal: 5)
                    Note(id: UUID(-1), text: "Deload next week")
                }
            }
            let summary = try database.read { db in try request.fetch(db) }
            #expect(summary.weeklyGoal == 5)
            #expect(summary.noteCount == 1)
        }
    }
}

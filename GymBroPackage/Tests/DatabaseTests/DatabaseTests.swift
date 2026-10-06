import Dependencies
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import Database

@Suite(
    .dependencies {
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct CatalogTests {
    @Dependency(\.defaultDatabase) var database

    @Test func bootstrapSeedsTheBundledCatalog() throws {
        let count = try database.read { db in try Exercise.all.fetchCount(db) }
        #expect(count == 448)
        let bench = try database.read { db in try Exercise.find("EIeI8Vf").fetchOne(db) }
        #expect(bench?.name == "Barbell Bench Press")
        #expect(bench?.primaryMuscle == .chest)
        #expect(bench?.equipment == .barbell)
    }

    @Test func seedingAgainAddsNothing() throws {
        try database.write { db in try Exercise.seedCatalog(db) }
        let count = try database.read { db in try Exercise.all.fetchCount(db) }
        #expect(count == 448)
    }

    @Test func seedingKeepsArchivedFlags() throws {
        try database.write { db in
            try Exercise.find("EIeI8Vf").update { $0.isArchived = true }.execute(db)
            try Exercise.seedCatalog(db)
        }
        let bench = try database.read { db in try Exercise.find("EIeI8Vf").fetchOne(db) }
        #expect(bench?.isArchived == true)
    }

    @Test func seedingRestoresEditedCatalogFields() throws {
        try database.write { db in
            try Exercise.find("EIeI8Vf").update { $0.name = "Renamed" }.execute(db)
            try Exercise.seedCatalog(db)
        }
        let bench = try database.read { db in try Exercise.find("EIeI8Vf").fetchOne(db) }
        #expect(bench?.name == "Barbell Bench Press")
    }

    @Test func seedingLeavesCustomExercisesAlone() throws {
        try database.write { db in
            try db.seed {
                Exercise(id: "custom-1", name: "Sled Push", primaryMuscle: .quads, isCustom: true)
            }
            try Exercise.seedCatalog(db)
        }
        let custom = try database.read { db in try Exercise.find("custom-1").fetchOne(db) }
        #expect(custom?.name == "Sled Push")
        let count = try database.read { db in try Exercise.all.fetchCount(db) }
        #expect(count == 449)
    }
}

@Suite(
    .dependencies {
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
        try $0.defaultDatabase.write { db in
            try db.seed {
                Workout(id: UUID(-1), startedAt: Date(timeIntervalSince1970: 1_800_000_000))
                WorkoutExercise(id: UUID(-1), workoutID: UUID(-1), exerciseID: "EIeI8Vf")
                WorkoutSet(id: UUID(-1), workoutExerciseID: UUID(-1), reps: 8, weightKg: 80)
                WorkoutSet(id: UUID(-2), workoutExerciseID: UUID(-1), position: 1, reps: 8, weightKg: 80)
            }
        }
    }
)
struct ForeignKeyTests {
    @Dependency(\.defaultDatabase) var database

    @Test func deletingAWorkoutDeletesItsExercisesAndSets() throws {
        try database.write { db in try Workout.find(UUID(-1)).delete().execute(db) }
        let exercises = try database.read { db in try WorkoutExercise.all.fetchCount(db) }
        let sets = try database.read { db in try WorkoutSet.all.fetchCount(db) }
        #expect(exercises == 0)
        #expect(sets == 0)
    }

    @Test func anExerciseWithHistoryCannotBeDeleted() throws {
        #expect(throws: (any Error).self) {
            try database.write { db in try Exercise.find("EIeI8Vf").delete().execute(db) }
        }
    }

    @Test func primaryKeysComeFromTheUUIDDependency() throws {
        let id = try database.write { db in
            try Routine.insert { Routine.Draft(name: "Legs") }.returning(\.id).fetchOne(db)
        }
        #expect(id == UUID(0))
    }
}

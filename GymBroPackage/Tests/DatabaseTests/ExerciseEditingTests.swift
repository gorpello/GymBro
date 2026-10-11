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
struct ExerciseEditingTests {
    @Dependency(\.defaultDatabase) var database

    @Test func stepsDropBlankLinesAndListMarkers() {
        let text = """
            1. Brace
              2) Pull the bar to your hips

            - Lower slowly
            • Repeat
            * Breathe out at the top
            10 reps is plenty
            """
        #expect(
            Exercise.steps(from: text) == [
                "Brace", "Pull the bar to your hips", "Lower slowly", "Repeat", "Breathe out at the top",
                "10 reps is plenty",
            ]
        )
    }

    @Test func secondaryMusclesSkipThePrimaryAndFollowMapOrder() {
        #expect(Exercise.secondaryMuscles([.calves, .chest, .biceps], primary: .chest) == [.biceps, .calves])
    }

    @Test func preferencesStartFromTheDefaults() throws {
        try database.write { db in
            try ExercisePreference.edit(db, exerciseID: "EIeI8Vf") { $0.isFavorite = true }
            try ExercisePreference.edit(db, exerciseID: "EIeI8Vf") { $0.restSeconds = 120 }
        }
        let preference = try database.read { db in try ExercisePreference.find("EIeI8Vf").fetchOne(db) }
        #expect(preference?.isFavorite == true)
        #expect(preference?.restSeconds == 120)
        #expect(preference?.isSuggested == true)
    }

    @Test func savingClearsTheModeOverride() throws {
        try database.write { db in
            try Exercise.saveCustom(db, Exercise.custom(id: "custom-plank"))
            try ExercisePreference.edit(db, exerciseID: "custom-plank") { $0.modeOverride = .time }
            var plank = Exercise.custom(id: "custom-plank")
            plank.name = "Plank"
            try Exercise.saveCustom(db, plank)
        }
        let saved = try database.read { db in
            (try Exercise.find("custom-plank").fetchOne(db), try ExercisePreference.find("custom-plank").fetchOne(db))
        }
        #expect(saved.0?.name == "Plank")
        #expect(saved.0?.isCustom == true)
        #expect(saved.1?.modeOverride == nil)
    }

    @Test func catalogueExercisesAreNeverDeleted() throws {
        let isDeleted = try database.write { db in try Exercise.deleteCustom(db, id: "EIeI8Vf") }
        #expect(!isDeleted)
        let exercise = try database.read { db in try Exercise.find("EIeI8Vf").fetchOne(db) }
        #expect(exercise?.isArchived == false)
    }

    @Test func deletingTakesPreferencesAndRoutineSlotsWithIt() throws {
        try database.write { db in
            try Exercise.saveCustom(db, Exercise.custom(id: "custom-sled"))
            try ExercisePreference.edit(db, exerciseID: "custom-sled") { $0.isFavorite = true }
            try db.seed {
                Routine(id: UUID(-1), name: "Legs")
                RoutineExercise(id: UUID(-1), routineID: UUID(-1), exerciseID: "custom-sled")
            }
        }
        let isDeleted = try database.write { db in try Exercise.deleteCustom(db, id: "custom-sled") }

        #expect(isDeleted)
        #expect(try database.read { db in try ExercisePreference.all.fetchCount(db) } == 0)
        #expect(try database.read { db in try RoutineExercise.all.fetchCount(db) } == 0)
    }
}

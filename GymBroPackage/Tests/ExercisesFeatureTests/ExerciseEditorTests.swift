import ComposableArchitecture
import ExercisesFeature
import Foundation
import SQLiteData
import Testing

@testable import Database

extension ExercisesFeatureSuite {
    @MainActor
    @Suite struct ExerciseEditorTests {
        @Dependency(\.defaultDatabase) var database

        @Test func savingANewExercise() async throws {
            var state = ExerciseEditor.State(name: "  Rope Pull ")
            state.primary = .back
            state.secondary = [.biceps, .forearm]
            state.equipment = .cable
            state.difficulty = .intermediate
            state.howTo = "1. Grab the rope\n\n- Walk back  "
            let isDismissed = LockIsolated(false)
            let store = TestStore(initialState: state) {
                ExerciseEditor()
            } withDependencies: {
                $0.dismiss = DismissEffect { isDismissed.setValue(true) }
            }

            await store.send(.saveButtonTapped).finish()

            let id = "custom-00000000-0000-0000-0000-000000000000"
            let saved = try await database.read { db in try Exercise.find(id).fetchOne(db) }
            #expect(
                saved
                    == Exercise(
                        id: id,
                        name: "Rope Pull",
                        primaryMuscle: .back,
                        secondaryMuscles: [.biceps, .forearm],
                        equipment: .cable,
                        difficulty: .intermediate,
                        steps: ["Grab the rope", "Walk back"],
                        isCustom: true
                    )
            )
            #expect(isDismissed.value)
        }

        @Test func aBlankNameIsNotSaved() async throws {
            let store = TestStore(initialState: ExerciseEditor.State(name: "   ")) { ExerciseEditor() }

            await store.send(.saveButtonTapped)
            #expect(try await database.read { db in try Exercise.where(\.isCustom).fetchCount(db) } == 0)
        }

        @Test func theMainMuscleIsNeverAlsoSecondary() async {
            var state = ExerciseEditor.State()
            state.secondary = [.triceps, .shoulders]
            let store = TestStore(initialState: state) { ExerciseEditor() }

            await store.send(.binding(.set(\.primary, .triceps))) {
                $0.primary = .triceps
                $0.secondary = [.shoulders]
            }
            await store.send(.secondaryMuscleTapped(.triceps))
            await store.send(.secondaryMuscleTapped(.biceps)) {
                $0.secondary = [.shoulders, .biceps]
            }
        }

        @Test func editingKeepsTheExerciseArchived() async throws {
            try await database.write { db in
                try seedBench(db)
                try Exercise.find("custom-sled").update { $0.isArchived = true }.execute(db)
            }
            let sled = try #require(try await database.read { db in try Exercise.find("custom-sled").fetchOne(db) })
            var state = ExerciseEditor.State(exercise: sled)
            state.name = "Heavy Sled Push"
            let store = TestStore(initialState: state) {
                ExerciseEditor()
            } withDependencies: {
                $0.dismiss = DismissEffect {}
            }

            await store.send(.saveButtonTapped).finish()

            let saved = try await database.read { db in try Exercise.find("custom-sled").fetchOne(db) }
            #expect(saved?.name == "Heavy Sled Push")
            #expect(saved?.isArchived == true)
            #expect(saved?.secondaryMuscles == [.glutes])
        }
    }
}

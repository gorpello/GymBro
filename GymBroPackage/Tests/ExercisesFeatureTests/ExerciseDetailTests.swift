import ComposableArchitecture
import CustomDump
import Foundation
import SQLiteData
import Testing

@testable import Database
@testable import ExercisesFeature

extension ExercisesFeatureSuite {
    @Suite struct ExerciseOverviewTests {
        @Dependency(\.defaultDatabase) var database

        @Test func readsTheExerciseWithItsHistory() throws {
            try database.write(seedBench)
            let overview = try database.read { db in try ExerciseOverview.Request(exerciseID: bench).fetch(db) }

            #expect(overview.exercise?.name == "Barbell Bench Press")
            #expect(overview.preference?.isFavorite == true)
            expectNoDifference(
                overview.history,
                [
                    HistoryEntry(id: UUID(-3), date: date(2026, 10, 7), setCount: 1, topWeightKg: 105, volumeKg: 315),
                    HistoryEntry(id: UUID(-2), date: date(2026, 10, 5), setCount: 2, topWeightKg: 100, volumeKg: 1_000),
                    HistoryEntry(id: UUID(-1), date: date(2026, 9, 1), setCount: 1, topWeightKg: 100, volumeKg: 500),
                ]
            )
            // The best estimated one-rep max is still the first five at 100 kg.
            #expect(overview.record?.best == 105)
            #expect(overview.record?.date == date(2026, 9, 1))
            #expect(overview.nextTarget == Progression.Target(weightKg: 107.5, reps: 3, isIncrease: true))
            #expect(overview.noteCount == 1)
            #expect(overview.similar.count == ExerciseOverview.similarLimit)
            #expect(!overview.similar.map(\.id).contains(bench))
        }

        @Test func aDeletedExerciseReadsAsEmpty() throws {
            let overview = try database.read { db in try ExerciseOverview.Request(exerciseID: "gone").fetch(db) }
            expectNoDifference(overview, ExerciseOverview())
        }
    }

    @MainActor
    @Suite struct ExerciseDetailTests {
        @Dependency(\.defaultDatabase) var database

        @Test func settingsAreSavedRightAway() async throws {
            let store = TestStore(initialState: ExerciseDetail.State(id: bench)) { ExerciseDetail() }

            await store.send(.autoWarmupToggled(true)).finish()
            await store.send(.suggestInWorkoutsToggled(false)).finish()
            await store.send(.autoProgressToggled(true)).finish()
            // Up one step from the default rest of 90 seconds.
            await store.send(.restIncrementButtonTapped).finish()

            let preference = try await database.read { db in try ExercisePreference.find(bench).fetchOne(db) }
            #expect(preference?.autoWarmup == true)
            #expect(preference?.isSuggested == false)
            #expect(preference?.progressStepKg == 2.5)
            #expect(preference?.restSeconds == 105)
        }

        @Test func restStaysInRange() async throws {
            try await database.write { db in
                try db.seed { ExercisePreference(exerciseID: bench, restSeconds: 0) }
            }
            let store = try await loadedStore(bench)

            await store.send(.restDecrementButtonTapped).finish()
            #expect(try await database.read { db in try ExercisePreference.find(bench).fetchOne(db)?.restSeconds } == 0)
        }

        @Test func archivingTogglesBackAndForth() async throws {
            let store = TestStore(initialState: ExerciseDetail.State(id: bench)) { ExerciseDetail() }

            await store.send(.archiveButtonTapped).finish()
            #expect(try await isArchived(bench))
            await store.send(.archiveButtonTapped).finish()
            #expect(try await !isArchived(bench))
        }

        @Test func deletingAnUnusedCustomExerciseClosesIt() async throws {
            try await database.write(seedBench)
            let isDismissed = LockIsolated(false)
            let store = try await loadedStore("custom-sled") {
                $0.dismiss = DismissEffect { isDismissed.setValue(true) }
            }

            await store.send(.deleteButtonTapped) {
                $0.alert = .deleteExercise(name: "Sled Push")
            }
            await store.send(\.alert.confirmDeleteButtonTapped) {
                $0.alert = nil
            }
            await store.finish()

            #expect(try await database.read { db in try Exercise.find("custom-sled").fetchCount(db) } == 0)
            #expect(isDismissed.value)
        }

        @Test func deletingALoggedCustomExerciseArchivesIt() async throws {
            try await database.write { db in
                try seedBench(db)
                try db.seed {
                    Workout(id: UUID(-9), startedAt: date(2026, 10, 6), finishedAt: date(2026, 10, 6, hour: 11))
                    WorkoutExercise(id: UUID(-9), workoutID: UUID(-9), exerciseID: "custom-sled")
                }
            }
            let store = try await loadedStore("custom-sled")

            await store.send(.deleteButtonTapped) {
                $0.alert = .deleteExercise(name: "Sled Push")
            }
            await store.send(\.alert.confirmDeleteButtonTapped) {
                $0.alert = nil
            }
            await store.finish()

            #expect(try await isArchived("custom-sled"))
        }

        @Test func onlyCustomExercisesCanBeEdited() async throws {
            try await database.write(seedBench)
            let catalogue = try await loadedStore(bench)
            await catalogue.send(.editButtonTapped)

            let custom = try await loadedStore("custom-sled")
            let sled = try #require(custom.state.overview.exercise)
            await custom.send(.editButtonTapped) {
                $0.editor = ExerciseEditor.State(exercise: sled)
            }
        }

        @Test func similarAndNotesNavigate() async {
            let store = TestStore(initialState: ExerciseDetail.State(id: bench)) { ExerciseDetail() }

            await store.send(.similarTapped(id: "SpYC0Kp"))
            await store.receive(\.delegate.navigate, .exerciseDetail(id: "SpYC0Kp"))
            await store.send(.notesButtonTapped)
            await store.receive(\.delegate.navigate, .notes)
        }

        /// A store with the exercise's overview already read.
        private func loadedStore(
            _ id: Exercise.ID,
            _ prepare: @escaping (inout DependencyValues) -> Void = { _ in }
        ) async throws -> TestStoreOf<ExerciseDetail> {
            let state = ExerciseDetail.State(id: id)
            try await state.$overview.load(ExerciseOverview.Request(exerciseID: id))
            return TestStore(initialState: state, reducer: { ExerciseDetail() }, withDependencies: prepare)
        }

        private func isArchived(_ id: Exercise.ID) async throws -> Bool {
            try await database.read { db in try Exercise.find(id).select(\.isArchived).fetchOne(db) ?? false }
        }
    }
}

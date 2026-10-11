import ComposableArchitecture
import Foundation
import SQLiteData
import Testing

@testable import Database
@testable import RoutinesFeature

extension RoutinesFeatureSuite {
    @Suite struct RoutineLibraryTests {
        @Dependency(\.defaultDatabase) var database

        @Test func searchIgnoresCaseAndAccentsAndSkipsArchived() throws {
            try database.write { db in
                try db.seed {
                    Exercise(id: "custom-press", name: "Presse Écrasée", isCustom: true)
                    Exercise(id: "custom-old", name: "Old Press", isCustom: true, isArchived: true)
                }
            }
            let rows = try database.read { db in try RoutineLibraryRow.Request(search: " ecrasee ").fetch(db) }
            #expect(rows.map(\.id) == ["custom-press"])

            let all = try database.read { db in try RoutineLibraryRow.Request(search: "").fetch(db) }
            #expect(!all.map(\.id).contains("custom-old"))
            #expect(all.map(\.name) == all.map(\.name).sorted())
        }
    }

    @MainActor
    @Suite struct RoutineEditTests {
        @Dependency(\.defaultDatabase) var database

        @Test func savingANewRoutine() async throws {
            var state = RoutineEdit.State(id: nil)
            state.draft.name = "Shoulders"
            try await state.$library.load(RoutineLibraryRow.Request(search: "seated overhead"))
            let isDismissed = LockIsolated(false)
            let store = TestStore(initialState: state) {
                RoutineEdit()
            } withDependencies: {
                $0.dismiss = DismissEffect { isDismissed.setValue(true) }
            }

            await store.send(.addExerciseTapped(id: press)) {
                $0.draft.exercises = [
                    RoutineDraft.Item(
                        id: press,
                        art: "barbell-seated-overhead-press",
                        name: "Barbell Seated Overhead Press",
                        setCount: 3
                    )
                ]
            }
            // Already in the routine.
            await store.send(.addExerciseTapped(id: press))
            await store.send(.weekdayTapped(2)) {
                $0.draft.weekdays = [2]
            }
            await store.send(.saveButtonTapped) {
                $0.routineID = UUID(0)
            }
            await store.finish()

            let saved = try await database.read { db in try RoutineDraft.fetch(db, id: UUID(0)) }
            #expect(saved == store.state.draft)
            #expect(isDismissed.value)
        }

        @Test func editingStartsFromTheSavedRoutine() async throws {
            try await database.write(seedRoutines)
            let expected = try #require(try await database.read { db in try RoutineDraft.fetch(db, id: push) })
            let store = TestStore(initialState: RoutineEdit.State(id: push)) { RoutineEdit() }

            let task = await store.send(.task)
            await store.receive(\.draftLoaded) {
                $0.draft = expected
                $0.isLoading = false
            }
            await task.cancel()

            #expect(store.state.draft.name == "Push")
            #expect(store.state.draft.weekdays == [1, 5])
            #expect(store.state.draft.exercises.map(\.setCount) == [1, 4])
        }

        @Test func editingTheExerciseList() async {
            var state = RoutineEdit.State(id: nil)
            state.draft.exercises = [
                RoutineDraft.Item(id: bench, art: "", name: "Bench", setCount: 3),
                RoutineDraft.Item(id: press, art: "", name: "Press", setCount: 3),
            ]
            let store = TestStore(initialState: state) { RoutineEdit() }

            await store.send(.setsChanged(id: bench, delta: -5)) {
                $0.draft.exercises[0].setCount = 1
            }
            await store.send(.setsChanged(id: bench, delta: 20)) {
                $0.draft.exercises[0].setCount = 12
            }
            await store.send(.supersetToggled(id: bench)) {
                $0.draft.exercises[0].isChainedToNext = true
            }
            await store.send(.moveExercises(from: [1], to: 0)) {
                $0.draft.exercises.swapAt(0, 1)
            }
            await store.send(.removeExerciseTapped(id: press)) {
                $0.draft.exercises.removeFirst()
            }
        }

        @Test func startingSavesFirstThenOpensTheSession() async throws {
            try await database.write(seedRoutines)
            let draft = try #require(try await database.read { db in try RoutineDraft.fetch(db, id: push) })
            var state = RoutineEdit.State(id: push)
            state.draft = draft
            state.draft.name = "Push day"
            state.isLoading = false
            let store = TestStore(initialState: state) { RoutineEdit() }

            await store.send(.startButtonTapped)
            await store.receive(\.delegate.navigate, .session)

            #expect(try await database.read { db in try Routine.find(push).fetchOne(db)?.name } == "Push day")
            #expect(try await database.read { db in try LiveWorkout.fetch(db)?.routineID } == push)
        }

        @Test func anEmptyRoutineCannotBeStarted() async throws {
            let store = TestStore(initialState: RoutineEdit.State(id: nil)) { RoutineEdit() }

            await store.send(.startButtonTapped)
            #expect(try await database.read { db in try Routine.all.fetchCount(db) } == 0)
        }
    }
}

import ComposableArchitecture
import CustomDump
import Foundation
import L10n
import SQLiteData
import Testing

@testable import Database
@testable import RoutinesFeature

extension RoutinesFeatureSuite {
    @Suite struct RoutineListingTests {
        @Dependency(\.defaultDatabase) var database

        @Test func emptyDatabase() throws {
            let listing = try database.read { db in try RoutineListing.Request().fetch(db) }
            expectNoDifference(listing, RoutineListing())
        }

        @Test func groupsKeepListOrderAndThePlanFollowsTheSchedule() throws {
            try database.write(seedRoutines)
            let listing = try database.read { db in try RoutineListing.Request().fetch(db) }

            expectNoDifference(
                listing.groups,
                [
                    RoutineGroup(
                        id: "PPL",
                        routines: [
                            RoutineCard(id: push, exerciseCount: 2, group: "PPL", hue: 0, name: "Push"),
                            RoutineCard(id: pull, exerciseCount: 0, group: "PPL", hue: 4, name: "Pull"),
                        ]
                    ),
                    RoutineGroup(
                        id: "",
                        routines: [RoutineCard(id: legs, exerciseCount: 0, group: "", hue: 1, name: "")]
                    ),
                ]
            )
            expectNoDifference(listing.weeklyPlan, [["Push"], [], ["Pull"], [], ["Push", "Pull"], [], []])
        }
    }

    @MainActor
    @Suite struct RoutinesTests {
        @Dependency(\.defaultDatabase) var database

        @Test func duplicatingAddsACopyAtTheEnd() async throws {
            try await database.write(seedRoutines)
            let store = try await loadedStore()

            await store.send(.duplicateButtonTapped(id: push)).finish()

            let names = try await database.read { db in try Routine.order(by: \.position).select(\.name).fetchAll(db) }
            #expect(names == ["Push", "", "Pull", L10n.copySuffix("Push")])
        }

        @Test func deletingAsksFirst() async throws {
            try await database.write(seedRoutines)
            let store = try await loadedStore()

            await store.send(.deleteButtonTapped(id: legs)) {
                $0.alert = .deleteRoutine(id: legs, title: L10n.newRoutineName)
            }
            await store.send(\.alert.confirmDeleteButtonTapped, legs) {
                $0.alert = nil
            }
            await store.finish()

            #expect(try await database.read { db in try Routine.find(legs).fetchCount(db) } == 0)
            #expect(try await database.read { db in try Routine.all.fetchCount(db) } == 2)
        }

        @Test func cancellingTheDeleteKeepsTheRoutine() async throws {
            try await database.write(seedRoutines)
            let store = try await loadedStore()

            await store.send(.deleteButtonTapped(id: push)) {
                $0.alert = .deleteRoutine(id: push, title: "Push")
            }
            await store.send(.alert(.dismiss)) {
                $0.alert = nil
            }

            #expect(try await database.read { db in try Routine.all.fetchCount(db) } == 3)
        }

        @Test func startingARoutineOpensTheSession() async throws {
            try await database.write(seedRoutines)
            let store = TestStore(initialState: Routines.State()) { Routines() }

            await store.send(.startButtonTapped(id: push))
            await store.receive(\.delegate.navigate, .session)

            let workout = try await database.read { db in try LiveWorkout.fetch(db) }
            #expect(workout?.routineID == push)
            let exerciseIDs = try await database.read { db in
                try WorkoutExercise.order(by: \.position).select(\.exerciseID).fetchAll(db)
            }
            #expect(exerciseIDs == [bench, press])
        }

        @Test func navigation() async {
            let store = TestStore(initialState: Routines.State()) { Routines() }

            await store.send(.newRoutineButtonTapped)
            await store.receive(\.delegate.navigate, .routineEdit(id: nil))
            await store.send(.routineTapped(id: pull))
            await store.receive(\.delegate.navigate, .routineEdit(id: pull))
            await store.send(.importButtonTapped)
            await store.receive(\.delegate.navigate, .planImport)
            await store.send(.aiRoutineButtonTapped)
            await store.receive(\.delegate.navigate, .aiPlan)
        }

        /// A store with the listing already read.
        private func loadedStore() async throws -> TestStoreOf<Routines> {
            let state = Routines.State()
            try await state.$listing.load(RoutineListing.Request())
            return TestStore(initialState: state) { Routines() }
        }
    }
}

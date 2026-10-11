import ComposableArchitecture
import Foundation
import SQLiteData
import Testing
import TrainFeature

@testable import Database

extension SessionFeatureSuite {
    @Suite struct StartOptionsTests {
        @Dependency(\.defaultDatabase) var database
        let request = StartOptions.Request(today: now, calendar: calendar)

        @Test func todaysRoutineComesFirst() throws {
            try database.write(seedRoutinesAndHistory)
            let options = try database.read { db in try request.fetch(db) }

            #expect(options.today?.name == "Push")
            #expect(options.today?.exerciseCount == 2)
            #expect(options.routines.map(\.name) == ["Pull"])
            #expect(options.routines.first?.exerciseCount == 0)
            #expect(!options.hasWorkoutInProgress)
        }

        @Test func aWorkoutInProgressCanBeResumed() throws {
            try database.write(startPush)
            let options = try database.read { db in try request.fetch(db) }
            #expect(options.hasWorkoutInProgress)
        }
    }

    @MainActor
    @Suite struct StartWorkoutTests {
        @Dependency(\.defaultDatabase) var database

        @Test func tappingARoutineStartsItAndOpensTheSession() async throws {
            try await database.write(seedRoutinesAndHistory)
            let store = TestStore(initialState: StartWorkout.State()) { StartWorkout() }

            await store.send(.routineTapped(id: UUID(-2)))
            await store.receive(\.delegate.navigate, .session)

            let workout = try await database.read { db in try LiveWorkout.fetch(db) }
            #expect(workout?.routineID == UUID(-2))
        }

        @Test func resumingOpensTheSession() async {
            let store = TestStore(initialState: StartWorkout.State()) { StartWorkout() }

            await store.send(.resumeButtonTapped)
            await store.receive(\.delegate.navigate, .session)
        }

        @Test func trainStartsWithThePickedExercisesInListOrder() async throws {
            var state = Train.State()
            state.options = try await database.read { db in try TrainOptions.fetch(db, focus: .muscles([.chest])) }
            // The press isn't a chest exercise, so it was picked from search and goes after the focus.
            state.picked = [press, bench]
            let store = TestStore(initialState: state) { Train() }

            await store.send(.startButtonTapped)
            await store.receive(\.delegate.navigate, .session)

            let exerciseIDs = try await database.read { db in
                try WorkoutExercise.order(by: \.position).select(\.exerciseID).fetchAll(db)
            }
            #expect(exerciseIDs == [bench, press])
        }
    }
}

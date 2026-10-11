import ComposableArchitecture
import Foundation
import SQLiteData
import Testing

@testable import Database
@testable import SessionFeature

extension SessionFeatureSuite {
    @Suite struct LiveSessionTests {
        @Dependency(\.defaultDatabase) var database

        @Test func nothingInProgress() throws {
            let session = try database.read { db in try LiveSession.Request().fetch(db) }
            #expect(session.workout == nil)
            #expect(session.exercises.isEmpty)
        }

        @Test func readsTheWorkoutWithHistoryAndTargets() throws {
            try database.write(startPush)
            let session = try database.read { db in try LiveSession.Request().fetch(db) }

            #expect(session.exercises.map(\.exerciseID) == [bench, press])
            let benchEntry = session.exercises[0]
            #expect(benchEntry.sets.map(\.weightKg) == [90, 90, 90])
            #expect(benchEntry.lastSets.map(\.reps) == [8, 8])
            #expect(benchEntry.nextTarget == .init(weightKg: 92.5, reps: 8, isIncrease: true))
            #expect(benchEntry.restSeconds == 90)
            #expect(session.exercises[1].lastSets.isEmpty)
            #expect(session.exercises[1].nextTarget == nil)
            #expect(session.setsDone == 0)
            #expect(session.setsTotal == 5)
        }
    }

    @MainActor
    @Suite struct SessionTests {
        @Dependency(\.defaultDatabase) var database

        @Test func taskFollowsTheDatabase() async throws {
            try await database.write(startPush)
            let store = TestStore(initialState: Session.State()) { Session() }

            let task = await store.send(.task) {
                $0.now = now
            }
            try await waitUntil { store.state.session.exercises.count == 2 }

            try await database.write { db in
                let entryID = try #require(try WorkoutExercise.order(by: \.position).select(\.id).fetchOne(db))
                try LiveWorkout.addSet(db, to: entryID)
            }
            try await waitUntil { store.state.session.setsTotal == 6 }
            await task.cancel()
        }

        @Test func tickingASetSavesItAndStartsTheRest() async throws {
            let store = try await loadedStore()
            let set = try #require(store.state.current?.sets.first)

            await store.send(.setDoneButtonTapped(setID: set.id)) {
                $0.now = now
                $0.restTotalSeconds = 90
            }
            .finish()

            let saved = try await database.read { db in
                (try WorkoutSet.find(set.id).fetchOne(db), try LiveWorkout.fetch(db))
            }
            #expect(saved.0?.isCompleted == true)
            #expect(saved.1?.restEndsAt == now.addingTimeInterval(90))
        }

        @Test func untickingDoesNotRestartTheRest() async throws {
            try await database.write { db in
                try startPush(db)
                // History's sets are all completed, so this is one of today's.
                let set = try #require(try WorkoutSet.where { !$0.isCompleted }.fetchOne(db))
                try LiveWorkout.toggleSet(db, id: set.id)
            }
            let store = try await loadedStore()
            let set = try #require(store.state.session.exercises.flatMap(\.sets).first(where: \.isCompleted))

            await store.send(.setDoneButtonTapped(setID: set.id)).finish()
            #expect(try await database.read { db in try LiveWorkout.fetch(db)?.restEndsAt } == nil)
        }

        @Test func weightStepsInTheUsersUnit() async throws {
            try await database.write { db in
                try db.seed { AppSettings(id: AppSettings.singletonID, units: .lb) }
            }
            let store = try await loadedStore()
            let set = try #require(store.state.current?.sets.first)
            #expect(store.state.weightStep == 5)

            await store.send(.weightChanged(setID: set.id, delta: 5)).finish()
            let weightKg = try await database.read { db in try WorkoutSet.find(set.id).fetchOne(db)?.weightKg }
            #expect(weightKg == 90 + 5 * 0.45359237)
        }

        @Test func pausingStopsTheClock() async throws {
            let store = try await loadedStore()

            await store.send(.pauseButtonTapped) {
                $0.now = now
            }
            .finish()
            let workout = try await database.read { db in try LiveWorkout.fetch(db) }
            #expect(workout?.isPaused == true)
        }

        @Test func movingThroughTheExercises() async throws {
            let store = try await loadedStore()

            await store.send(.nextExerciseButtonTapped).finish()
            #expect(try await database.read { db in try LiveWorkout.fetch(db)?.currentPosition } == 1)

            await store.send(.binding(.set(\.showsOverview, true))) {
                $0.showsOverview = true
            }
            await store.send(.exerciseSelected(index: 0)) {
                $0.showsOverview = false
            }
            .finish()
            #expect(try await database.read { db in try LiveWorkout.fetch(db)?.currentPosition } == 0)
        }

        @Test func finishingShowsTheSummary() async throws {
            let store = try await loadedStore()
            let set = try #require(store.state.current?.sets.first)
            try await database.write { db in try LiveWorkout.toggleSet(db, id: set.id) }

            await store.send(.finishButtonTapped)
            await store.receive(\.workoutFinished) {
                $0.finished = FinishedWorkout(
                    durationSeconds: 0,
                    setCount: 1,
                    volumeKg: 720,
                    recordCount: 0,
                    previousVolumeKg: 1_440,
                    newAwards: [.firstWorkout, .firstRoutine, .firstRecord]
                )
            }
        }

        @Test func finishingWithNothingTickedClosesTheSession() async throws {
            let isDismissed = LockIsolated(false)
            let store = try await loadedStore {
                $0.dismiss = DismissEffect { isDismissed.setValue(true) }
            }

            await store.send(.finishButtonTapped)
            await store.receive(\.workoutFinished)
            #expect(isDismissed.value)
            #expect(try await database.read { db in try Workout.all.fetchCount(db) } == 1)
        }

        /// A store showing Push, started from the routine, with its session read.
        private func loadedStore(
            _ prepare: @escaping (inout DependencyValues) -> Void = { _ in }
        ) async throws -> TestStoreOf<Session> {
            let isStarted = try await database.read { db in try LiveWorkout.fetch(db) != nil }
            if !isStarted {
                try await database.write(startPush)
            }
            let state = Session.State()
            try await state.$session.load(LiveSession.Request())
            return TestStore(initialState: state, reducer: { Session() }, withDependencies: prepare)
        }
    }

    @Suite struct SessionFormatTests {
        let english = Locale(identifier: "en_US")

        @Test func clock() {
            #expect(SessionFormat.clock(0) == "0:00")
            #expect(SessionFormat.clock(245) == "4:05")
            #expect(SessionFormat.clock(3_729) == "1:02:09")
        }

        @Test func lastTimeAndNextTarget() {
            let sets = [
                WorkoutSet(id: UUID(1), workoutExerciseID: UUID(0), reps: 8, weightKg: 92.5),
                WorkoutSet(id: UUID(2), workoutExerciseID: UUID(0), reps: 12, weightKg: 0),
            ]
            #expect(SessionFormat.sets(sets, units: .kg, locale: english) == "92.5×8 · 12")
            #expect(SessionFormat.sets([], units: .kg) == nil)
            #expect(
                SessionFormat.target(.init(weightKg: 100, reps: 5, isIncrease: true), units: .lb, locale: english)
                    == "220.5 lb × 5"
            )
        }

        @Test func volumeAndChange() {
            #expect(SessionFormat.volume(8_400, units: .kg, locale: english) == ("8.4", "t"))
            #expect(SessionFormat.change(from: 1_000, to: 1_120) == "+12%")
            #expect(SessionFormat.change(from: 1_000, to: 950) == "−5%")
            #expect(SessionFormat.change(from: nil, to: 950) == nil)
        }
    }
}

/// Database observations deliver on their own schedule; polls until `condition` holds.
@MainActor
func waitUntil(
    timeout: Duration = .seconds(2),
    sourceLocation: SourceLocation = #_sourceLocation,
    _ condition: () -> Bool
) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while !condition() {
        guard clock.now < deadline else {
            Issue.record("Condition not met within \(timeout)", sourceLocation: sourceLocation)
            return
        }
        try await clock.sleep(for: .milliseconds(10))
    }
}

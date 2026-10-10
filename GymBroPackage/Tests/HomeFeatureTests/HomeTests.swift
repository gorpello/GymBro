import ComposableArchitecture
import Foundation
import HomeFeature
import SQLiteData
import Testing

@testable import Database

extension HomeFeatureSuite {
    @MainActor
    @Suite struct HomeTests {
        @Dependency(\.defaultDatabase) var database

        @Test func shortcutsNavigate() async {
            let store = TestStore(initialState: Home.State()) { Home() }

            await store.send(.activityButtonTapped)
            await store.receive(\.delegate.navigate, .timeline)
            await store.send(.journalButtonTapped)
            await store.receive(\.delegate.navigate, .notes)
            await store.send(.routinesButtonTapped)
            await store.receive(\.delegate.navigate, .routines)
            await store.send(.toolsButtonTapped)
            await store.receive(\.delegate.navigate, .tools)
        }

        @Test func startWorkoutWithNothingPlannedOpensTrain() async {
            let store = TestStore(initialState: Home.State()) { Home() }

            await store.send(.startWorkoutButtonTapped)
            await store.receive(\.delegate.navigate, .train)
        }

        @Test func startWorkoutWithARoutinePlannedOpensStart() async throws {
            try await database.write(seedTrainingWeek)
            let state = Home.State()
            try await state.$summary.load(request)
            let store = TestStore(initialState: state) { Home() }

            await store.send(.startWorkoutButtonTapped)
            await store.receive(\.delegate.navigate, .start)
        }

        @Test func taskLoadsTodaysSummaryAndFollowsTheDatabase() async throws {
            try await database.write(seedTrainingWeek)
            let store = TestStore(initialState: Home.State()) { Home() }

            let task = await store.send(.task) {
                $0.today = date(2026, 10, 7, hour: 0)
            }
            try await waitUntil { store.state.summary.todayRoutineName == "Push" }
            #expect(store.state.summary.noteCount == 0)

            try await database.write { db in
                try db.seed {
                    Note(id: UUID(-1), text: "Deload next week")
                }
            }
            try await waitUntil { store.state.summary.noteCount == 1 }

            await task.cancel()
        }
    }
}

/// Database observations deliver on their own schedule; polls until `condition` holds.
@MainActor
private func waitUntil(
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

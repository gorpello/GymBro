import ComposableArchitecture
import Foundation
import ProgressFeature
import SQLiteData
import Testing

@testable import Database

extension ProgressFeatureSuite {
    @MainActor
    @Suite struct ProgressOverviewTests {
        @Dependency(\.defaultDatabase) var database

        @Test func shortcutsNavigate() async {
            let store = TestStore(initialState: ProgressOverview.State()) { ProgressOverview() }

            await store.send(.compareButtonTapped)
            await store.receive(\.delegate.navigate, .compare)
            await store.send(.exerciseTapped(id: bench))
            await store.receive(\.delegate.navigate, .exerciseDetail(id: bench))
            await store.send(.measuresButtonTapped)
            await store.receive(\.delegate.navigate, .measures)
            await store.send(.shareButtonTapped)
            await store.receive(\.delegate.navigate, .share)
            await store.send(.timelineButtonTapped)
            await store.receive(\.delegate.navigate, .timeline)
        }

        @Test func pickingAMuscleRange() async {
            let store = TestStore(initialState: ProgressOverview.State()) { ProgressOverview() }

            await store.send(.binding(.set(\.muscleRange, .recovery))) {
                $0.muscleRange = .recovery
            }
        }

        @Test func taskFollowsTheDatabase() async throws {
            let store = TestStore(initialState: ProgressOverview.State()) { ProgressOverview() }

            let task = await store.send(.task)
            try await database.write(seedTraining)
            try await waitUntil { store.state.summary.totals.workoutCount == 3 }

            try await database.write { db in
                try db.seed {
                    BodyMeasurement(id: UUID(-9), date: now, kind: .bodyweight, value: 81)
                }
            }
            try await waitUntil { store.state.summary.weight?.value == 81 }
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

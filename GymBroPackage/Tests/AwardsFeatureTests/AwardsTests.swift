import AwardsFeature
import ComposableArchitecture
import Foundation
import SQLiteData
import Testing

@testable import Database

extension AwardsFeatureSuite {
    @Suite struct AwardsBoardTests {
        @Dependency(\.defaultDatabase) var database

        @Test func emptyDatabaseLocksEverything() throws {
            let board = try database.read { db in try request.fetch(db) }
            #expect(board.earned.isEmpty)
            #expect(board.locked.map(\.kind) == AwardKind.allCases)
            #expect(board.medals.allSatisfy { $0.progress == 0 })
        }

        @Test func earnedMedalsCarryTheirDateAndLockedOnesTheirProgress() throws {
            try database.write { db in
                try seedFirstSession(db)
                try Award.refresh(db, now: now, calendar: calendar)
            }
            let board = try database.read { db in try request.fetch(db) }

            #expect(board.earned.map(\.kind) == [.firstStep, .firstWorkout, .firstRecord])
            #expect(board.earned.allSatisfy { $0.earnedAt == now })
            #expect(board.earned.allSatisfy { $0.progress == $0.kind.goal })

            let locked = Dictionary(uniqueKeysWithValues: board.locked.map { ($0.kind, $0.progress) })
            #expect(locked[.firstRoutine] == 0)
            #expect(locked[.streak3] == 1)
            #expect(locked[.workouts10] == 1)
            #expect(locked[.sets100] == 1)
            #expect(locked[.tonne1] == 500)
            #expect(locked[.hours10] == 0)
        }
    }

    @MainActor
    @Suite struct AwardsTests {
        @Dependency(\.defaultDatabase) var database

        @Test func taskAwardsDeservedMedalsAndMarksThemSeen() async throws {
            try await database.write(seedFirstSession)
            let store = TestStore(initialState: Awards.State()) { Awards() }

            let task = await store.send(.task)
            try await waitUntil { store.state.board.earned.count == 3 }

            let unseen = try await database.read { db in try Award.where { !$0.isSeen }.fetchCount(db) }
            #expect(unseen == 0)
            await task.cancel()
        }

        @Test func progressFollowsTheDatabase() async throws {
            let store = TestStore(initialState: Awards.State()) { Awards() }

            let task = await store.send(.task)

            // A check-in starts a streak without earning anything, so only progress can change.
            try await database.write { db in
                try db.seed { CheckIn(id: UUID(-1), day: calendar.startOfDay(for: now)) }
            }
            try await waitUntil {
                store.state.board.locked.first { $0.kind == .streak3 }?.progress == 1
            }
            #expect(store.state.board.earned.isEmpty)
            await task.cancel()
        }

        @Test func tappingAMedalDoesNothingYet() async {
            let store = TestStore(initialState: Awards.State()) { Awards() }
            await store.send(.medalTapped(.firstWorkout))
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

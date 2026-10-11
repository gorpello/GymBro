import ComposableArchitecture
import DesignSystem
import Foundation
import SQLiteData
import SessionFeature
import SnapshotTesting
import SwiftUI
import Testing

@testable import Database

extension SessionFeatureSuite {
    /// Snapshots live in `__Snapshots__`. A missing one is recorded on the first run, which fails
    /// once; run again to compare. Record on the same simulator (iOS 27, English) every time.
    @MainActor
    @Suite struct SessionViewSnapshotTests {
        @Dependency(\.defaultDatabase) var database

        init() {
            GymFont.register()
        }

        /// Push under way: first set ticked, 75 seconds of rest left, 12 minutes in.
        @Test func resting() async throws {
            try await database.write(startPush)
            var state = Session.State()
            try await state.$session.load(LiveSession.Request())
            let set = try #require(state.current?.sets.first)
            let workoutID = try #require(state.session.workout?.id)
            try await database.write { db in
                try LiveWorkout.toggleSet(db, id: set.id)
                try LiveWorkout.startRest(db, workoutID: workoutID, seconds: 90, now: now.addingTimeInterval(705))
            }
            try await state.$session.load(LiveSession.Request())
            state.now = now.addingTimeInterval(720)
            state.restTotalSeconds = 90
            assertSnapshot(
                of: SessionView(store: Store(initialState: state) { Session() }),
                as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro))
            )
        }

        @Test func summary() {
            var state = Session.State()
            state.finished = FinishedWorkout(
                durationSeconds: 3_480,
                setCount: 18,
                volumeKg: 8_400,
                recordCount: 2,
                previousVolumeKg: 7_500,
                newAwards: []
            )
            assertSnapshot(
                of: SessionView(store: Store(initialState: state) { Session() }),
                as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro))
            )
        }
    }
}

import AwardsFeature
import ComposableArchitecture
import DesignSystem
import SQLiteData
import SnapshotTesting
import SwiftUI
import Testing

@testable import Database

extension AwardsFeatureSuite {
    /// Snapshots live in `__Snapshots__`. A missing one is recorded on the first run, which fails
    /// once; run again to compare. Record on the same simulator (iOS 27, English) every time.
    @MainActor
    @Suite struct AwardsViewSnapshotTests {
        @Dependency(\.defaultDatabase) var database

        init() {
            GymFont.register()
        }

        @Test func nothingEarned() async throws {
            let view = try await awardsView()
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro)))
        }

        @Test func firstSession() async throws {
            try await database.write { db in
                try seedFirstSession(db)
                try Award.refresh(db, now: now, calendar: calendar)
            }
            let view = try await awardsView()
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro)))
        }

        /// Awards as it looks once `.task` has read the board.
        private func awardsView() async throws -> some View {
            var state = Awards.State()
            try await state.$board.load(request)
            return NavigationStack {
                AwardsView(store: Store(initialState: state) { Awards() })
            }
        }
    }
}

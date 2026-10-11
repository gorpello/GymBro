import ComposableArchitecture
import DesignSystem
import ProgressFeature
import SQLiteData
import SnapshotTesting
import SwiftUI
import Testing

@testable import Database

extension ProgressFeatureSuite {
    /// Snapshots live in `__Snapshots__`. A missing one is recorded on the first run, which fails
    /// once; run again to compare. Record on the same simulator (iOS 27, English) every time.
    @MainActor
    @Suite struct ProgressOverviewViewSnapshotTests {
        @Dependency(\.defaultDatabase) var database

        init() {
            GymFont.register()
        }

        @Test func firstLaunch() async throws {
            let view = try await progressView()
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro)))
        }

        @Test func trained() async throws {
            try await database.write(seedTraining)
            let view = try await progressView()
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro)))
        }

        /// Progress as it looks once `.task` has read the summary.
        private func progressView() async throws -> ProgressOverviewView {
            let state = ProgressOverview.State()
            try await state.$summary.load(request)
            return ProgressOverviewView(store: Store(initialState: state) { ProgressOverview() })
        }
    }
}

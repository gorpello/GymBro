import ComposableArchitecture
import DesignSystem
import HomeFeature
import SnapshotTesting
import SQLiteData
import SwiftUI
import Testing

extension HomeFeatureSuite {
    /// Snapshots live in `__Snapshots__`. A missing one is recorded on the first run, which fails
    /// once; run again to compare. Record on the same simulator (iOS 27, English) every time.
    @MainActor
    @Suite struct HomeViewSnapshotTests {
        @Dependency(\.defaultDatabase) var database

        init() {
            GymFont.register()
        }

        @Test func firstLaunch() async throws {
            let view = try await homeView()
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro)))
        }

        @Test func trainingWeek() async throws {
            try await database.write(seedTrainingWeek)
            let view = try await homeView()
            assertSnapshot(
                of: view,
                as: .image(
                    perceptualPrecision: 0.98,
                    layout: .device(config: .iPhone13Pro),
                    traits: UITraitCollection(userInterfaceStyle: .light)
                ),
                named: "light"
            )
            assertSnapshot(
                of: view,
                as: .image(
                    perceptualPrecision: 0.98,
                    layout: .device(config: .iPhone13Pro),
                    traits: UITraitCollection(userInterfaceStyle: .dark)
                ),
                named: "dark"
            )
        }

        @Test func trainingWeekLargeText() async throws {
            try await database.write(seedTrainingWeek)
            let view = try await homeView()
            assertSnapshot(
                of: view,
                as: .image(
                    perceptualPrecision: 0.98,
                    layout: .device(config: .iPhone13Pro),
                    traits: UITraitCollection(preferredContentSizeCategory: .accessibilityLarge)
                )
            )
        }

        /// Home as it looks once `.task` has run: today set and the summary read.
        private func homeView() async throws -> HomeView {
            var state = Home.State()
            state.today = date(2026, 10, 7, hour: 0)
            try await state.$summary.load(request)
            return HomeView(store: Store(initialState: state) { Home() })
        }
    }
}

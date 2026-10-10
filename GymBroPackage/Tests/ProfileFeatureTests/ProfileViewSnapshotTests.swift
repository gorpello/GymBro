import ComposableArchitecture
import DesignSystem
import ProfileFeature
import SQLiteData
import SnapshotTesting
import SwiftUI
import Testing

@testable import Database

extension ProfileFeatureSuite {
    /// Snapshots live in `__Snapshots__`. A missing one is recorded on the first run, which fails
    /// once; run again to compare. Record on the same simulator (iOS 27, English) every time.
    @MainActor
    @Suite struct ProfileViewSnapshotTests {
        @Dependency(\.defaultDatabase) var database

        init() {
            GymFont.register()
        }

        @Test func firstLaunch() async throws {
            let view = try await profileView()
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro)))
        }

        @Test func trainedProfile() async throws {
            try await database.write(seedAlex)
            let view = try await profileView()
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro)))
        }

        @Test func editSheet() {
            let view = ProfileEditView(
                store: Store(initialState: ProfileEdit.State(profile: alex, units: .lb)) {
                    ProfileEdit()
                }
            )
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro)))
        }

        /// Profile as it looks once `.task` has read the summary.
        private func profileView() async throws -> ProfileView {
            let state = Profile.State()
            try await state.$summary.load(request)
            return ProfileView(store: Store(initialState: state) { Profile() })
        }
    }
}

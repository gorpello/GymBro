import ComposableArchitecture
import DesignSystem
import RoutinesFeature
import SQLiteData
import SnapshotTesting
import SwiftUI
import Testing

@testable import Database

extension RoutinesFeatureSuite {
    /// Snapshots live in `__Snapshots__`. A missing one is recorded on the first run, which fails
    /// once; run again to compare. Record on the same simulator (iOS 27, English) every time.
    @MainActor
    @Suite struct RoutinesViewSnapshotTests {
        @Dependency(\.defaultDatabase) var database

        init() {
            GymFont.register()
        }

        @Test func routines() async throws {
            try await database.write(seedRoutines)
            let state = Routines.State()
            try await state.$listing.load(RoutineListing.Request())
            let view = NavigationStack {
                RoutinesView(store: Store(initialState: state) { Routines() })
            }
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro)))
        }

        @Test func edit() async throws {
            try await database.write(seedRoutines)
            var state = RoutineEdit.State(id: push)
            state.draft = try #require(try await database.read { db in try RoutineDraft.fetch(db, id: push) })
            state.isLoading = false
            state.searchText = "dip"
            try await state.$library.load(RoutineLibraryRow.Request(search: state.searchText))
            let view = NavigationStack {
                RoutineEditView(store: Store(initialState: state) { RoutineEdit() })
            }
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro)))
        }
    }
}

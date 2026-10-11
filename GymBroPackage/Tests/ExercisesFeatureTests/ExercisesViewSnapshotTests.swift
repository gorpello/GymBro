import ComposableArchitecture
import DesignSystem
import ExercisesFeature
import SQLiteData
import SnapshotTesting
import SwiftUI
import Testing

@testable import Database

extension ExercisesFeatureSuite {
    /// Snapshots live in `__Snapshots__`. A missing one is recorded on the first run, which fails
    /// once; run again to compare. Record on the same simulator (iOS 27, English) every time.
    @MainActor
    @Suite struct ExercisesViewSnapshotTests {
        @Dependency(\.defaultDatabase) var database

        init() {
            GymFont.register()
        }

        @Test func library() async throws {
            try await database.write(seedBench)
            let state = ExerciseLibrary.State()
            try await state.$listing.load(ExerciseListing.Request(filter: state.filter))
            let view = ExerciseLibraryView(store: Store(initialState: state) { ExerciseLibrary() })
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro)))
        }

        @Test func detail() async throws {
            try await database.write(seedBench)
            let state = ExerciseDetail.State(id: bench)
            try await state.$overview.load(ExerciseOverview.Request(exerciseID: bench))
            let view = NavigationStack {
                ExerciseDetailView(store: Store(initialState: state) { ExerciseDetail() })
            }
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro)))
        }

        @Test func editor() async throws {
            try await database.write(seedBench)
            let sled = try #require(try await database.read { db in try Exercise.find("custom-sled").fetchOne(db) })
            let view = NavigationStack {
                ExerciseEditorView(
                    store: Store(initialState: ExerciseEditor.State(exercise: sled)) { ExerciseEditor() })
            }
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhone13Pro)))
        }
    }
}

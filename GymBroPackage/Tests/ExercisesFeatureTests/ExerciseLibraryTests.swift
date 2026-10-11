import ComposableArchitecture
import ExercisesFeature
import Foundation
import SQLiteData
import Testing

@testable import Database

extension ExercisesFeatureSuite {
    @Suite struct ExerciseListingTests {
        @Dependency(\.defaultDatabase) var database

        @Test func everyActiveExerciseGroupedByMainMuscle() throws {
            try database.write(seedBench)
            let listing = try fetch(ExerciseFilter())

            #expect(listing.exerciseCount == 449)
            #expect(listing.favouriteCount == 1)
            #expect(!listing.hasArchived)
            #expect(listing.sections.first?.id == .chest)
            #expect(
                listing.sections.allSatisfy { section in section.rows.allSatisfy { $0.primaryMuscle == section.id } })
        }

        @Test func searchIgnoresCaseAndAccents() throws {
            var filter = ExerciseFilter()
            filter.search = "  BENCH préss "
            let names = try fetch(filter).sections.flatMap(\.rows).map(\.name)

            #expect(names.contains("Barbell Bench Press"))
            #expect(names.allSatisfy { $0.localizedStandardContains("bench press") })
        }

        @Test func chipsCombine() throws {
            try database.write(seedBench)
            var filter = ExerciseFilter()
            filter.favouritesOnly = true
            #expect(try fetch(filter).sections.flatMap(\.rows).map(\.id) == [bench])

            filter = ExerciseFilter()
            filter.customOnly = true
            #expect(try fetch(filter).sections.flatMap(\.rows).map(\.id) == ["custom-sled"])

            filter = ExerciseFilter()
            filter.noKitOnly = true
            #expect(try fetch(filter).sections.flatMap(\.rows).allSatisfy { $0.equipment == .bodyweight })
        }

        @Test func aPickedMuscleLeadsWithExercisesThatTrainItMost() throws {
            try database.write(seedBench)
            var filter = ExerciseFilter()
            filter.muscle = .glutes
            let sections = try fetch(filter).sections

            #expect(sections.first?.id == .glutes)
            // Sled push trains glutes second, so it stays under quads.
            #expect(sections.first { $0.id == .quads }?.rows.map(\.id).contains("custom-sled") == true)
        }

        @Test func archivedExercisesOnlyShowInTheArchive() throws {
            try database.write { db in
                try seedBench(db)
                try Exercise.find(bench).update { $0.isArchived = true }.execute(db)
            }
            let active = try fetch(ExerciseFilter())
            #expect(active.hasArchived)
            #expect(!active.sections.flatMap(\.rows).map(\.id).contains(bench))

            var filter = ExerciseFilter()
            filter.archivedOnly = true
            #expect(try fetch(filter).sections.flatMap(\.rows).map(\.id) == [bench])
            #expect(filter.sheetCount == 1)
        }

        private func fetch(_ filter: ExerciseFilter) throws -> ExerciseListing {
            try database.read { db in try ExerciseListing.Request(filter: filter).fetch(db) }
        }
    }

    @MainActor
    @Suite struct ExerciseLibraryTests {
        @Dependency(\.defaultDatabase) var database

        @Test func tappingAnExerciseOpensIt() async {
            let store = TestStore(initialState: ExerciseLibrary.State()) { ExerciseLibrary() }

            await store.send(.exerciseTapped(id: bench))
            await store.receive(\.delegate.navigate, .exerciseDetail(id: bench))
        }

        @Test func favouritingSavesThePreference() async throws {
            let store = TestStore(initialState: ExerciseLibrary.State()) { ExerciseLibrary() }

            await store.send(.favouriteButtonTapped(id: bench)).finish()
            #expect(try await isFavourite(bench))
            await store.send(.favouriteButtonTapped(id: bench)).finish()
            #expect(try await !isFavourite(bench))
        }

        @Test func changingTheFilterReloadsTheListing() async throws {
            try await database.write(seedBench)
            let store = TestStore(initialState: ExerciseLibrary.State()) { ExerciseLibrary() }

            await store.send(.task)
            try await waitUntil { store.state.listing.exerciseCount == 449 }

            await store.send(.binding(.set(\.filter.customOnly, true))) {
                $0.filter.customOnly = true
            }
            try await waitUntil { store.state.listing.exerciseCount == 1 }

            await store.send(.clearFiltersButtonTapped) {
                $0.filter.customOnly = false
            }
            try await waitUntil { store.state.listing.exerciseCount == 449 }
            // The listing keeps following the database until the screen goes away.
            await store.skipInFlightEffects()
        }

        @Test func addingStartsFromTheSearch() async {
            var state = ExerciseLibrary.State()
            state.filter.search = " Sled Pull "
            let store = TestStore(initialState: state) { ExerciseLibrary() }

            await store.send(.addButtonTapped) {
                $0.editor = ExerciseEditor.State(name: "Sled Pull")
            }
        }

        @Test func filtersOpenInASheet() async {
            let store = TestStore(initialState: ExerciseLibrary.State()) { ExerciseLibrary() }

            await store.send(.filtersButtonTapped) {
                $0.showsFilters = true
            }
        }

        private func isFavourite(_ id: Exercise.ID) async throws -> Bool {
            try await database.read { db in
                try ExercisePreference.find(id).select(\.isFavorite).fetchOne(db) ?? false
            }
        }
    }
}

/// Database observations deliver on their own schedule; polls until `condition` holds.
@MainActor
func waitUntil(
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

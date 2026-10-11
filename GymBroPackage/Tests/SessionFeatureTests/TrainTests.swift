import ComposableArchitecture
import Foundation
import SQLiteData
import Testing

@testable import Database
@testable import TrainFeature

extension SessionFeatureSuite {
    @Suite struct TrainOptionsTests {
        @Dependency(\.defaultDatabase) var database

        @Test func musclesOfferEveryExerciseThatTrainsThem() throws {
            let options = try database.read { db in try TrainOptions.fetch(db, focus: .muscles([.calves])) }
            let byID = Dictionary(uniqueKeysWithValues: options.exercises.map { ($0.id, $0) })
            let pool = options.pool.compactMap { byID[$0] }

            #expect(!pool.isEmpty)
            #expect(pool.allSatisfy { $0.primaryMuscle == .calves || $0.secondaryMuscles.contains(.calves) })
            #expect(options.defaultPicks.count == min(pool.count, TrainOptions.pickTarget))
        }

        @Test func archivedAndUnsuggestedExercisesAreLeftOut() throws {
            try database.write { db in
                try Exercise.find(bench).update { $0.isArchived = true }.execute(db)
                try ExercisePreference.edit(db, exerciseID: "SpYC0Kp") { $0.isSuggested = false }
            }
            let options = try database.read { db in try TrainOptions.fetch(db, focus: .muscles([.chest])) }

            #expect(!options.exercises.map(\.id).contains(bench))
            // Still offered, just never picked for you.
            #expect(options.pool.contains("SpYC0Kp"))
            #expect(!options.defaultPicks.contains("SpYC0Kp"))
        }

        @Test func warmUpFollowsItsListAndCardioPicksOneDoneBefore() throws {
            try database.write { db in
                try db.seed {
                    Workout(id: UUID(-1), startedAt: now, finishedAt: now)
                    WorkoutExercise(id: UUID(-1), workoutID: UUID(-1), exerciseID: "burpee")
                }
            }
            let warmup = try database.read { db in try TrainOptions.fetch(db, focus: .warmup) }
            #expect(warmup.pool == TrainOptions.warmupIDs)
            #expect(warmup.defaultPicks == Array(TrainOptions.warmupIDs.prefix(TrainOptions.pickTarget)))

            let cardio = try database.read { db in try TrainOptions.fetch(db, focus: .cardio) }
            #expect(Set(cardio.pool) == TrainOptions.cardioExtraIDs)
            #expect(cardio.defaultPicks == ["burpee"])
        }

        @Test func picksTakeTheBestForEachMuscleThenFavouritesThenHistory() {
            let pool = (1...8).map { exercise("e\($0)", $0 <= 4 ? .chest : .triceps) }
            let picks = TrainOptions.defaultPicks(
                from: pool,
                muscles: [.chest, .triceps],
                favourites: ["e3", "e8"],
                trained: ["e2", "e6"]
            )
            #expect(picks == ["e3", "e8", "e2", "e6", "e1", "e4"])
        }

        @Test func aSmallPoolIsPickedWhole() {
            let pool = [exercise("a", .chest), exercise("b", .chest)]
            let picks = TrainOptions.defaultPicks(from: pool, muscles: [.chest], favourites: [], trained: [])
            #expect(picks == ["a", "b"])
        }

        private func exercise(_ id: Exercise.ID, _ muscle: Muscle) -> TrainExercise {
            TrainExercise(Exercise(id: id, name: id, primaryMuscle: muscle))
        }
    }

    @MainActor
    @Suite struct TrainTests {
        @Dependency(\.defaultDatabase) var database

        @Test func continuingReadsTheFocusAndTicksTheSuggestedPicks() async throws {
            let expected = try await database.read { db in try TrainOptions.fetch(db, focus: .muscles([.chest])) }
            let store = TestStore(initialState: Train.State()) { Train() }

            await store.send(.muscleTapped("chest")) {
                $0.selectedMuscles = ["chest"]
            }
            await store.send(.continueButtonTapped) {
                $0.focus = .muscles([.chest])
                $0.step = .build
            }
            await store.receive(\.optionsLoaded, expected) {
                $0.options = expected
                $0.picked = Set(expected.defaultPicks)
            }
            #expect(store.state.suggestions.map(\.id) == store.state.options.defaultPicks)
            #expect(store.state.equipmentOptions.contains(.barbell))

            await store.send(.backButtonTapped) {
                $0.step = .focus
                $0.focus = nil
            }
        }

        @Test func filtersNarrowTheList() async throws {
            var state = Train.State()
            state.options.exercises = [
                TrainExercise(Exercise(id: "a", name: "Bench", primaryMuscle: .chest, equipment: .barbell)),
                TrainExercise(Exercise(id: "b", name: "Dip", primaryMuscle: .triceps, equipment: .bodyweight)),
                TrainExercise(Exercise(id: "c", name: "Fly", primaryMuscle: .chest, equipment: .cable)),
            ]
            state.options.pool = ["a", "b", "c"]
            state.options.defaultPicks = ["a"]

            #expect(state.suggestions.map(\.id) == ["a"])
            #expect(state.moreOptions.map(\.id) == ["b", "c"])
            #expect(state.equipmentOptions == [.barbell, .cable, .bodyweight])

            state.muscleFilter = "chest"
            state.equipmentFilter = .cable
            #expect(state.suggestions.isEmpty)
            #expect(state.moreOptions.map(\.id) == ["c"])

            state.searchText = " DIP "
            #expect(state.searchResults.map(\.id) == ["b"])
        }

        @Test func nothingPickedStartsNothing() async {
            let store = TestStore(initialState: Train.State()) { Train() }
            await store.send(.startButtonTapped)
        }
    }
}

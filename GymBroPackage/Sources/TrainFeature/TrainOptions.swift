import Database
import Foundation
import SQLiteData

/// What a quick workout can be built from: muscles picked on the body map, a warm-up or cardio.
public enum TrainFocus: Hashable, Sendable {
    case muscles([Muscle])
    case warmup
    case cardio
}

/// The exercises the Train builder offers, read once when the focus is chosen.
public struct TrainOptions: Equatable, Sendable {
    /// Every active exercise, by name, for search and for picks from outside the focus.
    public var exercises: [TrainExercise] = []
    /// Exercises that fit the focus, in list order.
    public var pool: [Exercise.ID] = []
    /// Picked to start with (`_defaultPicks` in GymMane), shown first as "Suggested picks".
    public var defaultPicks: [Exercise.ID] = []

    public init() {}

    /// How many exercises a focus starts with.
    static let pickTarget = 6

    /// Warm-up moves, in the order they're offered (`kWarmupIds`).
    static let warmupIDs: [Exercise.ID] = [
        "jumping-jack", "high-knees", "cat-cow-stretch", "worlds-greatest-stretch", "leg-swings-stretch", "inchworm",
        "QChZi3x", "scapular-push-up", "hip-airplane", "glute-bridge", "bird-dog", "dead-bug", "fire-hydrant",
        "clamshell", "kneeling-hip-flexor-stretch", "BbfB8Gb", "6YUfHPL", "jump-rope", "band-pull-apart",
        "yuris-shoulder-band-warmup", "wrist-prep",
    ]

    /// Conditioning moves that count as cardio besides exercises logged as cardio (`kCardioExtras`).
    static let cardioExtraIDs: Set<Exercise.ID> = [
        "jump-rope", "battle-ropes", "burpee", "half-burpee", "mountain-climber", "high-knees", "jumping-jack",
        "skater-hop", "squat-thrust", "sprawl", "lateral-shuffle", "plank-jack",
    ]

    public static func fetch(_ db: Database, focus: TrainFocus) throws -> TrainOptions {
        let exercises = try Exercise.where { !$0.isArchived }.order(by: \.name).fetchAll(db)
        let favourites = try Set(ExercisePreference.where(\.isFavorite).select(\.exerciseID).fetchAll(db))
        let unsuggested = try Set(ExercisePreference.where { !$0.isSuggested }.select(\.exerciseID).fetchAll(db))
        let trained = try Set(
            WorkoutExercise
                .join(Workout.all) { $0.workoutID.eq($1.id) }
                .where { _, workouts in workouts.finishedAt.isNot(nil) }
                .select { workoutExercises, _ in workoutExercises.exerciseID }
                .distinct()
                .fetchAll(db)
        )

        var options = TrainOptions()
        options.exercises = exercises.map(TrainExercise.init)
        let pool = Self.pool(of: options.exercises, for: focus)
        options.pool = pool.map(\.id)
        let suggested = pool.filter { !unsuggested.contains($0.id) }
        switch focus {
        case let .muscles(muscles):
            options.defaultPicks = defaultPicks(
                from: suggested,
                muscles: muscles,
                favourites: favourites,
                trained: trained
            )
        case .warmup:
            options.defaultPicks = suggested.prefix(pickTarget).map(\.id)
        case .cardio:
            options.defaultPicks = suggested.first { trained.contains($0.id) }.map { [$0.id] } ?? []
        }
        return options
    }

    /// Exercises that fit `focus`: training a picked muscle (as its main or a secondary one), the
    /// warm-up list, or cardio.
    static func pool(of exercises: [TrainExercise], for focus: TrainFocus) -> [TrainExercise] {
        switch focus {
        case let .muscles(muscles):
            let picked = Set(muscles)
            return exercises.filter {
                picked.contains($0.primaryMuscle) || !picked.isDisjoint(with: $0.secondaryMuscles)
            }
        case .warmup:
            let byID = Dictionary(exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            return warmupIDs.compactMap { byID[$0] }
        case .cardio:
            return exercises.filter { $0.mode == .cardio || cardioExtraIDs.contains($0.id) }
        }
    }

    /// Up to `pickTarget` exercises: the best one for each muscle first, then the best of the rest.
    /// Favourites rank first, then exercises trained before; ties keep list order. A small pool is
    /// picked whole.
    static func defaultPicks(
        from pool: [TrainExercise],
        muscles: [Muscle],
        favourites: Set<Exercise.ID>,
        trained: Set<Exercise.ID>
    ) -> [Exercise.ID] {
        guard pool.count > pickTarget else { return pool.map(\.id) }
        func rank(_ exercise: TrainExercise) -> Int {
            favourites.contains(exercise.id) ? 0 : trained.contains(exercise.id) ? 1 : 2
        }
        let ranked = pool.enumerated()
            .sorted { (rank($0.element), $0.offset) < (rank($1.element), $1.offset) }
            .map(\.element)

        var picks: [Exercise.ID] = []
        for muscle in muscles {
            if let best = ranked.first(where: { $0.primaryMuscle == muscle && !picks.contains($0.id) }) {
                picks.append(best.id)
            }
        }
        for exercise in ranked where picks.count < pickTarget && !picks.contains(exercise.id) {
            picks.append(exercise.id)
        }
        return picks
    }
}

/// An exercise in the Train builder.
public struct TrainExercise: Equatable, Identifiable, Sendable {
    public var id: Exercise.ID
    /// Illustration name under `Art/`; empty for custom exercises.
    public var art: String
    public var equipment: Equipment
    public var mode: ExerciseMode
    public var name: String
    public var primaryMuscle: Muscle
    public var secondaryMuscles: [Muscle]

    public init(_ exercise: Exercise) {
        self.id = exercise.id
        self.art = exercise.art
        self.equipment = exercise.equipment
        self.mode = exercise.mode
        self.name = exercise.name
        self.primaryMuscle = exercise.primaryMuscle
        self.secondaryMuscles = exercise.secondaryMuscles
    }
}

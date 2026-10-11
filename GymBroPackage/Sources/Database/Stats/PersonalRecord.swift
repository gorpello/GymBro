import Foundation
import SQLiteData

/// An exercise's all-time best, worked out from its completed working sets in finished workouts.
public struct PersonalRecord: Equatable, Sendable {
    public var exerciseID: Exercise.ID
    public var kind: Kind
    /// Heaviest weight (kg), longest distance (km), longest time (seconds) or most reps.
    public var best: Double
    /// Best estimated one-rep max of any set, in kilograms.
    public var oneRepMaxKg: Double
    /// When the best was first reached. Weight records compare estimated one-rep maxes, so a
    /// heavier single can lose to a stronger set of five; matching an earlier best doesn't count.
    public var date: Date

    /// What a record is measured in: the first kind any of the exercise's sets has a value for.
    public enum Kind: CaseIterable, Comparable, Sendable {
        case weight, distance, time, reps

        public func score(_ set: LoggedSet) -> Double {
            switch self {
            case .weight: set.weightKg
            case .distance: set.distanceKm ?? 0
            case .time: Double(set.durationSeconds ?? 0)
            case .reps: Double(set.reps)
            }
        }
    }

    @Selection
    public struct LoggedSet: Equatable, Sendable {
        public var exerciseID: Exercise.ID
        public var workoutID: Workout.ID
        public var startedAt: Date
        public var reps: Int
        public var weightKg: Double
        public var rpe: Double?
        public var durationSeconds: Int?
        public var distanceKm: Double?

        public var estimatedOneRepMaxKg: Double {
            WorkoutSet.estimatedOneRepMaxKg(weightKg: weightKg, reps: reps, rpe: rpe)
        }
    }
}

extension PersonalRecord {
    /// The record of one exercise; `nil` when no set scores above zero.
    ///
    /// - Parameter sets: The exercise's sets, oldest first.
    public init?(sets: [LoggedSet]) {
        guard let first = sets.first else { return nil }
        let kind = Kind.allCases.first { kind in sets.contains { kind.score($0) > 0 } } ?? .reps
        var bestScore = 0.0
        var date: Date?
        for set in sets {
            let score = kind == .weight ? set.estimatedOneRepMaxKg : kind.score(set)
            if score > bestScore {
                bestScore = score
                date = set.startedAt
            }
        }
        guard let date else { return nil }
        self.exerciseID = first.exerciseID
        self.kind = kind
        self.best = sets.map(kind.score).max() ?? 0
        self.oneRepMaxKg = sets.map(\.estimatedOneRepMaxKg).max() ?? 0
        self.date = date
    }

    /// One record per exercise: weight records first, strongest first, then the other kinds by
    /// their best.
    ///
    /// - Parameter sets: Sets of any number of exercises, oldest first.
    public static func records(from sets: [LoggedSet]) -> [Self] {
        Dictionary(grouping: sets, by: \.exerciseID).values
            .compactMap(Self.init(sets:))
            .sorted { lhs, rhs in
                if lhs.kind != rhs.kind { return lhs.kind < rhs.kind }
                let (left, right) = lhs.kind == .weight ? (lhs.oneRepMaxKg, rhs.oneRepMaxKg) : (lhs.best, rhs.best)
                return left != right ? left > right : lhs.exerciseID < rhs.exerciseID
            }
    }

    /// Every completed working set of finished workouts, oldest first.
    ///
    /// - Parameter exerciseIDs: Only these exercises; `nil` reads them all.
    public static func fetchSets(_ db: Database, exerciseIDs: [Exercise.ID]? = nil) throws -> [LoggedSet] {
        var query =
            WorkoutSet
            .where { $0.isCompleted && $0.kind.neq(SetKind.warmup) }
            .join(WorkoutExercise.all) { $0.workoutExerciseID.eq($1.id) }
            .join(Workout.all) { $1.workoutID.eq($2.id) }
            .where { _, _, workouts in workouts.finishedAt.isNot(nil) }
        if let exerciseIDs {
            query = query.where { _, workoutExercises, _ in workoutExercises.exerciseID.in(exerciseIDs) }
        }
        return
            try query
            .order { workoutSets, workoutExercises, workouts in
                (workouts.startedAt, workoutExercises.position, workoutSets.position)
            }
            .select { workoutSets, workoutExercises, workouts in
                LoggedSet.Columns(
                    exerciseID: workoutExercises.exerciseID,
                    workoutID: workouts.id,
                    startedAt: workouts.startedAt,
                    reps: workoutSets.reps,
                    weightKg: workoutSets.weightKg,
                    rpe: workoutSets.rpe,
                    durationSeconds: workoutSets.durationSeconds,
                    distanceKm: workoutSets.distanceKm
                )
            }
            .fetchAll(db)
    }
}

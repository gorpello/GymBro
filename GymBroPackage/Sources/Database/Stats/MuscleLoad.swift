import Foundation
import SQLiteData

/// How hard each muscle has been worked: sets over a window for the heat map, and fatigue that
/// fades over a few days for recovery. A set counts in full for its exercise's main muscle and
/// half for each secondary one.
public enum MuscleLoad {
    /// Working sets a week that fill a muscle's heat.
    public static let weeklySetTarget = 12.0
    /// Fatigue at which a muscle shows as fully tired.
    public static let fullFatigue = 8.0
    /// Sets older than this no longer add any fatigue worth counting.
    public static let fatigueWindowHours = 24.0 * 8

    /// A completed working set with the muscles its exercise trains.
    public struct TrainedSet: Equatable, Sendable {
        public var startedAt: Date
        public var finishedAt: Date
        public var primaryMuscle: Muscle
        public var secondaryMuscles: [Muscle]
        public var kind: SetKind
        public var rpe: Double?

        public init(
            startedAt: Date,
            finishedAt: Date,
            primaryMuscle: Muscle,
            secondaryMuscles: [Muscle] = [],
            kind: SetKind = .normal,
            rpe: Double? = nil
        ) {
            self.startedAt = startedAt
            self.finishedAt = finishedAt
            self.primaryMuscle = primaryMuscle
            self.secondaryMuscles = secondaryMuscles
            self.kind = kind
            self.rpe = rpe
        }

        /// How much the set tires: 1 for a normal set, 1.2 to failure, or scaled by its RPE.
        var effort: Double {
            guard let rpe else { return kind == .failure ? 1.2 : 1 }
            return min(max((rpe - 5) / 4, 0.4), 1.3)
        }
    }

    /// Completed working sets of finished workouts started on or after `start`.
    public static func fetchSets(_ db: Database, since start: Date) throws -> [TrainedSet] {
        let rows =
            try WorkoutSet
            .where { $0.isCompleted && $0.kind.neq(SetKind.warmup) }
            .join(WorkoutExercise.all) { $0.workoutExerciseID.eq($1.id) }
            .join(Workout.all) { $1.workoutID.eq($2.id) }
            .where { _, _, workouts in workouts.finishedAt.isNot(nil) && workouts.startedAt.gte(start) }
            .select { workoutSets, workoutExercises, workouts in
                SetRow.Columns(
                    exerciseID: workoutExercises.exerciseID,
                    startedAt: workouts.startedAt,
                    finishedAt: workouts.finishedAt,
                    kind: workoutSets.kind,
                    rpe: workoutSets.rpe
                )
            }
            .fetchAll(db)
        let exerciseIDs = Array(Set(rows.map(\.exerciseID)))
        let exercises = try Dictionary(
            uniqueKeysWithValues: Exercise.where { $0.id.in(exerciseIDs) }.fetchAll(db).map { ($0.id, $0) }
        )
        return rows.compactMap { row in
            guard let exercise = exercises[row.exerciseID] else { return nil }
            return TrainedSet(
                startedAt: row.startedAt,
                finishedAt: row.finishedAt ?? row.startedAt,
                primaryMuscle: exercise.primaryMuscle,
                secondaryMuscles: exercise.secondaryMuscles,
                kind: row.kind,
                rpe: row.rpe
            )
        }
    }

    /// Sets per muscle.
    public static func setCounts(_ sets: [TrainedSet]) -> [Muscle: Double] {
        var counts: [Muscle: Double] = [:]
        for set in sets {
            counts[set.primaryMuscle, default: 0] += 1
            for muscle in set.secondaryMuscles {
                counts[muscle, default: 0] += 0.5
            }
        }
        return counts
    }

    /// Heat 1…4 per muscle trained in `sets`, done over `days` days, against the weekly target.
    public static func heatLevels(_ sets: [TrainedSet], days: Int) -> [Muscle: Int] {
        let target = weeklySetTarget * Double(days) / 7
        return setCounts(sets).mapValues { HeatLevel.of(min($0 / target, 1)) }
    }

    /// Fatigue per muscle at `now`: each set's effort, fading with the muscle's recovery time.
    public static func fatigue(_ sets: [TrainedSet], at now: Date) -> [Muscle: Double] {
        var fatigue: [Muscle: Double] = [:]
        for set in sets {
            let hours = now.timeIntervalSince(set.finishedAt) / 3_600
            guard (0...fatigueWindowHours).contains(hours) else { continue }
            let add = { (muscle: Muscle, share: Double) in
                fatigue[muscle, default: 0] += set.effort * share * exp(-hours / decayHours(muscle))
            }
            add(set.primaryMuscle, 1)
            for muscle in set.secondaryMuscles {
                add(muscle, 0.5)
            }
        }
        return fatigue
    }

    /// From 1 (fresh) down to 0 (fully tired), for every muscle.
    public static func recovery(_ sets: [TrainedSet], at now: Date) -> [Muscle: Double] {
        let fatigue = fatigue(sets, at: now)
        return Dictionary(
            uniqueKeysWithValues: Muscle.all.map { muscle in
                (muscle, min(max(1 - (fatigue[muscle] ?? 0) / fullFatigue, 0), 1))
            }
        )
    }

    /// Average recovery of every muscle, in percent.
    public static func overallRecovery(_ recovery: [Muscle: Double]) -> Int {
        guard !recovery.isEmpty else { return 100 }
        return Int((recovery.values.reduce(0, +) / Double(recovery.count) * 100).rounded())
    }

    /// Big muscles take longer to recover. Fatigue falls to about 5% after the full time.
    static func decayHours(_ muscle: Muscle) -> Double {
        let recoveryHours: Double =
            switch muscle {
            case .quads, .hamstrings, .glutes: 72
            case .chest, .back: 60
            case .forearm, .calves, .abdomen, .obliques: 36
            default: 48
            }
        return recoveryHours / 3
    }
}

@Selection
private struct SetRow {
    let exerciseID: Exercise.ID
    let startedAt: Date
    let finishedAt: Date?
    let kind: SetKind
    let rpe: Double?
}

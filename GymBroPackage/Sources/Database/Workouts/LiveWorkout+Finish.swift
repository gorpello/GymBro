import Foundation
import SQLiteData

/// What a finished workout amounted to, for the "Session complete" screen.
public struct FinishedWorkout: Equatable, Sendable {
    public var durationSeconds: Int
    /// Working sets: completed, warm-ups left out.
    public var setCount: Int
    public var volumeKg: Double
    /// Exercises whose best estimated one-rep max beat every earlier workout.
    public var recordCount: Int
    /// Volume of the last workout that shared an exercise with this one; `nil` the first time.
    public var previousVolumeKg: Double?
    /// Medals this workout earned, easiest first.
    public var newAwards: [AwardKind]

    public init(
        durationSeconds: Int,
        setCount: Int,
        volumeKg: Double,
        recordCount: Int,
        previousVolumeKg: Double?,
        newAwards: [AwardKind]
    ) {
        self.durationSeconds = durationSeconds
        self.setCount = setCount
        self.volumeKg = volumeKg
        self.recordCount = recordCount
        self.previousVolumeKg = previousVolumeKg
        self.newAwards = newAwards
    }
}

extension LiveWorkout {
    /// Files the workout into history. Sets never ticked, and exercises left without sets, are
    /// dropped; a workout with nothing ticked is deleted instead and `nil` is returned.
    /// Medals are refreshed, since this is when most of them are earned.
    public static func finish(
        _ db: Database,
        workoutID: Workout.ID,
        now: Date,
        calendar: Calendar
    ) throws -> FinishedWorkout? {
        guard var workout = try Workout.find(workoutID).fetchOne(db), workout.isLive else { return nil }
        let workoutExerciseIDs = WorkoutExercise.where { $0.workoutID.eq(workoutID) }.select(\.id)

        try WorkoutSet
            .where { !$0.isCompleted && $0.workoutExerciseID.in(workoutExerciseIDs) }
            .delete()
            .execute(db)
        try WorkoutExercise
            .where { $0.workoutID.eq(workoutID) && !$0.id.in(WorkoutSet.select(\.workoutExerciseID)) }
            .delete()
            .execute(db)
        guard try WorkoutExercise.where({ $0.workoutID.eq(workoutID) }).fetchCount(db) > 0 else {
            try Workout.find(workoutID).delete().execute(db)
            return nil
        }

        workout.durationSeconds = workout.elapsedSeconds(at: now)
        workout.finishedAt = now
        workout.resumedAt = nil
        workout.restEndsAt = nil
        workout.restPausedRemaining = nil
        try Workout.upsert { Workout.Draft(workout) }.execute(db)

        let sets = try workingSets(db, inWorkout: workoutID)
        return FinishedWorkout(
            durationSeconds: workout.durationSeconds,
            setCount: sets.count,
            volumeKg: sets.reduce(0) { $0 + $1.volumeKg },
            recordCount: try recordCount(db, workoutID: workoutID, sets: sets),
            previousVolumeKg: try previousVolumeKg(db, before: workout),
            newAwards: try Award.refresh(db, now: now, calendar: calendar)
        )
    }

    /// Exercises whose best estimated one-rep max in this workout beats every earlier one. The
    /// first time an exercise is logged counts, as in GymMane.
    private static func recordCount(_ db: Database, workoutID: Workout.ID, sets: [HistorySet]) throws -> Int {
        let best = Dictionary(grouping: sets, by: \.exerciseID).mapValues(\.bestOneRepMaxKg)
        let earlier = try historySets(db) { workoutExercises, workouts in
            workouts.id.neq(workoutID) && workoutExercises.exerciseID.in(Array(best.keys))
        }
        let earlierBest = Dictionary(grouping: earlier, by: \.exerciseID).mapValues(\.bestOneRepMaxKg)
        return best.count { exerciseID, oneRepMaxKg in
            oneRepMaxKg > 0 && oneRepMaxKg > earlierBest[exerciseID, default: 0]
        }
    }

    /// Volume of the latest earlier workout that has any exercise in common with `workout`.
    private static func previousVolumeKg(_ db: Database, before workout: Workout) throws -> Double? {
        let exerciseIDs = WorkoutExercise.where { $0.workoutID.eq(workout.id) }.select(\.exerciseID)
        let previousID =
            try WorkoutExercise
            .where { $0.exerciseID.in(exerciseIDs) }
            .join(Workout.all) { $0.workoutID.eq($1.id) }
            .where { _, workouts in
                workouts.id.neq(workout.id) && workouts.finishedAt.isNot(nil)
                    && workouts.startedAt.lte(workout.startedAt)
            }
            .order { _, workouts in workouts.startedAt.desc() }
            .limit(1)
            .select { _, workouts in workouts.id }
            .fetchOne(db)
        guard let previousID else { return nil }
        return try workingSets(db, inWorkout: previousID).reduce(0) { $0 + $1.volumeKg }
    }

    private static func workingSets(_ db: Database, inWorkout workoutID: Workout.ID) throws -> [HistorySet] {
        try historySets(db) { _, workouts in workouts.id.eq(workoutID) }
    }

    /// Completed working sets of finished workouts matching `predicate`, with their exercise.
    private static func historySets(
        _ db: Database,
        where predicate: @escaping (WorkoutExercise.TableColumns, Workout.TableColumns) -> some QueryExpression<Bool>
    ) throws -> [HistorySet] {
        try WorkoutSet
            .where { $0.isCompleted && $0.kind.neq(SetKind.warmup) }
            .join(WorkoutExercise.all) { $0.workoutExerciseID.eq($1.id) }
            .join(Workout.all) { $1.workoutID.eq($2.id) }
            .where { _, workoutExercises, workouts in
                workouts.finishedAt.isNot(nil) && predicate(workoutExercises, workouts)
            }
            .select { workoutSets, workoutExercises, _ in
                HistorySet.Columns(
                    exerciseID: workoutExercises.exerciseID,
                    reps: workoutSets.reps,
                    weightKg: workoutSets.weightKg,
                    rpe: workoutSets.rpe
                )
            }
            .fetchAll(db)
    }
}

@Selection
struct HistorySet {
    let exerciseID: Exercise.ID
    let reps: Int
    let weightKg: Double
    let rpe: Double?

    var volumeKg: Double { Double(reps) * weightKg }
}

extension [HistorySet] {
    fileprivate var bestOneRepMaxKg: Double {
        map { WorkoutSet.estimatedOneRepMaxKg(weightKg: $0.weightKg, reps: $0.reps, rpe: $0.rpe) }.max() ?? 0
    }
}

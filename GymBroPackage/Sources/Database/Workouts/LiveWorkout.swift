import Dependencies
import Foundation
import SQLiteData

/// Everything that changes the workout in progress, the one `Workout` with no `finishedAt`.
/// Every change is written as it happens, so quitting the app mid-workout loses nothing.
///
/// All functions run inside the caller's write transaction.
public enum LiveWorkout {
    /// The workout in progress, if any.
    public static func fetch(_ db: Database) throws -> Workout? {
        try Workout.where { $0.finishedAt.is(nil) }.order { $0.startedAt.desc() }.fetchOne(db)
    }

    // MARK: - Starting

    /// Starts a workout with `exerciseIDs`, in order, each opening with its usual sets. Unknown
    /// exercise ids are skipped. If a workout is already in progress, it's returned instead, so
    /// "Start" always resumes rather than abandoning one.
    @discardableResult
    public static func start(_ db: Database, exerciseIDs: [Exercise.ID], now: Date) throws -> Workout.ID {
        let known = try Set(Exercise.where { $0.id.in(exerciseIDs) }.select(\.id).fetchAll(db))
        let plans = exerciseIDs.filter(known.contains).map { ExercisePlan(exerciseID: $0) }
        return try begin(db, routineID: nil, plans: plans, now: now)
    }

    /// Starts `routineID`: its exercises in order, with their planned sets filled in from history.
    @discardableResult
    public static func start(_ db: Database, routineID: Routine.ID, now: Date) throws -> Workout.ID {
        let routineExercises =
            try RoutineExercise
            .where { $0.routineID.eq(routineID) }
            .order(by: \.position)
            .fetchAll(db)
        let plans = try routineExercises.map { routineExercise in
            ExercisePlan(
                exerciseID: routineExercise.exerciseID,
                setCount: routineExercise.setCount,
                planned:
                    try PlannedSet
                    .where { $0.routineExerciseID.eq(routineExercise.id) }
                    .order(by: \.position)
                    .fetchAll(db),
                isChainedToNext: routineExercise.isChainedToNext
            )
        }
        return try begin(db, routineID: routineID, plans: plans, now: now)
    }

    private struct ExercisePlan {
        var exerciseID: Exercise.ID
        /// `nil` repeats last time's number of sets.
        var setCount: Int?
        var planned: [PlannedSet] = []
        var isChainedToNext = false
    }

    private static func begin(
        _ db: Database,
        routineID: Routine.ID?,
        plans: [ExercisePlan],
        now: Date
    ) throws -> Workout.ID {
        if let live = try fetch(db) { return live.id }
        @Dependency(\.uuid) var uuid

        let workout = Workout(id: uuid(), startedAt: now, routineID: routineID, resumedAt: now)
        try Workout.insert { workout }.execute(db)
        for (position, plan) in plans.enumerated() {
            let workoutExercise = WorkoutExercise(
                id: uuid(),
                workoutID: workout.id,
                exerciseID: plan.exerciseID,
                position: position,
                isChainedToNext: plan.isChainedToNext
            )
            try WorkoutExercise.insert { workoutExercise }.execute(db)
            let openings = Progression.openingSets(
                planned: plan.planned,
                setCount: plan.setCount,
                lastSets: try ExerciseHistory.lastWorkingSets(db, exerciseID: plan.exerciseID),
                progressStepKg: try ExercisePreference.find(plan.exerciseID).fetchOne(db)?.progressStepKg
            )
            for (setPosition, opening) in openings.enumerated() {
                try WorkoutSet.insert {
                    WorkoutSet(
                        id: uuid(),
                        workoutExerciseID: workoutExercise.id,
                        position: setPosition,
                        reps: opening.reps,
                        weightKg: opening.weightKg,
                        kind: opening.kind
                    )
                }
                .execute(db)
            }
        }
        return workout.id
    }

    // MARK: - Sets

    /// Ticks or unticks a set. Returns whether it's now completed.
    @discardableResult
    public static func toggleSet(_ db: Database, id: WorkoutSet.ID) throws -> Bool {
        guard var set = try WorkoutSet.find(id).fetchOne(db) else { return false }
        set.isCompleted.toggle()
        try WorkoutSet.upsert { WorkoutSet.Draft(set) }.execute(db)
        return set.isCompleted
    }

    /// Changes a set's reps and weight by the given amounts, never below zero.
    public static func adjustSet(_ db: Database, id: WorkoutSet.ID, reps: Int = 0, weightKg: Double = 0) throws {
        guard var set = try WorkoutSet.find(id).fetchOne(db) else { return }
        set.reps = max(0, set.reps + reps)
        set.weightKg = max(0, set.weightKg + weightKg)
        try WorkoutSet.upsert { WorkoutSet.Draft(set) }.execute(db)
    }

    /// Adds a set after the last one, copying it; an exercise with no sets gets 10 × 20 kg.
    public static func addSet(_ db: Database, to workoutExerciseID: WorkoutExercise.ID) throws {
        @Dependency(\.uuid) var uuid
        let last = try sets(db, of: workoutExerciseID).last
        try WorkoutSet.insert {
            WorkoutSet(
                id: uuid(),
                workoutExerciseID: workoutExerciseID,
                position: (last?.position ?? -1) + 1,
                reps: last?.reps ?? Progression.defaultReps,
                weightKg: last?.weightKg ?? Progression.defaultWeightKg,
                kind: last?.kind == .warmup ? .normal : last?.kind ?? .normal
            )
        }
        .execute(db)
    }

    /// Adds a warm-up before the first set: 10 reps at half the first working weight.
    public static func addWarmup(_ db: Database, to workoutExerciseID: WorkoutExercise.ID) throws {
        @Dependency(\.uuid) var uuid
        let existing = try sets(db, of: workoutExerciseID)
        let workingWeightKg = existing.first { $0.kind != .warmup }?.weightKg ?? Progression.defaultWeightKg
        try WorkoutSet.insert {
            WorkoutSet(
                id: uuid(),
                workoutExerciseID: workoutExerciseID,
                position: (existing.first?.position ?? 1) - 1,
                reps: Progression.defaultReps,
                weightKg: Progression.warmupWeightKg(for: workingWeightKg),
                kind: .warmup
            )
        }
        .execute(db)
    }

    private static func sets(_ db: Database, of workoutExerciseID: WorkoutExercise.ID) throws -> [WorkoutSet] {
        try WorkoutSet.where { $0.workoutExerciseID.eq(workoutExerciseID) }.order(by: \.position).fetchAll(db)
    }

    // MARK: - Clock

    /// Shows the exercise at `position`.
    public static func move(_ db: Database, workoutID: Workout.ID, toPosition position: Int) throws {
        try update(db, workoutID) { $0.currentPosition = max(0, position) }
    }

    /// Stops the clock, and the rest timer with it.
    public static func pause(_ db: Database, workoutID: Workout.ID, now: Date) throws {
        try update(db, workoutID) { workout in
            guard workout.resumedAt != nil else { return }
            workout.restPausedRemaining = workout.restRemainingSeconds(at: now)
            workout.restEndsAt = nil
            workout.elapsedBeforePauseSeconds = workout.elapsedSeconds(at: now)
            workout.resumedAt = nil
        }
    }

    /// Restarts the clock, and any rest that was running when it was paused.
    public static func resume(_ db: Database, workoutID: Workout.ID, now: Date) throws {
        try update(db, workoutID) { workout in
            guard workout.resumedAt == nil else { return }
            if let remaining = workout.restPausedRemaining {
                workout.restEndsAt = now.addingTimeInterval(TimeInterval(remaining))
            }
            workout.restPausedRemaining = nil
            workout.resumedAt = now
        }
    }

    // MARK: - Rest

    /// Rest after a set of `exerciseID`: the exercise's own rest, or the default from Settings.
    public static func restSeconds(_ db: Database, exerciseID: Exercise.ID) throws -> Int {
        let own = try ExercisePreference.find(exerciseID).fetchOne(db)?.restSeconds
        let fallback = try AppSettings.find(AppSettings.singletonID).select(\.restSeconds).fetchOne(db)
        return own ?? fallback ?? AppSettings().restSeconds
    }

    /// Starts a rest of `seconds`, unless the workout is paused or rest is off.
    public static func startRest(_ db: Database, workoutID: Workout.ID, seconds: Int, now: Date) throws {
        try update(db, workoutID) { workout in
            guard seconds > 0, workout.resumedAt != nil else { return }
            workout.restEndsAt = now.addingTimeInterval(TimeInterval(seconds))
            workout.restPausedRemaining = nil
        }
    }

    /// Lengthens or shortens the running rest, keeping 5 seconds to 10 minutes left.
    public static func adjustRest(_ db: Database, workoutID: Workout.ID, by seconds: Int, now: Date) throws {
        try update(db, workoutID) { workout in
            guard let remaining = workout.restRemainingSeconds(at: now) else { return }
            let adjusted = min(max(remaining + seconds, 5), 600)
            if workout.restPausedRemaining != nil {
                workout.restPausedRemaining = adjusted
            } else {
                workout.restEndsAt = now.addingTimeInterval(TimeInterval(adjusted))
            }
        }
    }

    public static func skipRest(_ db: Database, workoutID: Workout.ID) throws {
        try update(db, workoutID) { workout in
            workout.restEndsAt = nil
            workout.restPausedRemaining = nil
        }
    }

    private static func update(_ db: Database, _ id: Workout.ID, _ change: (inout Workout) -> Void) throws {
        guard var workout = try Workout.find(id).fetchOne(db) else { return }
        change(&workout)
        try Workout.upsert { Workout.Draft(workout) }.execute(db)
    }
}

extension Workout {
    /// Seconds on the clock at `now`: time banked before the last pause plus the running stretch.
    public func elapsedSeconds(at now: Date) -> Int {
        elapsedBeforePauseSeconds + (resumedAt.map { Swift.max(0, Int(now.timeIntervalSince($0))) } ?? 0)
    }

    public var isPaused: Bool { resumedAt == nil }

    /// Seconds of rest left at `now`; `nil` when not resting or the rest is over.
    public func restRemainingSeconds(at now: Date) -> Int? {
        if let restPausedRemaining { return restPausedRemaining }
        guard let restEndsAt else { return nil }
        let remaining = Int(restEndsAt.timeIntervalSince(now).rounded(.up))
        return remaining > 0 ? remaining : nil
    }
}

/// Reads over finished workouts.
public enum ExerciseHistory {
    /// Working sets of the most recent finished workout with `exerciseID`, in the order they were
    /// done; empty if it was never trained.
    public static func lastWorkingSets(_ db: Database, exerciseID: Exercise.ID) throws -> [WorkoutSet] {
        let lastWorkoutID =
            try WorkoutExercise
            .where { $0.exerciseID.eq(exerciseID) }
            .join(Workout.all) { $0.workoutID.eq($1.id) }
            .where { _, workouts in workouts.finishedAt.isNot(nil) }
            .order { _, workouts in workouts.startedAt.desc() }
            .limit(1)
            .select { _, workouts in workouts.id }
            .fetchOne(db)
        guard let lastWorkoutID else { return [] }
        return
            try WorkoutSet
            .where { $0.isCompleted && $0.kind.neq(SetKind.warmup) }
            .join(WorkoutExercise.all) { $0.workoutExerciseID.eq($1.id) }
            .where { _, workoutExercises in
                workoutExercises.workoutID.eq(lastWorkoutID) && workoutExercises.exerciseID.eq(exerciseID)
            }
            .order { workoutSets, workoutExercises in (workoutExercises.position, workoutSets.position) }
            .select { workoutSets, _ in workoutSets }
            .fetchAll(db)
    }
}

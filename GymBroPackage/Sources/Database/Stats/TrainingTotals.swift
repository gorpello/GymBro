import Foundation
import SQLiteData

/// All-time numbers the medals are measured against. Only finished workouts and completed working
/// sets count; warm-ups don't.
public struct TrainingTotals: Equatable, Sendable {
    /// The profile has been set up.
    public var isOnboarded = false
    public var routineCount = 0
    /// Exercises with at least one working set, each of which therefore has a personal record.
    public var recordCount = 0
    public var streak = 0
    public var workoutCount = 0
    public var setCount = 0
    public var volumeKg = 0.0
    public var trainingSeconds = 0

    public init() {}

    /// Reads every total in the caller's transaction.
    public static func fetch(_ db: Database, today: Date, calendar: Calendar) throws -> Self {
        var totals = Self()
        totals.isOnboarded = try UserProfile.find(UserProfile.singletonID).fetchCount(db) > 0
        totals.routineCount = try Routine.all.fetchCount(db)
        totals.streak = try Streak.fetch(db, today: today, calendar: calendar)

        let workouts =
            try Workout
            .where { $0.finishedAt.isNot(nil) }
            .select { WorkoutTotals.Columns(count: $0.id.count(), seconds: $0.durationSeconds.total()) }
            .fetchOne(db)
        totals.workoutCount = workouts?.count ?? 0
        totals.trainingSeconds = Int(workouts?.seconds ?? 0)

        let sets =
            try WorkoutSet
            .where { $0.isCompleted && $0.kind.neq(SetKind.warmup) }
            .join(WorkoutExercise.all) { $0.workoutExerciseID.eq($1.id) }
            .join(Workout.all) { $1.workoutID.eq($2.id) }
            .where { _, _, workouts in workouts.finishedAt.isNot(nil) }
            .select { workoutSets, workoutExercises, _ in
                SetTotals.Columns(
                    count: workoutSets.id.count(),
                    volumeKg: (workoutSets.reps.cast(as: Double.self) * workoutSets.weightKg).total(),
                    exerciseCount: workoutExercises.exerciseID.count(distinct: true)
                )
            }
            .fetchOne(db)
        totals.setCount = sets?.count ?? 0
        totals.volumeKg = sets?.volumeKg ?? 0
        totals.recordCount = sets?.exerciseCount ?? 0
        return totals
    }

    /// How far along `metric` is, in the unit its goals use.
    public func value(of metric: AwardKind.Metric) -> Int {
        switch metric {
        case .onboarding: isOnboarded ? 1 : 0
        case .routines: routineCount
        case .records: recordCount
        case .streak: streak
        case .workouts: workoutCount
        case .sets: setCount
        case .volumeKg: Int(volumeKg.rounded())
        case .hours: trainingSeconds / 3600
        }
    }
}

@Selection
private struct WorkoutTotals {
    let count: Int
    let seconds: Double
}

@Selection
private struct SetTotals {
    let count: Int
    let volumeKg: Double
    let exerciseCount: Int
}

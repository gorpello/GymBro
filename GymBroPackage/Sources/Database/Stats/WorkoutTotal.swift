import Foundation
import SQLiteData

/// Working sets and volume of one finished workout. Volume is reps × weight of completed working
/// sets; warm-ups and unticked sets don't count.
@Selection
public struct WorkoutTotal: Equatable, Sendable {
    public let id: Workout.ID
    public let startedAt: Date
    public let setCount: Int
    public let volumeKg: Double
}

extension WorkoutTotal {
    /// Finished workouts started in `start..<end`, oldest first. Workouts without a completed
    /// working set are left out.
    ///
    /// - Parameter end: `nil` reads up to now.
    public static func fetch(_ db: Database, from start: Date, to end: Date? = nil) throws -> [WorkoutTotal] {
        var workouts = Workout.where { $0.finishedAt.isNot(nil) && $0.startedAt.gte(start) }
        if let end {
            workouts = workouts.where { $0.startedAt.lt(end) }
        }
        return
            try workouts
            .group(by: \.id)
            .order(by: \.startedAt)
            .join(WorkoutExercise.all) { $0.id.eq($1.workoutID) }
            .join(WorkoutSet.all) { $1.id.eq($2.workoutExerciseID) }
            .where { _, _, workoutSets in
                workoutSets.isCompleted && workoutSets.kind.neq(SetKind.warmup)
            }
            .select { workouts, _, workoutSets in
                WorkoutTotal.Columns(
                    id: workouts.id,
                    startedAt: workouts.startedAt,
                    setCount: workoutSets.id.count(),
                    volumeKg: (workoutSets.reps.cast(as: Double.self) * workoutSets.weightKg).total()
                )
            }
            .fetchAll(db)
    }
}

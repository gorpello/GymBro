import Foundation
import SQLiteData

/// A workout, finished or in progress. The one with `finishedAt == nil` is the live session; its
/// sets are saved as they're ticked, so quitting the app mid-workout loses nothing.
@Table
public struct Workout: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var startedAt = Date()
    public var finishedAt: Date?
    public var durationSeconds = 0
    public var routineID: Routine.ID?
    /// Logged after the fact, without the timer.
    public var isManual = false

    // Live session only.
    public var currentPosition = 0
    public var elapsedBeforePauseSeconds = 0
    /// When the timer last started; `nil` while paused.
    public var resumedAt: Date?
    public var restEndsAt: Date?
    /// Seconds left on a paused rest timer.
    public var restPausedRemaining: Int?

    public var isLive: Bool { finishedAt == nil }
}

@Table
nonisolated public struct WorkoutExercise: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var workoutID: Workout.ID
    public var exerciseID: Exercise.ID
    public var position = 0
    public var isChainedToNext = false
}

@Table
nonisolated public struct WorkoutSet: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var workoutExerciseID: WorkoutExercise.ID
    public var position = 0
    public var reps = 0
    public var weightKg = 0.0
    public var kind: SetKind = .normal
    /// Rate of perceived exertion, 6…10.
    public var rpe: Double?
    public var durationSeconds: Int?
    public var distanceKm: Double?
    public var isCompleted = false

    public var volumeKg: Double { kind.counts ? Double(reps) * weightKg : 0 }

    public var estimatedOneRepMaxKg: Double {
        Self.estimatedOneRepMaxKg(weightKg: weightKg, reps: reps, rpe: rpe)
    }

    /// Estimated one-rep max: from the RPE chart when the set has an RPE and 1…12 reps, Epley otherwise.
    public static func estimatedOneRepMaxKg(weightKg: Double, reps: Int, rpe: Double?) -> Double {
        guard reps > 0 else { return 0 }
        if let rpe, (6...10).contains(rpe), (1...12).contains(reps) {
            let index = (reps - 1) * 2 + Int(((10 - rpe) * 2).rounded())
            if index < rpeChart.count { return weightKg / rpeChart[index] }
        }
        return weightKg * (1 + Double(reps) / 30)
    }

    /// Share of the one-rep max lifted, indexed by `(reps - 1) * 2 + (10 - rpe) * 2`.
    private static let rpeChart = [
        1.0, 0.978, 0.955, 0.939, 0.922, 0.907, 0.892, 0.878, 0.863, 0.85, 0.837, 0.824, 0.811, 0.799, 0.786,
        0.774, 0.762, 0.751, 0.739, 0.723, 0.707, 0.694, 0.68, 0.667, 0.653, 0.64, 0.626, 0.613, 0.599, 0.586,
        0.574,
    ]
}

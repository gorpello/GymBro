import Foundation
import SQLiteData

/// A workout, finished or in progress. The one with `finishedAt == nil` is the live session; its
/// sets are saved as they're ticked, so quitting the app mid-workout loses nothing.
@Table
public nonisolated struct Workout: Hashable, Identifiable, Sendable {
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
public nonisolated struct WorkoutExercise: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var workoutID: Workout.ID
    public var exerciseID: Exercise.ID
    public var position = 0
    public var isChainedToNext = false
}

@Table
public nonisolated struct WorkoutSet: Hashable, Identifiable, Sendable {
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
}

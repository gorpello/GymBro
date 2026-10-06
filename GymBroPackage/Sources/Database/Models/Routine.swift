import Foundation
import SQLiteData

@Table
public nonisolated struct Routine: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var name = ""
    /// Free-text folder, e.g. "Push / Pull / Legs". Empty means ungrouped.
    public var group = ""
    /// Index into the design system's routine palette; `nil` picks one from the name.
    public var colorIndex: Int?
    public var position = 0
}

@Table
public nonisolated struct RoutineExercise: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var routineID: Routine.ID
    public var exerciseID: Exercise.ID
    public var position = 0
    public var setCount = 3
    /// Superset: go straight to the next exercise without resting.
    public var isChainedToNext = false
}

/// A set planned in a routine. Empty values are filled in from history when the workout starts.
@Table
public nonisolated struct PlannedSet: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var routineExerciseID: RoutineExercise.ID
    public var position = 0
    public var reps: Int?
    /// `nil` means "suggest from the last workout".
    public var weightKg: Double?
    public var kind: SetKind = .normal
    public var durationSeconds: Int?
    public var distanceKm: Double?
}

/// One routine planned on one weekday. Several rows on the same day are allowed.
@Table
public nonisolated struct RoutineSchedule: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var routineID: Routine.ID
    /// 1 = Monday … 7 = Sunday.
    public var weekday = 1
}

import Foundation
import SQLiteData

/// A built-in catalogue exercise or one the user created. Catalogue rows keep their bundled ids so
/// they're the same on every device; custom exercises get a UUID string.
@Table
public struct Exercise: Hashable, Identifiable, Sendable {
    public let id: String
    public var name = ""
    public var primaryMuscle: Muscle = .chest
    @Column(as: [Muscle].JSONRepresentation.self)
    public var secondaryMuscles: [Muscle] = []
    public var equipment: Equipment = .other
    public var difficulty: Difficulty = .beginner
    /// File name of the bundled illustration in `GymAssets`; empty for custom exercises.
    public var art = ""
    @Column(as: [String].JSONRepresentation.self)
    public var steps: [String] = []
    public var mode: ExerciseMode = .weight
    public var isCustom = false
    /// Custom exercises are archived instead of deleted, so workout history keeps its names.
    public var isArchived = false
}

/// The user's choices for one exercise. Kept apart from `Exercise` so re-seeding the catalogue
/// never overwrites them. A missing row means "all defaults".
@Table
public struct ExercisePreference: Hashable, Identifiable, Sendable {
    @Column(primaryKey: true)
    public let exerciseID: Exercise.ID
    public var isFavorite = false
    public var modeOverride: ExerciseMode?
    /// 15…600 seconds; `nil` uses the global rest setting.
    public var restSeconds: Int?
    /// Weight added once every set hits its reps; `nil` turns auto-progression off, so the next
    /// workout repeats the last weights.
    public var progressStepKg: Double?
    public var autoWarmup = false
    /// `nil` decides automatically from the exercise's equipment.
    public var repsOnly: Bool?
    public var suggestsNextStep = true
    /// Stay on this exercise instead of being offered the harder variation.
    public var keepsLevel = false
    public var nextStepSnoozedUntil: Date?
    public var barWeightKg: Double?
    /// File in the app container that replaces the bundled illustration.
    public var customMediaFile: String?
    /// Bookmarks in a custom video: index → milliseconds.
    @Column(as: [Int: Int].JSONRepresentation.self)
    public var videoMarks: [Int: Int] = [:]
    public var goalTargetKg: Double?
    public var goalDueDate: Date?
    /// Offered when Home and Train recommend exercises.
    public var isSuggested = true

    public var id: Exercise.ID { exerciseID }
}

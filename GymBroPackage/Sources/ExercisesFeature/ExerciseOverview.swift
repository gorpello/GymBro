import Database
import Foundation
import SQLiteData

/// Everything the exercise screen shows. Read in one transaction by `ExerciseOverview.Request` and
/// re-read whenever the exercise, its preferences, its workouts or its notes change.
public struct ExerciseOverview: Equatable, Sendable {
    public static let historyLimit = 8
    public static let similarLimit = 4

    /// `nil` until read, or when the exercise has been deleted.
    public var exercise: Exercise?
    /// `nil` while the exercise still has all-default preferences.
    public var preference: ExercisePreference?
    public var units = AppSettings().units
    /// Rest used when the exercise has none of its own.
    public var defaultRestSeconds = AppSettings().restSeconds
    public var record: PersonalRecord?
    public var nextTarget: Progression.Target?
    /// Latest workouts first.
    public var history: [HistoryEntry] = []
    public var noteCount = 0
    /// Others with the same main muscle.
    public var similar: [SimilarExercise] = []

    public init() {}

    public struct Request: FetchKeyRequest {
        public var exerciseID: Exercise.ID

        public init(exerciseID: Exercise.ID) {
            self.exerciseID = exerciseID
        }

        public func fetch(_ db: Database) throws -> ExerciseOverview {
            var overview = ExerciseOverview()
            guard let exercise = try Exercise.find(exerciseID).fetchOne(db) else { return overview }
            overview.exercise = exercise
            overview.preference = try ExercisePreference.find(exerciseID).fetchOne(db)
            if let settings = try AppSettings.find(AppSettings.singletonID).fetchOne(db) {
                overview.units = settings.units
                overview.defaultRestSeconds = settings.restSeconds
            }

            overview.record = PersonalRecord(sets: try PersonalRecord.fetchSets(db, exerciseIDs: [exerciseID]))
            let stepKg = overview.units == .kg ? Progression.defaultStepKg : 5 * WeightUnit.lb.kilograms
            overview.nextTarget = Progression.nextTarget(
                after: try ExerciseHistory.lastWorkingSets(db, exerciseID: exerciseID),
                stepKg: stepKg
            )
            overview.history =
                try WorkoutSet
                .where { $0.isCompleted && $0.kind.neq(SetKind.warmup) }
                .join(WorkoutExercise.all) { $0.workoutExerciseID.eq($1.id) }
                .join(Workout.all) { $1.workoutID.eq($2.id) }
                .where { _, workoutExercises, workouts in
                    workoutExercises.exerciseID.eq(exerciseID) && workouts.finishedAt.isNot(nil)
                }
                .group { _, _, workouts in workouts.id }
                .order { _, _, workouts in workouts.startedAt.desc() }
                .limit(ExerciseOverview.historyLimit)
                .select { workoutSets, _, workouts in
                    HistoryEntry.Columns(
                        id: workouts.id,
                        date: workouts.startedAt,
                        setCount: workoutSets.id.count(),
                        topWeightKg: workoutSets.weightKg.max() ?? 0,
                        volumeKg: (workoutSets.reps.cast(as: Double.self) * workoutSets.weightKg).total()
                    )
                }
                .fetchAll(db)
            overview.noteCount = try Note.where { $0.exerciseID.eq(exerciseID) }.fetchCount(db)
            overview.similar =
                try Exercise
                .where {
                    $0.primaryMuscle.eq(exercise.primaryMuscle) && $0.id.neq(exerciseID) && !$0.isArchived
                }
                .order(by: \.name)
                .limit(ExerciseOverview.similarLimit)
                .select { SimilarExercise.Columns(id: $0.id, art: $0.art, name: $0.name) }
                .fetchAll(db)
            return overview
        }
    }
}

/// One finished workout of the exercise: its working sets, heaviest weight and volume.
@Selection
public struct HistoryEntry: Equatable, Identifiable, Sendable {
    public var id: Workout.ID
    public var date: Date
    public var setCount: Int
    public var topWeightKg: Double
    public var volumeKg: Double
}

@Selection
public struct SimilarExercise: Equatable, Identifiable, Sendable {
    public var id: Exercise.ID
    public var art: String
    public var name: String
}

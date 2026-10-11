import Database
import Foundation
import SQLiteData

/// The workout in progress, as the session screen shows it. Read by `LiveSession.Request` and
/// re-read after every change, so the screen always shows what's saved.
public struct LiveSession: Equatable, Sendable {
    /// `nil` when no workout is in progress.
    public var workout: Workout?
    public var exercises: [Entry] = []
    public var units = AppSettings().units

    public init() {}

    /// One exercise of the workout, with its sets and history.
    public struct Entry: Equatable, Identifiable, Sendable {
        /// The `WorkoutExercise` row.
        public var id: WorkoutExercise.ID
        public var exerciseID: Exercise.ID
        public var name: String
        public var art: String
        public var muscle: Muscle
        public var sets: [WorkoutSet]
        /// Working sets from the last time this exercise was done; empty the first time.
        public var lastSets: [WorkoutSet]
        public var nextTarget: Progression.Target?
        /// Rest started after each of its sets.
        public var restSeconds: Int
    }

    public var setsDone: Int { exercises.reduce(0) { $0 + $1.sets.count(where: \.isCompleted) } }
    public var setsTotal: Int { exercises.reduce(0) { $0 + $1.sets.count } }
}

extension LiveSession {
    public struct Request: FetchKeyRequest {
        public init() {}

        public func fetch(_ db: Database) throws -> LiveSession {
            var session = LiveSession()
            session.units =
                try AppSettings.find(AppSettings.singletonID).select(\.units).fetchOne(db) ?? AppSettings().units
            guard let workout = try LiveWorkout.fetch(db) else { return session }
            session.workout = workout

            let rows =
                try WorkoutExercise
                .where { $0.workoutID.eq(workout.id) }
                .join(Exercise.all) { $0.exerciseID.eq($1.id) }
                .order { workoutExercises, _ in workoutExercises.position }
                .select { workoutExercises, exercises in
                    Row.Columns(
                        id: workoutExercises.id,
                        exerciseID: exercises.id,
                        name: exercises.name,
                        art: exercises.art,
                        muscle: exercises.primaryMuscle
                    )
                }
                .fetchAll(db)
            let sets = try Dictionary(
                grouping:
                    WorkoutSet
                    .where { $0.workoutExerciseID.in(rows.map(\.id)) }
                    .order(by: \.position)
                    .fetchAll(db),
                by: \.workoutExerciseID
            )
            let stepKg = session.units == .kg ? Progression.defaultStepKg : 5 * WeightUnit.lb.kilograms

            session.exercises = try rows.map { row in
                let lastSets = try ExerciseHistory.lastWorkingSets(db, exerciseID: row.exerciseID)
                return Entry(
                    id: row.id,
                    exerciseID: row.exerciseID,
                    name: row.name,
                    art: row.art,
                    muscle: row.muscle,
                    sets: sets[row.id] ?? [],
                    lastSets: lastSets,
                    nextTarget: Progression.nextTarget(after: lastSets, stepKg: stepKg),
                    restSeconds: try LiveWorkout.restSeconds(db, exerciseID: row.exerciseID)
                )
            }
            return session
        }
    }
}

@Selection
private struct Row {
    let id: WorkoutExercise.ID
    let exerciseID: Exercise.ID
    let name: String
    let art: String
    let muscle: Muscle
}

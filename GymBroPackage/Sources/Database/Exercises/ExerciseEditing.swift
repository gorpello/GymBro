import Foundation
import SQLiteData

extension Exercise {
    /// A new custom exercise with every field at its default, ready to be filled in.
    public static func custom(id: Exercise.ID) -> Exercise {
        Exercise(id: id, isCustom: true)
    }

    /// Bodyweight moves that need no kit at all.
    public var isNoKit: Bool { equipment == .bodyweight }

    /// Saves a custom exercise, new or edited. Editing keeps its archived flag and clears any
    /// logging-mode override, so the mode chosen in the editor is the one that applies.
    public static func saveCustom(_ db: Database, _ exercise: Exercise) throws {
        var exercise = exercise
        exercise.isCustom = true
        if let current = try find(exercise.id).fetchOne(db) {
            exercise.isArchived = current.isArchived
        }
        try upsert { Draft(exercise) }.execute(db)
        try ExercisePreference.find(exercise.id).update { $0.modeOverride = nil }.execute(db)
    }

    /// Deletes a custom exercise along with its preferences and routine slots; its notes stay,
    /// unlinked. One that appears in a workout is archived instead, so the history keeps its name.
    /// Catalogue exercises are never deleted.
    ///
    /// - Returns: `true` when the exercise was deleted, `false` when it was archived or isn't custom.
    @discardableResult
    public static func deleteCustom(_ db: Database, id: Exercise.ID) throws -> Bool {
        guard try Exercise.where({ $0.id.eq(id) && $0.isCustom }).fetchCount(db) > 0 else { return false }
        guard try WorkoutExercise.where({ $0.exerciseID.eq(id) }).fetchCount(db) == 0 else {
            try find(id).update { $0.isArchived = true }.execute(db)
            return false
        }
        try find(id).delete().execute(db)
        return true
    }

    /// Steps typed one per line. Blank lines and list markers such as "1." or "-" are dropped.
    public static func steps(from text: String) -> [String] {
        text.split(whereSeparator: \.isNewline).compactMap { line in
            let step = droppingListMarker(line).trimmingCharacters(in: .whitespaces)
            return step.isEmpty ? nil : step
        }
    }

    private static func droppingListMarker(_ line: Substring) -> Substring {
        let text = line.drop(while: \.isWhitespace)
        if let first = text.first, "-•*".contains(first) {
            return text.dropFirst()
        }
        let digits = text.prefix(while: \.isNumber)
        let rest = text.dropFirst(digits.count)
        if !digits.isEmpty, let mark = rest.first, ".)".contains(mark) {
            return rest.dropFirst()
        }
        return text
    }

    /// Secondary muscles in map order, without the primary one.
    public static func secondaryMuscles(_ muscles: Set<Muscle>, primary: Muscle) -> [Muscle] {
        Muscle.all.filter { $0 != primary && muscles.contains($0) }
    }
}

extension ExercisePreference {
    /// What an exercise without a saved row uses.
    public static func defaults(for exerciseID: Exercise.ID) -> Self {
        Self(exerciseID: exerciseID)
    }

    /// Applies `change` to the exercise's preferences, starting from the defaults when it has none
    /// yet, and saves them.
    public static func edit(
        _ db: Database,
        exerciseID: Exercise.ID,
        _ change: (inout Self) -> Void
    ) throws {
        var preference = try find(exerciseID).fetchOne(db) ?? defaults(for: exerciseID)
        change(&preference)
        try upsert { Draft(preference) }.execute(db)
    }
}

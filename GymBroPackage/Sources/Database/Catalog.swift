import Foundation
import GymAssets
import SQLiteData

extension Exercise {
    /// The built-in catalogue decoded from `GymAssets/Data/exercises.json`.
    static func bundledCatalog() throws -> [Exercise] {
        guard let url = GymAssets.exerciseCatalogURL else { throw CatalogError.missingFile }
        let file = try JSONDecoder().decode(CatalogFile.self, from: Data(contentsOf: url))
        return file.exercises.map(Exercise.init)
    }

    /// Inserts new catalogue exercises and updates changed ones. Rows that already match are left
    /// alone, so running this on every launch writes nothing (and won't trigger iCloud sync later).
    /// User data is preserved: archived flags, preferences, custom exercises and catalogue entries
    /// removed from the bundle, which old workouts may still point to.
    static func seedCatalog(_ db: Database) throws {
        let existing = Dictionary(
            uniqueKeysWithValues: try Exercise.where { !$0.isCustom }.fetchAll(db).map { ($0.id, $0) }
        )
        var inserts: [Exercise] = []
        for var exercise in try bundledCatalog() {
            guard let current = existing[exercise.id] else {
                inserts.append(exercise)
                continue
            }
            exercise.isArchived = current.isArchived
            if exercise != current {
                try Exercise.update(exercise).execute(db)
            }
        }
        if !inserts.isEmpty {
            try Exercise.insert { inserts }.execute(db)
        }
    }
}

enum CatalogError: Error {
    case missingFile
}

private struct CatalogFile: Decodable {
    var exercises: [Entry]

    struct Entry: Decodable {
        var id: String
        var name: String
        var primary: String
        var secondary: [String]?
        var equipment: String?
        var difficulty: String?
        var art: String?
        var steps: [String]?
    }
}

private extension Exercise {
    init(_ entry: CatalogFile.Entry) {
        self.init(
            id: entry.id,
            name: entry.name,
            primaryMuscle: Muscle(rawValue: entry.primary),
            secondaryMuscles: (entry.secondary ?? []).filter { $0 != entry.primary }.map(Muscle.init),
            equipment: Equipment(rawValue: entry.equipment ?? Equipment.other.rawValue),
            difficulty: Difficulty(rawValue: entry.difficulty ?? Difficulty.beginner.rawValue),
            art: entry.art ?? "",
            steps: entry.steps ?? []
        )
    }
}

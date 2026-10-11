import Database
import Foundation
import SQLiteData

/// What narrows the library. Everything combines; an empty filter shows every active exercise.
public struct ExerciseFilter: Hashable, Sendable {
    public var search = ""
    public var favouritesOnly = false
    public var noKitOnly = false
    public var customOnly = false
    /// Archived exercises are shown instead of the active ones.
    public var archivedOnly = false
    /// Trains the muscle, as its main or a secondary one.
    public var muscle: Muscle?
    public var equipment: Equipment?
    public var difficulty: Difficulty?

    public init() {}

    /// Filters chosen in the sheet, shown as a count on its button.
    public var sheetCount: Int {
        [muscle != nil, equipment != nil, difficulty != nil, archivedOnly].count { $0 }
    }

    public func matches(_ exercise: Exercise, isFavourite: Bool) -> Bool {
        guard exercise.isArchived == archivedOnly else { return false }
        if favouritesOnly, !isFavourite { return false }
        if noKitOnly, !exercise.isNoKit { return false }
        if customOnly, !exercise.isCustom { return false }
        if let muscle, exercise.primaryMuscle != muscle, !exercise.secondaryMuscles.contains(muscle) { return false }
        if let equipment, exercise.equipment != equipment { return false }
        if let difficulty, exercise.difficulty != difficulty { return false }
        let query = search.trimmingCharacters(in: .whitespaces)
        return query.isEmpty || exercise.name.localizedStandardContains(query)
    }
}

/// The library as listed: matching exercises grouped by main muscle, plus the counts the header
/// and chips show.
public struct ExerciseListing: Equatable, Sendable {

    public var sections: [ExerciseSection] = []
    public var favouriteCount = 0
    /// Whether anything is archived, so the archived filter is worth offering.
    public var hasArchived = false

    public init() {}

    public var exerciseCount: Int { sections.reduce(0) { $0 + $1.rows.count } }

    public struct Request: FetchKeyRequest {
        public var filter: ExerciseFilter

        public init(filter: ExerciseFilter) {
            self.filter = filter
        }

        public func fetch(_ db: Database) throws -> ExerciseListing {
            let favourites = try Set(ExercisePreference.where(\.isFavorite).select(\.exerciseID).fetchAll(db))
            let exercises = try Exercise.order(by: \.name).fetchAll(db)

            var listing = ExerciseListing()
            listing.favouriteCount = favourites.count
            listing.hasArchived = exercises.contains(where: \.isArchived)
            let rows = exercises.compactMap { exercise -> ExerciseRowState? in
                let isFavourite = favourites.contains(exercise.id)
                guard filter.matches(exercise, isFavourite: isFavourite) else { return nil }
                return ExerciseRowState(exercise: exercise, isFavourite: isFavourite)
            }
            listing.sections = ExerciseListing.sections(of: rows, leading: filter.muscle)
            return listing
        }
    }

    /// Rows grouped by main muscle in map order, with `leading` first when a muscle is picked.
    static func sections(of rows: [ExerciseRowState], leading: Muscle?) -> [ExerciseSection] {
        let groups = Dictionary(grouping: rows, by: \.primaryMuscle)
        let known = Set(Muscle.all)
        let unknown = groups.keys.filter { !known.contains($0) }.sorted { $0.rawValue < $1.rawValue }
        let order = (leading.map { [$0] } ?? []) + Muscle.all.filter { $0 != leading } + unknown
        return order.compactMap { muscle in
            groups[muscle].map { ExerciseSection(id: muscle, rows: $0) }
        }
    }
}

public struct ExerciseSection: Equatable, Identifiable, Sendable {
    /// Main muscle of every row in the section.
    public var id: Muscle
    public var rows: [ExerciseRowState]

    public init(id: Muscle, rows: [ExerciseRowState]) {
        self.id = id
        self.rows = rows
    }
}

public struct ExerciseRowState: Equatable, Identifiable, Sendable {
    public var id: Exercise.ID
    /// Illustration name under `Art/`, e.g. `bench-press`; empty for custom exercises.
    public var art: String
    public var difficulty: Difficulty
    public var equipment: Equipment
    public var isCustom: Bool
    public var isFavourite: Bool
    public var name: String
    public var primaryMuscle: Muscle

    public init(exercise: Exercise, isFavourite: Bool) {
        self.id = exercise.id
        self.art = exercise.art
        self.difficulty = exercise.difficulty
        self.equipment = exercise.equipment
        self.isCustom = exercise.isCustom
        self.isFavourite = isFavourite
        self.name = exercise.name
        self.primaryMuscle = exercise.primaryMuscle
    }
}

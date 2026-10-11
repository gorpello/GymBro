import Dependencies
import Foundation
import SQLiteData

/// A routine while it's being edited: read in one go, changed in memory, then saved in one
/// transaction, so leaving the editor without saving changes nothing.
public struct RoutineDraft: Equatable, Sendable {
    public var name = ""
    /// Free-text folder; empty means ungrouped.
    public var group = ""
    public var colorIndex: Int?
    /// Days it's planned on, 1 = Monday … 7 = Sunday.
    public var weekdays: Set<Int> = []
    /// In the order they're done. An exercise is in a routine at most once.
    public var exercises: [Item] = []

    /// Working sets per exercise (`kDefaultRoutineSets` and the clamp in GymMane).
    public static let setRange = 1...12
    public static let defaultSetCount = 3

    public init() {}

    public struct Item: Equatable, Identifiable, Sendable {
        /// The exercise's id.
        public var id: Exercise.ID
        /// Illustration name under `Art/`; empty for custom exercises.
        public var art: String
        public var name: String
        /// Working sets; planned warm-ups come on top.
        public var setCount: Int
        /// Superset: go straight to the next exercise without resting.
        public var isChainedToNext: Bool

        public init(id: Exercise.ID, art: String, name: String, setCount: Int, isChainedToNext: Bool = false) {
            self.id = id
            self.art = art
            self.name = name
            self.setCount = setCount
            self.isChainedToNext = isChainedToNext
        }
    }
}

extension RoutineDraft {
    /// Routine `id` as the editor starts from, or `nil` if it no longer exists.
    public static func fetch(_ db: Database, id: Routine.ID) throws -> RoutineDraft? {
        guard let routine = try Routine.find(id).fetchOne(db) else { return nil }
        let rows =
            try RoutineExercise
            .where { $0.routineID.eq(id) }
            .order(by: \.position)
            .join(Exercise.all) { $0.exerciseID.eq($1.id) }
            .fetchAll(db)
        let planned = Dictionary(
            grouping: try PlannedSet.where { $0.routineExerciseID.in(rows.map(\.0.id)) }.fetchAll(db),
            by: \.routineExerciseID
        )

        var draft = RoutineDraft()
        draft.name = routine.name
        draft.group = routine.group
        draft.colorIndex = routine.colorIndex
        draft.weekdays = try Set(RoutineSchedule.where { $0.routineID.eq(id) }.select(\.weekday).fetchAll(db))
        var seen = Set<Exercise.ID>()
        draft.exercises = rows.compactMap { routineExercise, exercise in
            guard seen.insert(exercise.id).inserted else { return nil }
            return Item(
                id: exercise.id,
                art: exercise.art,
                name: exercise.name,
                setCount: setCount(of: routineExercise, planned: planned[routineExercise.id] ?? []),
                isChainedToNext: routineExercise.isChainedToNext
            )
        }
        return draft
    }

    /// Saves the draft as routine `id`, adding it at the end of the list when it's new.
    ///
    /// Exercises that stay keep their planned sets, with working sets added (copying the last one)
    /// or removed from the end to match the new count. The last exercise never chains to a next one.
    public func save(_ db: Database, id: Routine.ID) throws {
        @Dependency(\.uuid) var uuid
        let position = try Routine.find(id).select(\.position).fetchOne(db) ?? Routine.nextPosition(db)
        try Routine.upsert {
            Routine.Draft(
                id: id,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                group: group.trimmingCharacters(in: .whitespacesAndNewlines),
                colorIndex: colorIndex,
                position: position
            )
        }
        .execute(db)

        let existing = try RoutineExercise.where { $0.routineID.eq(id) }.fetchAll(db)
        var existingIDs: [Exercise.ID: RoutineExercise.ID] = [:]
        for routineExercise in existing where existingIDs[routineExercise.exerciseID] == nil {
            existingIDs[routineExercise.exerciseID] = routineExercise.id
        }
        let keptIDs = exercises.compactMap { existingIDs[$0.id] }
        try RoutineExercise.where { $0.routineID.eq(id) && !$0.id.in(keptIDs) }.delete().execute(db)

        for (position, item) in exercises.enumerated() {
            let routineExerciseID = existingIDs[item.id] ?? uuid()
            try RoutineExercise.upsert {
                RoutineExercise.Draft(
                    id: routineExerciseID,
                    routineID: id,
                    exerciseID: item.id,
                    position: position,
                    setCount: item.setCount,
                    isChainedToNext: item.isChainedToNext && position < exercises.count - 1
                )
            }
            .execute(db)
            try Self.resizePlan(db, of: routineExerciseID, toWorkingSets: item.setCount)
        }

        try RoutineSchedule.where { $0.routineID.eq(id) && !$0.weekday.in(Array(weekdays)) }.delete().execute(db)
        let scheduled = try Set(RoutineSchedule.where { $0.routineID.eq(id) }.select(\.weekday).fetchAll(db))
        for weekday in weekdays.subtracting(scheduled).sorted() {
            try RoutineSchedule.insert { RoutineSchedule(id: uuid(), routineID: id, weekday: weekday) }.execute(db)
        }
    }

    /// Working sets shown for a routine exercise: its planned ones (or every planned set, when all
    /// are warm-ups), else its set count (`routineSets` in GymMane).
    static func setCount(of routineExercise: RoutineExercise, planned: [PlannedSet]) -> Int {
        guard !planned.isEmpty else { return routineExercise.setCount }
        let working = planned.count { $0.kind != .warmup }
        return working == 0 ? planned.count : working
    }

    /// Adds or removes planned working sets at the end until there are `count`. Exercises with no
    /// planned working sets are left alone; their set count is enough.
    private static func resizePlan(
        _ db: Database,
        of routineExerciseID: RoutineExercise.ID,
        toWorkingSets count: Int
    ) throws {
        @Dependency(\.uuid) var uuid
        let planned =
            try PlannedSet
            .where { $0.routineExerciseID.eq(routineExerciseID) }
            .order(by: \.position)
            .fetchAll(db)
        let working = planned.filter { $0.kind != .warmup }
        guard let last = working.last, working.count != count else { return }
        if count < working.count {
            let removed = working.suffix(working.count - count).map(\.id)
            try PlannedSet.where { $0.id.in(removed) }.delete().execute(db)
            return
        }
        let nextPosition = (planned.last?.position ?? 0) + 1
        for offset in 0..<(count - working.count) {
            try PlannedSet.insert {
                PlannedSet(
                    id: uuid(),
                    routineExerciseID: routineExerciseID,
                    position: nextPosition + offset,
                    reps: last.reps,
                    weightKg: last.weightKg,
                    durationSeconds: last.durationSeconds,
                    distanceKm: last.distanceKm
                )
            }
            .execute(db)
        }
    }
}

extension Routine {
    /// Position after the last routine in the list.
    static func nextPosition(_ db: Database) throws -> Int {
        try Routine.select { $0.position.max() ?? -1 }.fetchOne(db).map { $0 + 1 } ?? 0
    }

    /// Copies routine `id`, with its exercises and planned sets, to the end of the list as `name`.
    /// The copy isn't planned on any day yet.
    ///
    /// - Returns: The copy's id, or `nil` if `id` no longer exists.
    @discardableResult
    public static func duplicate(_ db: Database, id: Routine.ID, name: String) throws -> Routine.ID? {
        @Dependency(\.uuid) var uuid
        guard let source = try Routine.find(id).fetchOne(db) else { return nil }
        let copyID = uuid()
        let position = try nextPosition(db)
        try Routine.insert {
            Routine(id: copyID, name: name, group: source.group, colorIndex: source.colorIndex, position: position)
        }
        .execute(db)

        let routineExercises = try RoutineExercise.where { $0.routineID.eq(id) }.order(by: \.position).fetchAll(db)
        for routineExercise in routineExercises {
            let routineExerciseID = uuid()
            try RoutineExercise.insert {
                RoutineExercise(
                    id: routineExerciseID,
                    routineID: copyID,
                    exerciseID: routineExercise.exerciseID,
                    position: routineExercise.position,
                    setCount: routineExercise.setCount,
                    isChainedToNext: routineExercise.isChainedToNext
                )
            }
            .execute(db)
            let planned =
                try PlannedSet
                .where { $0.routineExerciseID.eq(routineExercise.id) }
                .order(by: \.position)
                .fetchAll(db)
            for plannedSet in planned {
                try PlannedSet.insert {
                    PlannedSet(
                        id: uuid(),
                        routineExerciseID: routineExerciseID,
                        position: plannedSet.position,
                        reps: plannedSet.reps,
                        weightKg: plannedSet.weightKg,
                        kind: plannedSet.kind,
                        durationSeconds: plannedSet.durationSeconds,
                        distanceKm: plannedSet.distanceKm
                    )
                }
                .execute(db)
            }
        }
        return copyID
    }
}

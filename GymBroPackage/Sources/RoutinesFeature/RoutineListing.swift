import Database
import Foundation
import SQLiteData

/// The Routines screen as read from the database: the week's plan and every routine, by group.
public struct RoutineListing: Equatable, Sendable {
    /// Routines in list order, grouped by folder in the order each folder first appears.
    public var groups: [RoutineGroup] = []
    /// Names of the routines planned on each weekday, Monday first; empty on rest days.
    public var weeklyPlan: [[String]] = Array(repeating: [], count: 7)

    public init() {}

    public func routine(id: Routine.ID) -> RoutineCard? {
        groups.lazy.flatMap(\.routines).first { $0.id == id }
    }

    public struct Request: FetchKeyRequest {
        public init() {}

        public func fetch(_ db: Database) throws -> RoutineListing {
            let routines =
                try Routine
                .group(by: \.id)
                .order(by: \.position)
                .leftJoin(RoutineExercise.all) { $0.id.eq($1.routineID) }
                .select { routines, routineExercises in
                    RoutineCard.Columns(
                        id: routines.id,
                        exerciseCount: routineExercises.id.count(distinct: true),
                        group: routines.group,
                        hue: routines.colorIndex ?? routines.position,
                        name: routines.name
                    )
                }
                .fetchAll(db)
            let scheduled =
                try RoutineSchedule
                .join(Routine.all) { $0.routineID.eq($1.id) }
                .order { routineSchedules, routines in (routineSchedules.weekday, routines.position) }
                .select { routineSchedules, routines in (routineSchedules.weekday, routines.name) }
                .fetchAll(db)

            var listing = RoutineListing()
            listing.groups = RoutineListing.groups(of: routines)
            for (weekday, name) in scheduled where (1...7).contains(weekday) {
                listing.weeklyPlan[weekday - 1].append(name)
            }
            return listing
        }
    }

    /// Routines grouped by folder, keeping list order within and between folders.
    static func groups(of routines: [RoutineCard]) -> [RoutineGroup] {
        var groups: [RoutineGroup] = []
        for routine in routines {
            if let index = groups.firstIndex(where: { $0.id == routine.group }) {
                groups[index].routines.append(routine)
            } else {
                groups.append(RoutineGroup(id: routine.group, routines: [routine]))
            }
        }
        return groups
    }
}

public struct RoutineGroup: Equatable, Identifiable, Sendable {
    /// Folder name; empty for ungrouped routines.
    public var id: String
    public var routines: [RoutineCard]

    public init(id: String, routines: [RoutineCard]) {
        self.id = id
        self.routines = routines
    }
}

@Selection
public struct RoutineCard: Equatable, Identifiable, Sendable {
    public var id: Routine.ID
    public var exerciseCount: Int
    public var group: String
    /// Index into `GymColor.folderHues`.
    public var hue: Int
    /// May be empty; shown as "New routine".
    public var name: String
}

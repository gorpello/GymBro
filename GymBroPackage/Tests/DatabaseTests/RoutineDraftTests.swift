import Dependencies
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import Database

/// Reading and saving routines, on a fresh database.
@Suite(
    .dependencies {
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct RoutineDraftTests {
    @Dependency(\.defaultDatabase) var database

    @Test func aMissingRoutineReadsAsNil() throws {
        #expect(try database.read { db in try RoutineDraft.fetch(db, id: UUID(-1)) } == nil)
    }

    @Test func readsTheRoutineWithItsDaysAndExercisesInOrder() throws {
        try database.write(seedPush)
        let draft = try #require(try database.read { db in try RoutineDraft.fetch(db, id: push) })

        #expect(draft.name == "Push")
        #expect(draft.group == "PPL")
        #expect(draft.weekdays == [1, 4])
        #expect(draft.exercises.map(\.id) == [bench, press])
        #expect(draft.exercises.map(\.name) == ["Barbell Bench Press", pressName])
        // Bench has two planned working sets after its warm-up; the press has no plan.
        #expect(draft.exercises.map(\.setCount) == [2, 4])
        #expect(draft.exercises.map(\.isChainedToNext) == [true, false])
    }

    @Test func aNewRoutineGoesAtTheEndOfTheList() throws {
        try database.write(seedPush)
        var draft = RoutineDraft()
        draft.name = "  Legs "
        draft.weekdays = [3]
        draft.exercises = [RoutineDraft.Item(id: press, art: "", name: "", setCount: 3, isChainedToNext: true)]

        try database.write { db in try draft.save(db, id: UUID(-2)) }

        let routine = try database.read { db in try Routine.find(UUID(-2)).fetchOne(db) }
        #expect(routine?.name == "Legs")
        #expect(routine?.position == 1)
        let saved = try #require(try database.read { db in try RoutineDraft.fetch(db, id: UUID(-2)) })
        #expect(saved.weekdays == [3])
        // The last exercise has nothing to chain to.
        #expect(saved.exercises.map(\.isChainedToNext) == [false])
    }

    @Test func savingKeepsPlansAndResizesThem() throws {
        try database.write(seedPush)
        var draft = try #require(try database.read { db in try RoutineDraft.fetch(db, id: push) })
        draft.exercises[0].setCount = 4
        draft.exercises.reverse()
        draft.weekdays = [4, 6]

        try database.write { db in try draft.save(db, id: push) }

        let planned = try database.read { db in
            try PlannedSet.where { $0.routineExerciseID.eq(UUID(-1)) }.order(by: \.position).fetchAll(db)
        }
        // The warm-up stays first; two copies of the last working set are added.
        #expect(planned.map(\.kind) == [.warmup, .normal, .normal, .normal, .normal])
        #expect(planned.map(\.reps) == [10, 8, 6, 6, 6])
        let saved = try #require(try database.read { db in try RoutineDraft.fetch(db, id: push) })
        #expect(saved.exercises.map(\.id) == [press, bench])
        #expect(saved.exercises.map(\.setCount) == [4, 4])
        #expect(saved.weekdays == [4, 6])
        #expect(try database.read { db in try RoutineSchedule.all.fetchCount(db) } == 2)
    }

    @Test func fewerSetsDropPlannedWorkingSetsFromTheEnd() throws {
        try database.write(seedPush)
        var draft = try #require(try database.read { db in try RoutineDraft.fetch(db, id: push) })
        draft.exercises[0].setCount = 1

        try database.write { db in try draft.save(db, id: push) }

        let planned = try database.read { db in
            try PlannedSet.where { $0.routineExerciseID.eq(UUID(-1)) }.order(by: \.position).fetchAll(db)
        }
        #expect(planned.map(\.reps) == [10, 8])
    }

    @Test func removedExercisesTakeTheirPlansWithThem() throws {
        try database.write(seedPush)
        var draft = try #require(try database.read { db in try RoutineDraft.fetch(db, id: push) })
        draft.exercises.removeFirst()

        try database.write { db in try draft.save(db, id: push) }

        #expect(try database.read { db in try RoutineExercise.all.fetchCount(db) } == 1)
        #expect(try database.read { db in try PlannedSet.all.fetchCount(db) } == 0)
    }

    @Test func duplicatingCopiesEverythingButTheDays() throws {
        try database.write(seedPush)
        let copyID = try #require(
            try database.write { db in try Routine.duplicate(db, id: push, name: "Push (copy)") }
        )

        let copy = try #require(try database.read { db in try RoutineDraft.fetch(db, id: copyID) })
        let original = try #require(try database.read { db in try RoutineDraft.fetch(db, id: push) })
        #expect(copy.name == "Push (copy)")
        #expect(copy.group == original.group)
        #expect(copy.exercises == original.exercises)
        #expect(copy.weekdays.isEmpty)
        #expect(try database.read { db in try PlannedSet.all.fetchCount(db) } == 6)
        #expect(try database.read { db in try Routine.find(copyID).fetchOne(db)?.position } == 1)
    }

    @Test func duplicatingAMissingRoutineDoesNothing() throws {
        let copyID = try database.write { db in try Routine.duplicate(db, id: UUID(-9), name: "Copy") }
        #expect(copyID == nil)
        #expect(try database.read { db in try Routine.all.fetchCount(db) } == 0)
    }
}

private let push = UUID(-1)
private let bench: Exercise.ID = "EIeI8Vf"
private let press: Exercise.ID = "kTbSH9h"
private let pressName = "Barbell Seated Overhead Press"

/// "Push" on Monday and Thursday: bench (a warm-up then 8 and 6 reps, chained to the next) and
/// the press (4 sets, no plan).
private func seedPush(_ db: Database) throws {
    try db.seed {
        Routine(id: push, name: "Push", group: "PPL")
        RoutineSchedule(id: UUID(-1), routineID: push, weekday: 1)
        RoutineSchedule(id: UUID(-2), routineID: push, weekday: 4)
        RoutineExercise(id: UUID(-1), routineID: push, exerciseID: bench, position: 0, isChainedToNext: true)
        PlannedSet(id: UUID(-1), routineExerciseID: UUID(-1), position: 0, reps: 10, kind: .warmup)
        PlannedSet(id: UUID(-2), routineExerciseID: UUID(-1), position: 1, reps: 8, weightKg: 80)
        PlannedSet(id: UUID(-3), routineExerciseID: UUID(-1), position: 2, reps: 6, weightKg: 90)
        RoutineExercise(id: UUID(-2), routineID: push, exerciseID: press, position: 1, setCount: 4)
    }
}

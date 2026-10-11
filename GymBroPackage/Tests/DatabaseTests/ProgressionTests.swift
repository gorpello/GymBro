import Dependencies
import Foundation
import Testing

@testable import Database

struct ProgressionTests {
    @Test func withNoHistoryAnExerciseOpensWithThreeSetsOfTenAtTwenty() {
        let sets = Progression.openingSets(lastSets: [])
        #expect(sets == Array(repeating: .init(reps: 10, weightKg: 20), count: 3))
    }

    @Test func lastWorkoutIsRepeated() {
        let sets = Progression.openingSets(lastSets: logged((8, 90), (8, 90), (6, 92.5)))
        #expect(sets == [.init(reps: 8, weightKg: 90), .init(reps: 8, weightKg: 90), .init(reps: 6, weightKg: 92.5)])
    }

    @Test func ownStepIsAddedOnlyWhenEverySetHitItsReps() {
        let easy = Progression.openingSets(lastSets: logged((8, 90), (8, 90)), progressStepKg: 2.5)
        #expect(easy.map(\.weightKg) == [92.5, 92.5])

        let hard = Progression.openingSets(lastSets: logged((8, 90), (6, 90)), progressStepKg: 2.5)
        #expect(hard.map(\.weightKg) == [90, 90])
    }

    @Test func setCountTrimsOrRepeatsTheLastSet() {
        let last = logged((8, 90), (6, 95))
        #expect(Progression.openingSets(setCount: 1, lastSets: last) == [.init(reps: 8, weightKg: 90)])
        #expect(
            Progression.openingSets(setCount: 3, lastSets: last)
                == [.init(reps: 8, weightKg: 90), .init(reps: 6, weightKg: 95), .init(reps: 6, weightKg: 95)]
        )
    }

    @Test func plannedSetsAreFilledInFromHistory() {
        let planned = [
            PlannedSet(id: UUID(1), routineExerciseID: UUID(0), kind: .warmup),
            PlannedSet(id: UUID(2), routineExerciseID: UUID(0), position: 1, reps: 5),
            PlannedSet(id: UUID(3), routineExerciseID: UUID(0), position: 2, weightKg: 80),
        ]
        let sets = Progression.openingSets(planned: planned, lastSets: logged((8, 90), (8, 90)))
        #expect(
            sets == [
                .init(reps: 10, weightKg: 45, kind: .warmup),
                .init(reps: 5, weightKg: 90),
                .init(reps: 8, weightKg: 80),
            ]
        )
    }

    @Test func warmUpsAreHalfTheWorkingWeightToTheNearestStep() {
        #expect(Progression.warmupWeightKg(for: 100) == 50)
        #expect(Progression.warmupWeightKg(for: 37) == 17.5)
        #expect(Progression.warmupWeightKg(for: 0) == 0)
    }

    @Test func nextTargetGoesUpOnlyWhenEverySetHitItsReps() {
        #expect(
            Progression.nextTarget(after: logged((8, 90), (8, 92.5)))
                == .init(weightKg: 95, reps: 8, isIncrease: true)
        )
        #expect(
            Progression.nextTarget(after: logged((8, 90), (7, 90)))
                == .init(weightKg: 90, reps: 8, isIncrease: false)
        )
        #expect(
            Progression.nextTarget(after: logged((12, 0), (12, 0)))
                == .init(weightKg: 0, reps: 13, isIncrease: true)
        )
        #expect(Progression.nextTarget(after: []) == nil)
    }
}

/// Completed working sets, `(reps, weightKg)` each.
private func logged(_ sets: (Int, Double)...) -> [WorkoutSet] {
    sets.enumerated().map { index, set in
        WorkoutSet(
            id: UUID(index),
            workoutExerciseID: UUID(0),
            position: index,
            reps: set.0,
            weightKg: set.1,
            isCompleted: true
        )
    }
}

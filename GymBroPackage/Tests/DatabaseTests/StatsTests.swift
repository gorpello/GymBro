import Foundation
import Testing

@testable import Database

/// Pure rules behind Home and Progress: records, muscle heat and recovery.
struct PersonalRecordTests {
    @Test func weightRecordsCompareEstimatedOneRepMaxes() throws {
        let record = try #require(
            PersonalRecord(sets: [
                set(day: 1, reps: 5, weightKg: 100),
                // Heavier, but a weaker set: the record date stays on day 1.
                set(day: 2, reps: 1, weightKg: 110),
                // Matching the best doesn't move the date either.
                set(day: 3, reps: 5, weightKg: 100),
            ])
        )
        #expect(record.kind == .weight)
        #expect(record.best == 110)
        #expect(record.oneRepMaxKg == 100 * (1 + 5.0 / 30))
        #expect(record.date == day(1))
    }

    @Test func bodyweightExercisesFallBackToReps() throws {
        let record = try #require(
            PersonalRecord(sets: [set(day: 1, reps: 12, weightKg: 0), set(day: 2, reps: 15, weightKg: 0)])
        )
        #expect(record.kind == .reps)
        #expect(record.best == 15)
        #expect(record.date == day(2))
    }

    @Test func nothingScoredIsNoRecord() {
        #expect(PersonalRecord(sets: [set(day: 1, reps: 0, weightKg: 0)]) == nil)
        #expect(PersonalRecord(sets: []) == nil)
    }

    @Test func recordsListWeightFirstThenByBest() {
        let records = PersonalRecord.records(from: [
            set("pushup", day: 1, reps: 20, weightKg: 0),
            set("curl", day: 1, reps: 10, weightKg: 15),
            set("squat", day: 1, reps: 5, weightKg: 120),
        ])
        #expect(records.map(\.exerciseID) == ["squat", "curl", "pushup"])
    }

    private func set(
        _ exerciseID: Exercise.ID = "bench", day: Int, reps: Int, weightKg: Double
    )
        -> PersonalRecord.LoggedSet
    {
        PersonalRecord.LoggedSet(
            exerciseID: exerciseID,
            workoutID: UUID(day),
            startedAt: self.day(day),
            reps: reps,
            weightKg: weightKg
        )
    }

    private func day(_ day: Int) -> Date {
        Date(timeIntervalSince1970: Double(day) * 86_400)
    }
}

struct MuscleLoadTests {
    let now = Date(timeIntervalSince1970: 1_000_000)

    @Test func secondaryMusclesCountHalf() {
        let sets = Array(repeating: trained(hoursAgo: 1, .chest, secondary: [.triceps]), count: 6)
        #expect(MuscleLoad.setCounts(sets) == [.chest: 6, .triceps: 3])
        // 12 sets a week fill the heat: 6 is half way, 3 a quarter.
        #expect(MuscleLoad.heatLevels(sets, days: 7) == [.chest: 3, .triceps: 2])
    }

    @Test func fatigueFadesWithEachMusclesRecoveryTime() {
        let sets = [trained(hoursAgo: 20, .chest), trained(hoursAgo: 20, .forearm)]
        let fatigue = MuscleLoad.fatigue(sets, at: now)

        #expect(fatigue[.chest] == exp(-20.0 / 20))
        #expect(fatigue[.forearm] == exp(-20.0 / 12))
    }

    @Test func effortFollowsRPEAndFailure() {
        let fatigue = { (set: MuscleLoad.TrainedSet) in MuscleLoad.fatigue([set], at: now)[.chest] ?? 0 }

        #expect(fatigue(trained(hoursAgo: 0, .chest)) == 1)
        #expect(fatigue(trained(hoursAgo: 0, .chest, kind: .failure)) == 1.2)
        #expect(fatigue(trained(hoursAgo: 0, .chest, rpe: 7)) == 0.5)
        #expect(fatigue(trained(hoursAgo: 0, .chest, rpe: 10)) == 1.25)
        #expect(fatigue(trained(hoursAgo: 0, .chest, rpe: 6)) == 0.4)
    }

    @Test func oldAndFutureSetsAreIgnored() {
        let sets = [trained(hoursAgo: 24 * 8 + 1, .chest), trained(hoursAgo: -1, .chest)]
        #expect(MuscleLoad.fatigue(sets, at: now).isEmpty)
    }

    @Test func recoveryCoversEveryMuscle() {
        let sets = Array(repeating: trained(hoursAgo: 0, .chest), count: 4)
        let recovery = MuscleLoad.recovery(sets, at: now)

        #expect(recovery.count == Muscle.all.count)
        #expect(recovery[.chest] == 0.5)
        #expect(recovery[.back] == 1)
        // One muscle half tired out of thirteen.
        #expect(MuscleLoad.overallRecovery(recovery) == 96)
    }

    private func trained(
        hoursAgo: Double,
        _ primary: Muscle,
        secondary: [Muscle] = [],
        kind: SetKind = .normal,
        rpe: Double? = nil
    ) -> MuscleLoad.TrainedSet {
        let finishedAt = now.addingTimeInterval(-hoursAgo * 3_600)
        return MuscleLoad.TrainedSet(
            startedAt: finishedAt.addingTimeInterval(-3_600),
            finishedAt: finishedAt,
            primaryMuscle: primary,
            secondaryMuscles: secondary,
            kind: kind,
            rpe: rpe
        )
    }
}

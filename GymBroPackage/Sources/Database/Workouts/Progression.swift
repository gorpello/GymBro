import Foundation

/// How a workout picks its first numbers from history: the sets a new workout opens with, and the
/// target shown as "Next time". Pure functions, ported from GymMane's `WorkoutState`.
public enum Progression {
    /// Sets an exercise starts with when nothing else is known.
    public static let defaultSetCount = 3
    public static let defaultReps = 10
    public static let defaultWeightKg = 20.0
    /// Weight added when an exercise gets easy, unless the exercise has its own step.
    public static let defaultStepKg = 2.5

    /// A set a new workout opens with.
    public struct Opening: Equatable, Sendable {
        public var reps: Int
        public var weightKg: Double
        public var kind: SetKind

        public init(reps: Int, weightKg: Double, kind: SetKind = .normal) {
            self.reps = reps
            self.weightKg = weightKg
            self.kind = kind
        }
    }

    /// The sets an exercise opens with.
    ///
    /// - A routine's planned sets win; any reps or weight they leave empty come from the working
    ///   sets below, and planned warm-ups default to 10 reps at half the first working weight.
    /// - Otherwise the last workout's working sets are repeated, `progressStepKg` heavier when every
    ///   set hit the first set's reps.
    /// - With no history, `setCount` (or 3) sets of 10 × 20 kg.
    ///
    /// - Parameters:
    ///   - planned: The routine's planned sets for the exercise, in order; empty when not planned.
    ///   - setCount: How many working sets to open with, when nothing is planned; `nil` keeps as
    ///     many as last time.
    ///   - lastSets: Working sets of the last finished workout with this exercise, in order.
    ///   - progressStepKg: The exercise's own progression step; `nil` repeats the last weights.
    public static func openingSets(
        planned: [PlannedSet] = [],
        setCount: Int? = nil,
        lastSets: [WorkoutSet],
        progressStepKg: Double? = nil
    ) -> [Opening] {
        guard !planned.isEmpty else {
            let count = setCount ?? (lastSets.isEmpty ? defaultSetCount : lastSets.count)
            return workingSets(count: count, lastSets: lastSets, progressStepKg: progressStepKg)
        }
        let plannedWorking = planned.count { $0.kind != .warmup }
        let working = workingSets(
            count: max(plannedWorking, 1),
            lastSets: lastSets,
            progressStepKg: progressStepKg
        )
        let first = working[0]
        var next = 0
        return planned.map { plannedSet in
            if plannedSet.kind == .warmup {
                return Opening(
                    reps: plannedSet.reps ?? defaultReps,
                    weightKg: plannedSet.weightKg ?? warmupWeightKg(for: first.weightKg),
                    kind: .warmup
                )
            }
            let base = working[min(next, working.count - 1)]
            next += 1
            return Opening(
                reps: plannedSet.reps ?? base.reps,
                weightKg: plannedSet.weightKg ?? base.weightKg,
                kind: plannedSet.kind
            )
        }
    }

    /// Half the working weight, to the nearest 2.5 kg.
    public static func warmupWeightKg(for workingWeightKg: Double) -> Double {
        (workingWeightKg * 0.5 / defaultStepKg).rounded() * defaultStepKg
    }

    /// What to aim for next time, after `lastSets` (working sets, in order). When every set hit the
    /// first set's reps the target goes up: by `stepKg` on the heaviest weight, or by one rep for
    /// bodyweight work. Otherwise it repeats.
    public static func nextTarget(after lastSets: [WorkoutSet], stepKg: Double = defaultStepKg) -> Target? {
        guard let reps = lastSets.first?.reps, reps > 0 else { return nil }
        let isHit = lastSets.allSatisfy { $0.reps >= reps }
        let topWeightKg = lastSets.map(\.weightKg).max() ?? 0
        guard topWeightKg > 0 else {
            return Target(weightKg: 0, reps: isHit ? reps + 1 : reps, isIncrease: isHit)
        }
        return Target(weightKg: isHit ? topWeightKg + stepKg : topWeightKg, reps: reps, isIncrease: isHit)
    }

    public struct Target: Equatable, Sendable {
        public var weightKg: Double
        public var reps: Int
        /// Heavier or more reps than last time.
        public var isIncrease: Bool
    }

    private static func workingSets(count: Int, lastSets: [WorkoutSet], progressStepKg: Double?) -> [Opening] {
        let base: [Opening]
        if lastSets.isEmpty {
            base = [Opening(reps: defaultReps, weightKg: defaultWeightKg)]
        } else {
            let firstReps = lastSets[0].reps
            let isHit = lastSets.allSatisfy { $0.reps >= firstReps }
            let bump = isHit ? progressStepKg ?? 0 : 0
            base = lastSets.map { Opening(reps: $0.reps, weightKg: $0.weightKg + bump) }
        }
        let count = max(count, 1)
        if count <= base.count { return Array(base.prefix(count)) }
        return base + Array(repeating: base[base.count - 1], count: count - base.count)
    }
}

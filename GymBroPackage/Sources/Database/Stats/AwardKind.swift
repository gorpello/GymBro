/// The 20 medals, easiest first. The raw value is the `Award` row id and the artwork name under
/// `Badges/`, so it must never change once shipped.
public enum AwardKind: String, CaseIterable, Sendable {
    case firstStep
    case firstWorkout
    case firstRoutine
    case firstRecord
    case streak3
    case streak7
    case workouts10
    case tonne1
    case sets100
    case hours10
    case workouts50
    case tonnes10
    case hours50
    case streak30
    case sets1000
    case workouts100
    case hours100
    case streak100
    case tonnes100
    case workouts365

    /// What a medal counts.
    public enum Metric: Sendable {
        case onboarding, routines, records, streak, workouts, sets, volumeKg, hours
    }

    public var metric: Metric {
        switch self {
        case .firstStep: .onboarding
        case .firstRoutine: .routines
        case .firstRecord: .records
        case .streak3, .streak7, .streak30, .streak100: .streak
        case .firstWorkout, .workouts10, .workouts50, .workouts100, .workouts365: .workouts
        case .sets100, .sets1000: .sets
        case .tonne1, .tonnes10, .tonnes100: .volumeKg
        case .hours10, .hours50, .hours100: .hours
        }
    }

    /// The value of `metric` that earns the medal.
    public var goal: Int {
        switch self {
        case .firstStep, .firstWorkout, .firstRoutine, .firstRecord: 1
        case .streak3: 3
        case .streak7: 7
        case .streak30: 30
        case .streak100: 100
        case .workouts10, .hours10: 10
        case .workouts50, .hours50: 50
        case .workouts100, .hours100, .sets100: 100
        case .workouts365: 365
        case .sets1000, .tonne1: 1_000
        case .tonnes10: 10_000
        case .tonnes100: 100_000
        }
    }
}

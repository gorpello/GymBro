import Database
import L10n

/// Display text for medals, shared by Awards and the Profile medal shelf.
extension AwardKind {
    public var name: String {
        switch self {
        case .firstStep: L10n.awardFirstStepName
        case .firstWorkout: L10n.awardFirstWorkoutName
        case .firstRoutine: L10n.awardFirstRoutineName
        case .firstRecord: L10n.awardFirstRecordName
        case .streak3: L10n.awardStreak3Name
        case .streak7: L10n.awardStreak7Name
        case .workouts10: L10n.awardWorkouts10Name
        case .tonne1: L10n.awardTonne1Name
        case .sets100: L10n.awardSets100Name
        case .hours10: L10n.awardHours10Name
        case .workouts50: L10n.awardWorkouts50Name
        case .tonnes10: L10n.awardTonnes10Name
        case .hours50: L10n.awardHours50Name
        case .streak30: L10n.awardStreak30Name
        case .sets1000: L10n.awardSets1000Name
        case .workouts100: L10n.awardWorkouts100Name
        case .hours100: L10n.awardHours100Name
        case .streak100: L10n.awardStreak100Name
        case .tonnes100: L10n.awardTonnes100Name
        case .workouts365: L10n.awardWorkouts365Name
        }
    }

    /// What it takes to earn the medal.
    public var line: String {
        switch self {
        case .firstStep: L10n.awardFirstStepLine
        case .firstWorkout: L10n.awardFirstWorkoutLine
        case .firstRoutine: L10n.awardFirstRoutineLine
        case .firstRecord: L10n.awardFirstRecordLine
        case .streak3: L10n.awardStreak3Line
        case .streak7: L10n.awardStreak7Line
        case .workouts10: L10n.awardWorkouts10Line
        case .tonne1: L10n.awardTonne1Line
        case .sets100: L10n.awardSets100Line
        case .hours10: L10n.awardHours10Line
        case .workouts50: L10n.awardWorkouts50Line
        case .tonnes10: L10n.awardTonnes10Line
        case .hours50: L10n.awardHours50Line
        case .streak30: L10n.awardStreak30Line
        case .sets1000: L10n.awardSets1000Line
        case .workouts100: L10n.awardWorkouts100Line
        case .hours100: L10n.awardHours100Line
        case .streak100: L10n.awardStreak100Line
        case .tonnes100: L10n.awardTonnes100Line
        case .workouts365: L10n.awardWorkouts365Line
        }
    }
}

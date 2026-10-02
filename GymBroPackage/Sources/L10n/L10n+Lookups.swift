import Foundation

/// Id → label lookups, ported from the helper methods in GymMane's `l10n.dart`.
extension L10n {
    public static func muscle(_ id: String) -> String {
        switch id {
        case "chest": muscleChest
        case "back": muscleBack
        case "shoulders": muscleShoulders
        case "biceps": muscleBiceps
        case "triceps": muscleTriceps
        case "forearm": muscleForearm
        case "trapezius": muscleTrapezius
        case "abdomen": muscleAbdomen
        case "obliques": muscleObliques
        case "quads": muscleQuads
        case "hamstrings": muscleHamstrings
        case "glutes": muscleGlutes
        case "calves": muscleCalves
        default: id
        }
    }
    
    public static func equipment(_ id: String) -> String {
        switch id {
        case "Barbell": equipBarbell
        case "Dumbbell": equipDumbbell
        case "Cable": equipCable
        case "Machine": equipMachine
        case "Bodyweight": equipBodyweight
        case "Weighted": equipWeighted
        case "Band": equipBand
        case "Kettlebell": equipKettlebell
        case "Rings": equipRings
        default: equipOther
        }
    }
    
    public static func difficulty(_ id: String) -> String {
        switch id {
        case "Beginner": diffBeginner
        case "Advanced": diffAdvanced
        default: diffIntermediate
        }
    }
    
    public static func toolName(_ id: String) -> String {
        switch id {
        case "rm": toolNameRm
        case "bmi": toolNameBmi
        case "cal": toolNameCal
        case "bf": toolNameBf
        case "plate": toolNamePlate
        default: toolNameWarmup
        }
    }
    
    public static func toolDesc(_ id: String) -> String {
        switch id {
        case "rm": toolDescRm
        case "bmi": toolDescBmi
        case "cal": toolDescCal
        case "bf": toolDescBf
        case "plate": toolDescPlate
        default: toolDescWarmup
        }
    }
    
    public static func activityName(_ key: String) -> String {
        switch key {
        case "Sedentary": actSedentary
        case "Light": actLight
        case "Active": actActive
        default: actModerate
        }
    }
    
    public static func poseName(_ pose: String) -> String {
        switch pose {
        case "front": poseFront
        case "side": poseSide
        default: poseBack
        }
    }
    
    public static func placePresetName(_ preset: String) -> String {
        switch preset {
        case "gym": placeGym
        case "home": placeHome
        default: placeOutdoors
        }
    }
    
    public static func measureName(_ key: String) -> String {
        switch key {
        case "neck": measureNeck
        case "shoulders": measureShoulders
        case "chest": measureChest
        case "arm": measureArm
        case "forearm": measureForearm
        case "waist": measureWaist
        case "hips": measureHips
        case "thigh": measureThigh
        case "calf": measureCalf
        default: measureBodyfat
        }
    }
    
    /// Journal note kinds: `note`, `plan`, `done` (a win) and `pain` (a niggle).
    public static func noteKind(_ kind: String) -> String {
        switch kind {
        case "plan": noteKindPlan
        case "done": noteKindDone
        case "pain": noteKindPain
        default: noteKindNote
        }
    }
    
    /// One-letter weekday names, Monday first.
    public static var weekdayInitials: [String] {
        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
        return Array(symbols[1...] + symbols[..<1])
    }
    
    /// Short weekday names, Monday first.
    public static var weekdayShortNames: [String] {
        let symbols = Calendar.current.shortStandaloneWeekdaySymbols
        return Array(symbols[1...] + symbols[..<1])
    }
}

import SQLiteData

// Closed sets of values stored as text. Raw-representable structs (not enums) so a row written by
// a newer app version with a value this version doesn't know still decodes.
// Never change a raw value once it has shipped.

/// One of the 13 muscles on the body map.
public struct Muscle: Codable, Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public init(from decoder: any Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
    
    public static let abdomen = Self(rawValue: "abdomen")
    public static let back = Self(rawValue: "back")
    public static let biceps = Self(rawValue: "biceps")
    public static let calves = Self(rawValue: "calves")
    public static let chest = Self(rawValue: "chest")
    public static let forearm = Self(rawValue: "forearm")
    public static let glutes = Self(rawValue: "glutes")
    public static let hamstrings = Self(rawValue: "hamstrings")
    public static let obliques = Self(rawValue: "obliques")
    public static let quads = Self(rawValue: "quads")
    public static let shoulders = Self(rawValue: "shoulders")
    public static let trapezius = Self(rawValue: "trapezius")
    public static let triceps = Self(rawValue: "triceps")
}

public struct Equipment: Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public static let band = Self(rawValue: "Band")
    public static let barbell = Self(rawValue: "Barbell")
    public static let bodyweight = Self(rawValue: "Bodyweight")
    public static let cable = Self(rawValue: "Cable")
    public static let dumbbell = Self(rawValue: "Dumbbell")
    public static let kettlebell = Self(rawValue: "Kettlebell")
    public static let machine = Self(rawValue: "Machine")
    public static let other = Self(rawValue: "Other")
    public static let rings = Self(rawValue: "Rings")
    public static let weighted = Self(rawValue: "Weighted")
}

public struct Difficulty: Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public static let beginner = Self(rawValue: "Beginner")
    public static let intermediate = Self(rawValue: "Intermediate")
    public static let advanced = Self(rawValue: "Advanced")
}

/// How an exercise is logged: weight × reps, distance and time, or time only.
public struct ExerciseMode: Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public static let weight = Self(rawValue: "weight")
    public static let cardio = Self(rawValue: "cardio")
    public static let time = Self(rawValue: "time")
}

public struct SetKind: Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public static let normal = Self(rawValue: "normal")
    public static let warmup = Self(rawValue: "warmup")
    public static let drop = Self(rawValue: "drop")
    public static let failure = Self(rawValue: "failure")
    public static let restPause = Self(rawValue: "restPause")
    
    /// Warm-up sets don't count toward volume, set totals or PRs.
    public var counts: Bool { self != .warmup }
}

public struct NoteKind: Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public static let note = Self(rawValue: "note")
    public static let plan = Self(rawValue: "plan")
    public static let done = Self(rawValue: "done")
    public static let pain = Self(rawValue: "pain")
}

public struct MeasurementKind: Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    /// Kilograms.
    public static let bodyweight = Self(rawValue: "bodyweight")
    /// Percent.
    public static let bodyFat = Self(rawValue: "bodyFat")
    // Circumferences, in centimetres.
    public static let neck = Self(rawValue: "neck")
    public static let shoulders = Self(rawValue: "shoulders")
    public static let chest = Self(rawValue: "chest")
    public static let arm = Self(rawValue: "arm")
    public static let forearm = Self(rawValue: "forearm")
    public static let waist = Self(rawValue: "waist")
    public static let hips = Self(rawValue: "hips")
    public static let thigh = Self(rawValue: "thigh")
    public static let calf = Self(rawValue: "calf")
}

public struct Sex: Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public static let male = Self(rawValue: "male")
    public static let female = Self(rawValue: "female")
}

// MARK: - Settings

/// The app's colour scheme; `system` follows the device.
public struct ThemePreference: Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public static let system = Self(rawValue: "system")
    public static let dark = Self(rawValue: "dark")
    public static let light = Self(rawValue: "light")
}

/// Weights are always stored in kilograms; this only changes how they're shown and entered.
public struct WeightUnit: Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public static let kg = Self(rawValue: "kg")
    public static let lb = Self(rawValue: "lb")
}

/// How effort is logged per set: rate of perceived exertion, reps in reserve, or not at all.
public struct EffortScale: Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public static let off = Self(rawValue: "off")
    public static let rpe = Self(rawValue: "rpe")
    public static let rir = Self(rawValue: "rir")
}

/// Size of the exercise demo animation during a workout.
public struct DemoSize: Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public static let large = Self(rawValue: "large")
    public static let small = Self(rawValue: "small")
    public static let off = Self(rawValue: "off")
}

/// `loud` always plays, `quiet` follows silent mode, `vibrate` never makes a sound.
public struct AlarmStyle: Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public static let loud = Self(rawValue: "loud")
    public static let quiet = Self(rawValue: "quiet")
    public static let vibrate = Self(rawValue: "vibrate")
}

public struct BackgroundPattern: Hashable, QueryBindable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    
    public static let dots = Self(rawValue: "dots")
    public static let grid = Self(rawValue: "grid")
    /// Raw value kept from GymMane; not `.none`, which would clash with `Optional.none`.
    public static let plain = Self(rawValue: "none")
}

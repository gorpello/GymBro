import Database
import Foundation
import L10n

/// How the exercise screen writes its numbers; the unit conversions live in `UnitFormat`.
enum ExerciseFormat {
    /// "92.5 kg × 8", or "12 reps" for bodyweight work.
    static func target(_ target: Progression.Target, units: WeightUnit, locale: Locale = .current) -> String {
        guard target.weightKg > 0 else { return L10n.repCount(target.reps) }
        return "\(UnitFormat.weightLabel(target.weightKg, units: units, locale: locale)) × \(target.reps)"
    }

    static func record(_ record: PersonalRecord, units: WeightUnit, locale: Locale = .current) -> String {
        UnitFormat.record(record, units: units, locale: locale, reps: L10n.repCount)
    }

    /// Volume with its unit, "2.6 t".
    static func volume(_ kg: Double, units: WeightUnit, locale: Locale = .current) -> String {
        let (value, unit) = UnitFormat.volume(kg, units: units, locale: locale)
        return "\(value) \(unit)"
    }

    /// Rest between sets: "Off", or seconds such as "150s".
    static func rest(_ seconds: Int) -> String {
        seconds == 0 ? L10n.restOff : "\(seconds)s"
    }
}

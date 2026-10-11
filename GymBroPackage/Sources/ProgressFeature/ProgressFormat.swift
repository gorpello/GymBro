import Database
import Foundation
import L10n

/// How Progress writes its numbers. Pure functions, so the rules are unit-tested; the unit
/// conversions themselves live in `UnitFormat`.
enum ProgressFormat {
    static let centimetresPerInch = 2.54

    static func volume(_ kg: Double, units: WeightUnit, locale: Locale = .current) -> (value: String, unit: String) {
        UnitFormat.volume(kg, units: units, locale: locale)
    }

    /// A weight in the user's unit to one decimal, without the unit.
    static func weight(_ kg: Double, units: WeightUnit, locale: Locale = .current) -> String {
        UnitFormat.weight(kg, units: units, locale: locale)
    }

    /// Size of a change, "16%"; the trend arrow shows its direction.
    static func change(_ percent: Int) -> String {
        "\(abs(percent))%"
    }

    /// Body fat in percent; circumferences in centimetres, or inches for pound users.
    static func measure(
        _ measurement: BodyMeasurement,
        units: WeightUnit,
        locale: Locale = .current
    ) -> (value: String, unit: String) {
        if measurement.kind == .bodyFat {
            return (UnitFormat.decimal(measurement.value, digits: 1, locale: locale), "%")
        }
        return units == .kg
            ? (UnitFormat.decimal(measurement.value, digits: 1, locale: locale), "cm")
            : (UnitFormat.decimal(measurement.value / centimetresPerInch, digits: 1, locale: locale), "in")
    }

    /// A record in its own measure: weight, distance, time or reps.
    static func record(_ record: PersonalRecord, units: WeightUnit, locale: Locale = .current) -> String {
        UnitFormat.record(record, units: units, locale: locale, reps: L10n.repCount)
    }

    /// "Sep 19".
    static func shortDate(_ date: Date, calendar: Calendar = .current, locale: Locale = .current) -> String {
        UnitFormat.shortDate(date, calendar: calendar, locale: locale)
    }

    /// Whole hours trained.
    static func hours(_ seconds: Int) -> String {
        "\(seconds / 3_600)"
    }
}

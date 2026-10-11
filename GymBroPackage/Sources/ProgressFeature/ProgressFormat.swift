import Database
import Foundation
import L10n

/// How Progress writes its numbers. Pure functions, so the rules are unit-tested.
enum ProgressFormat {
    static let centimetresPerInch = 2.54
    static let kilometresPerMile = 1.609344

    /// Volume in tonnes, or thousands of pounds, to one decimal.
    static func volume(_ kg: Double, units: WeightUnit, locale: Locale = .current) -> (value: String, unit: String) {
        let thousands = units.value(fromKilograms: kg) / 1_000
        return (decimal(thousands, digits: 1, locale: locale), units == .kg ? "t" : "k \(units.rawValue)")
    }

    /// A weight in the user's unit to one decimal, without the unit.
    static func weight(_ kg: Double, units: WeightUnit, locale: Locale = .current) -> String {
        decimal(units.value(fromKilograms: kg), digits: 1, locale: locale)
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
            return (decimal(measurement.value, digits: 1, locale: locale), "%")
        }
        return units == .kg
            ? (decimal(measurement.value, digits: 1, locale: locale), "cm")
            : (decimal(measurement.value / centimetresPerInch, digits: 1, locale: locale), "in")
    }

    /// A record in its own measure: weight, distance, time or reps.
    static func record(_ record: PersonalRecord, units: WeightUnit, locale: Locale = .current) -> String {
        switch record.kind {
        case .weight:
            return "\(weight(record.best, units: units, locale: locale)) \(units.rawValue)"
        case .distance:
            let (value, unit) = units == .kg ? (record.best, "km") : (record.best / kilometresPerMile, "mi")
            return "\(decimal(value, digits: 2, locale: locale)) \(unit)"
        case .time:
            let seconds = Int(record.best.rounded())
            let (hours, minutes, rest) = (seconds / 3_600, seconds / 60 % 60, seconds % 60)
            return hours > 0
                ? String(format: "%d:%02d:%02d", hours, minutes, rest)
                : String(format: "%d:%02d", minutes, rest)
        case .reps:
            return L10n.repCount(Int(record.best.rounded()))
        }
    }

    /// "Sep 19".
    static func shortDate(_ date: Date, calendar: Calendar = .current, locale: Locale = .current) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .omitted, locale: locale, calendar: calendar)
            .month(.abbreviated)
            .day()
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    /// Whole hours trained.
    static func hours(_ seconds: Int) -> String {
        "\(seconds / 3_600)"
    }

    private static func decimal(_ value: Double, digits: Int, locale: Locale) -> String {
        value.formatted(.number.precision(.fractionLength(0...digits)).locale(locale))
    }
}

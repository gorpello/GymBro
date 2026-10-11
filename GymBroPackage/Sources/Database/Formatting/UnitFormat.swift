import Foundation

/// Numbers in the user's units, shared by every screen that shows weights, volume, distance or
/// time. Labels that need translating (such as "12 reps") stay in the features.
public enum UnitFormat {
    public static let kilometresPerMile = 1.609344

    /// A weight to one decimal, without the unit: "92.5".
    public static func weight(_ kg: Double, units: WeightUnit, locale: Locale = .current) -> String {
        decimal(units.value(fromKilograms: kg), digits: 1, locale: locale)
    }

    /// A weight with its unit: "92.5 kg".
    public static func weightLabel(_ kg: Double, units: WeightUnit, locale: Locale = .current) -> String {
        "\(weight(kg, units: units, locale: locale)) \(units.rawValue)"
    }

    /// Volume in tonnes, or thousands of pounds, to one decimal.
    public static func volume(
        _ kg: Double,
        units: WeightUnit,
        locale: Locale = .current
    ) -> (value: String, unit: String) {
        let thousands = units.value(fromKilograms: kg) / 1_000
        return (decimal(thousands, digits: 1, locale: locale), units == .kg ? "t" : "k \(units.rawValue)")
    }

    /// Distance in kilometres, or miles for pound users, to two decimals: "5.25 km".
    public static func distanceLabel(_ km: Double, units: WeightUnit, locale: Locale = .current) -> String {
        let (value, unit) = units == .kg ? (km, "km") : (km / kilometresPerMile, "mi")
        return "\(decimal(value, digits: 2, locale: locale)) \(unit)"
    }

    /// A record in its own measure: weight, distance, time or reps.
    ///
    /// - Parameter reps: The translated reps label, e.g. "12 reps".
    public static func record(
        _ record: PersonalRecord,
        units: WeightUnit,
        locale: Locale = .current,
        reps: (Int) -> String
    ) -> String {
        switch record.kind {
        case .weight: weightLabel(record.best, units: units, locale: locale)
        case .distance: distanceLabel(record.best, units: units, locale: locale)
        case .time: clock(Int(record.best.rounded()))
        case .reps: reps(Int(record.best.rounded()))
        }
    }

    /// "4:05", or "1:02:09" past an hour.
    public static func clock(_ seconds: Int) -> String {
        let seconds = max(seconds, 0)
        let (hours, minutes, rest) = (seconds / 3_600, seconds / 60 % 60, seconds % 60)
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, rest)
            : String(format: "%d:%02d", minutes, rest)
    }

    /// "Sep 19".
    public static func shortDate(_ date: Date, calendar: Calendar = .current, locale: Locale = .current) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .omitted, locale: locale, calendar: calendar)
            .month(.abbreviated)
            .day()
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    public static func decimal(_ value: Double, digits: Int, locale: Locale = .current) -> String {
        value.formatted(.number.precision(.fractionLength(0...digits)).locale(locale))
    }
}

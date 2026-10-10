import Database
import Foundation
import L10n

/// How Profile writes its numbers. Pure functions, so the rules are unit-tested.
enum ProfileFormat {
    /// Lifetime volume: whole kilograms or pounds below a thousand, then tonnes (`t`) or
    /// thousands of pounds (`k lb`), with one decimal below ten.
    static func lifted(kg: Double, units: WeightUnit, locale: Locale = .current) -> (value: String, unit: String) {
        let shown = units.value(fromKilograms: kg)
        guard shown >= 1_000 else {
            return (shown.rounded().formatted(.number.precision(.fractionLength(0)).locale(locale)), units.rawValue)
        }
        let thousands = shown / 1_000
        let digits = thousands >= 10 ? 0 : 1
        let value = thousands.formatted(.number.precision(.fractionLength(0...digits)).locale(locale))
        return (value, units == .kg ? "t" : "k \(units.rawValue)")
    }

    /// Time trained: hours under two days, whole days after that.
    static func trained(seconds: Int) -> (value: String, unit: String) {
        let hours = seconds / 3_600
        return hours < 48 ? ("\(hours)", L10n.unitHours) : ("\(hours / 24)", L10n.unitDays)
    }

    /// Body weight in the user's unit, to one decimal, e.g. "78.5 kg".
    static func weight(kg: Double, units: WeightUnit, locale: Locale = .current) -> String {
        let value = units.value(fromKilograms: kg).formatted(.number.precision(.fractionLength(0...1)).locale(locale))
        return "\(value) \(units.rawValue)"
    }
}

import Database
import Foundation
import L10n

/// How the session writes its numbers. Weights are stored in kilograms and shown in the user's
/// unit. Pure functions, so the rules are unit-tested.
enum SessionFormat {
    /// "4:05", or "1:02:09" past the hour.
    static func clock(_ seconds: Int) -> String {
        let seconds = max(seconds, 0)
        let (hours, minutes, rest) = (seconds / 3_600, seconds / 60 % 60, seconds % 60)
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, rest)
            : String(format: "%d:%02d", minutes, rest)
    }

    /// "58 min", rounded down.
    static func duration(_ seconds: Int) -> String {
        "\(max(seconds, 0) / 60) min"
    }

    /// A weight in the user's unit, to one decimal: "92.5".
    static func weight(_ kg: Double, units: WeightUnit, locale: Locale = .current) -> String {
        units.value(fromKilograms: kg).formatted(.number.precision(.fractionLength(0...1)).locale(locale))
    }

    /// Last time's sets, "90×8 · 90×8 · 92.5×6"; bodyweight sets show reps only. `nil` the first time.
    static func sets(_ sets: [WorkoutSet], units: WeightUnit, locale: Locale = .current) -> String? {
        guard !sets.isEmpty else { return nil }
        return
            sets
            .map { $0.weightKg > 0 ? "\(weight($0.weightKg, units: units, locale: locale))×\($0.reps)" : "\($0.reps)" }
            .joined(separator: " · ")
    }

    /// The next target, "92.5 kg × 8", or "12 reps" for bodyweight work.
    static func target(_ target: Progression.Target, units: WeightUnit, locale: Locale = .current) -> String {
        guard target.weightKg > 0 else { return "\(target.reps) \(L10n.repsCol.lowercased())" }
        return "\(weight(target.weightKg, units: units, locale: locale)) \(units.rawValue) × \(target.reps)"
    }

    /// Volume as tonnes (`t`) or thousands of pounds (`k lb`): ("8.4", "t").
    static func volume(_ kg: Double, units: WeightUnit, locale: Locale = .current) -> (value: String, unit: String) {
        let thousands = units.value(fromKilograms: kg) / 1_000
        let value = thousands.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
        return (value, units == .kg ? "t" : "k \(units.rawValue)")
    }

    /// Volume against last time, "+12%" or "−5%"; `nil` the first time or when last time was empty.
    static func change(from previousKg: Double?, to currentKg: Double) -> String? {
        guard let previousKg, previousKg > 0 else { return nil }
        let percent = Int(((currentKg - previousKg) / previousKg * 100).rounded())
        return percent >= 0 ? "+\(percent)%" : "−\(-percent)%"
    }
}

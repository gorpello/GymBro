import Foundation
import Testing

@testable import Database
@testable import ProgressFeature

struct ProgressFormatTests {
    let english = Locale(identifier: "en_US")

    @Test func volume() {
        #expect(ProgressFormat.volume(98_400, units: .kg, locale: english) == ("98.4", "t"))
        #expect(ProgressFormat.volume(1_000, units: .lb, locale: english) == ("2.2", "k lb"))
    }

    @Test func weightAndChange() {
        #expect(ProgressFormat.weight(81.44, units: .kg, locale: english) == "81.4")
        #expect(ProgressFormat.weight(100, units: .lb, locale: english) == "220.5")
        #expect(ProgressFormat.change(16) == "16%")
        #expect(ProgressFormat.change(-5) == "5%")
    }

    @Test func measuresFollowTheWeightUnit() {
        let waist = BodyMeasurement(id: UUID(0), kind: .waist, value: 81.28)
        let bodyFat = BodyMeasurement(id: UUID(1), kind: .bodyFat, value: 14)
        #expect(ProgressFormat.measure(waist, units: .kg, locale: english) == ("81.3", "cm"))
        #expect(ProgressFormat.measure(waist, units: .lb, locale: english) == ("32", "in"))
        #expect(ProgressFormat.measure(bodyFat, units: .lb, locale: english) == ("14", "%"))
    }

    @Test func recordsInTheirOwnMeasure() {
        let record = { (kind: PersonalRecord.Kind, best: Double) in
            PersonalRecord(exerciseID: "x", kind: kind, best: best, oneRepMaxKg: 0, date: Date())
        }
        #expect(ProgressFormat.record(record(.weight, 92.5), units: .kg, locale: english) == "92.5 kg")
        #expect(ProgressFormat.record(record(.distance, 5), units: .kg, locale: english) == "5 km")
        #expect(ProgressFormat.record(record(.time, 245), units: .kg, locale: english) == "4:05")
    }

    @Test func shortDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 19))!
        #expect(ProgressFormat.shortDate(date, calendar: calendar, locale: english) == "Sep 19")
    }
}

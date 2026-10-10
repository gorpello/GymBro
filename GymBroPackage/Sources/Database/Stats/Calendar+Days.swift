import Foundation

extension Calendar {
    /// 0 = Monday … 6 = Sunday, whatever the calendar's first weekday.
    public func mondayIndex(of date: Date) -> Int {
        (component(.weekday, from: date) + 5) % 7
    }

    /// `date` moved by whole calendar days, so daylight-saving changes don't shift it.
    public func day(byAdding days: Int, to date: Date) -> Date {
        self.date(byAdding: .day, value: days, to: date) ?? date
    }
}

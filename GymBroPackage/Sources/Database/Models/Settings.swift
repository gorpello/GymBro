import Foundation
import SQLiteData

/// App-wide preferences. Like `UserProfile` there's a single row, always with
/// `AppSettings.singletonID`; until the user changes something there may be no row at all, so
/// read it with `?? AppSettings()`.
@Table("appSettings")
public struct AppSettings: Hashable, Identifiable, Sendable {
    public static let singletonID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    public let id: UUID
    public var theme: ThemePreference = .dark
    public var units: WeightUnit = .kg
    /// First day of the week, 1 = Monday … 7 = Sunday. GymMane offers Monday, Saturday and Sunday.
    public var weekStart = 1
    public var heatmapLabels = true
    public var background: BackgroundPattern = .dots

    /// Default rest between sets, 0 (off) … 600, in steps of 15.
    public var restSeconds = 90
    public var effort: EffortScale = .off
    public var autoAdvance = true
    public var countdown = true
    public var keepScreenOn = true
    public var multiPlan = false
    public var levelHints = true
    public var demoSize: DemoSize = .large

    /// Daily training reminder, in minutes after midnight; `nil` when off.
    public var trainReminderMinutes: Int?
    /// File name of a custom rest alarm; `nil` plays the bundled one.
    public var alarmSound: String?
    public var alarmSoundName: String?
    public var alarmStyle: AlarmStyle = .quiet

    public var focusCard = true
    public var homeRecommended = true
    public var gamification = true
}

extension AppSettings {
    /// The defaults, for the singleton row.
    public init() {
        self.init(id: Self.singletonID)
    }

    /// Rest timer bounds and step, in seconds.
    public static let restRange = 0...600
    public static let restStep = 15
}

import Foundation
import SQLiteData

/// A medal the user has earned. The id is the award's identifier, e.g. `"firstWorkout"`.
@Table
public struct Award: Hashable, Identifiable, Sendable {
    public let id: String
    public var earnedAt = Date()
    public var isSeen = false
}

/// The user's profile. There's a single row, always with `UserProfile.singletonID`, so every
/// device (and iCloud sync later) agrees on which record it is.
@Table
public struct UserProfile: Hashable, Identifiable, Sendable {
    public static let singletonID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    public let id: UUID
    public var name = ""
    public var handle = ""
    public var sex: Sex = .male
    public var age = 28
    public var heightCm = 175.0
    public var weightKg = 75.0
    /// Activity multiplier for calorie estimates, 1.2…1.9.
    public var activityFactor = 1.55
    public var weeklyGoal = 4
    public var photoFile: String?
    public var bannerFile: String?
    /// Colour of the verified badge next to the name.
    public var badge = "blue"
    public var memberSince: Date?
}

extension UserProfile {
    /// The defaults, for the singleton row.
    public init() {
        self.init(id: Self.singletonID)
    }

    public static let ageRange = 10...90
    public static let heightRangeCm = 100.0...250
    public static let weightRangeKg = 30.0...250
    public static let weeklyGoalRange = 1...14

    /// Activity multipliers offered in the profile: sedentary, light, moderate and active.
    public static let activityFactors = [1.2, 1.375, 1.55, 1.725]

    /// A handle keeps only letters, digits, `_` and `.`, so it can follow an `@`.
    public static func sanitizedHandle(_ handle: String) -> String {
        String(handle.filter(handleCharacters.contains))
    }

    private static let handleCharacters = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.")
}

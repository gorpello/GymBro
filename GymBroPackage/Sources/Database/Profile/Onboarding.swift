import Dependencies
import Foundation
import SQLiteData

extension Place {
    /// A starting setup offered during onboarding, with the equipment it usually has
    /// (`kPlacePresetGear` in GymMane).
    public struct Preset: Hashable, Identifiable, Sendable {
        public var id: String
        public var equipment: [Equipment]

        public static let gym = Self(id: "gym", equipment: Equipment.all)
        public static let home = Self(id: "home", equipment: [.bodyweight, .dumbbell, .kettlebell, .band, .weighted])
        public static let outdoors = Self(id: "outdoors", equipment: [.bodyweight, .band])

        public static let all = [gym, home, outdoors]
    }

    /// Adds a place with `equipment`; bodyweight is always there.
    @discardableResult
    public static func create(_ db: Database, name: String, equipment: [Equipment]) throws -> Place.ID {
        @Dependency(\.uuid) var uuid
        let placeID = uuid()
        try Place.insert { Place(id: placeID, name: name) }.execute(db)
        var seen = Set<Equipment>()
        for item in equipment + [.bodyweight] where seen.insert(item).inserted {
            try PlaceEquipment.insert { PlaceEquipment(id: uuid(), placeID: placeID, equipment: item) }.execute(db)
        }
        return placeID
    }
}

extension UserProfile {
    /// Finishes onboarding: saves the profile (a member from `now`, unless already one) and the
    /// weight unit, then awards whatever that earns. A profile row is what marks the app as set up.
    ///
    /// - Returns: Medals earned by it.
    @discardableResult
    public static func completeOnboarding(
        _ db: Database,
        profile: UserProfile,
        units: WeightUnit,
        now: Date,
        calendar: Calendar
    ) throws -> [AwardKind] {
        var profile = profile
        let existing = try UserProfile.find(UserProfile.singletonID).fetchOne(db)
        profile.memberSince = existing?.memberSince ?? profile.memberSince ?? now
        try UserProfile.upsert { UserProfile.Draft(profile) }.execute(db)

        var settings = try AppSettings.find(AppSettings.singletonID).fetchOne(db) ?? AppSettings()
        settings.units = units
        try AppSettings.upsert { AppSettings.Draft(settings) }.execute(db)

        return try Award.refresh(db, now: now, calendar: calendar)
    }
}

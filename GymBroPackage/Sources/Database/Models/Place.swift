import Foundation
import SQLiteData

/// A gym or home setup: what equipment it has and which plates are on the rack.
@Table
public struct Place: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var name = ""
    public var barWeightKg: Double?
}

@Table("placeEquipment")
public struct PlaceEquipment: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var placeID: Place.ID
    public var equipment: Equipment = .other
}

@Table
public struct PlacePlate: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var placeID: Place.ID
    public var weightKg = 0.0
    /// Plates of this weight available in total (not per side).
    public var count = 0
}

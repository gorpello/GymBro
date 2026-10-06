import Foundation
import SQLiteData

/// Bodyweight, body fat or a circumference, one value per row. Units follow `kind`.
@Table
public nonisolated struct BodyMeasurement: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var date = Date()
    public var kind: MeasurementKind = .bodyweight
    public var value = 0.0
}

/// A progress check-in: up to three photos, plus optional weight and note.
@Table
public nonisolated struct ProgressEntry: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var date = Date()
    public var weightKg: Double?
    public var note = ""
    public var frontPhoto: String?
    public var sidePhoto: String?
    public var backPhoto: String?
    
    public var photos: [String] { [frontPhoto, sidePhoto, backPhoto].compactMap(\.self) }
}

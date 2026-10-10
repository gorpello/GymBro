import Foundation
import SQLiteData

@Table
nonisolated public struct Note: Hashable, Identifiable, Sendable {
    public let id: UUID
    /// `nil` for a general note not tied to an exercise.
    public var exerciseID: Exercise.ID?
    public var date = Date()
    public var kind: NoteKind = .note
    /// First line is the title, the rest is the body.
    public var text = ""
    public var createdAt = Date()

    public var title: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\n").first.map(String.init) ?? ""
    }
}

/// A photo or video attached to a note, stored in the app container.
@Table
public struct NoteAttachment: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var noteID: Note.ID
    public var position = 0
    public var fileName = ""
}

/// A photo from the gym, kept on the Moments wall.
@Table
public struct Moment: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var date = Date()
    public var fileName = ""
    public var note = ""
}

/// A day marked as trained by hand, without a logged workout.
@Table
public struct CheckIn: Hashable, Identifiable, Sendable {
    public let id: UUID
    /// Start of the day, in the user's calendar.
    public var day = Date()
}

import DesignSystem
import L10n
import SwiftUI

/// Colour and icon for each journal note kind (`note_kit.dart`).
enum NoteKindStyle {
    static let kinds = ["note", "plan", "done", "pain"]

    static func color(_ kind: String) -> Color {
        switch kind {
        case "plan": GymColor.warn
        case "done": GymColor.sage
        case "pain": GymColor.danger
        default: GymColor.info
        }
    }

    static func icon(_ kind: String) -> Ph {
        switch kind {
        case "plan": .crosshair
        case "done": .checkCircle
        case "pain": .warning
        default: .notePencil
        }
    }
}

/// Small coloured tag: icon + kind name in caps.
struct NoteKindTag: View {
    let kind: String

    var body: some View {
        let color = NoteKindStyle.color(kind)
        HStack(spacing: 5) {
            GymIcon(NoteKindStyle.icon(kind), weight: .bold, size: 11)
            Text(L10n.noteKind(kind).uppercased())
                .font(.gym(11.5, .extraBold))
                .tracking(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.16), in: .rect(cornerRadius: 7))
    }
}

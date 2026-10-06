import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct NotesView: View {
    @Bindable var store: StoreOf<Notes>

    public init(store: StoreOf<Notes>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                filters
                if store.showsCalendar {
                    DatePicker(L10n.noteCalendar, selection: $store.calendarDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(GymColor.accent)
                        .softCard(padding: 12, radius: 24)
                }
                if store.days.isEmpty {
                    EmptyStateView(icon: .notebook, title: L10n.noteEmptyTitle, message: L10n.noteEmptyBody)
                }
                ForEach(store.days) { day in
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.id).font(.gym(15, .extraBold)).foregroundStyle(GymColor.text)
                            HStack(spacing: 10) {
                                Text(day.subtitle).font(.gym(13, .medium)).foregroundStyle(GymColor.textTertiary)
                                Rectangle().fill(GymColor.border).frame(height: 1)
                            }
                        }
                        ForEach(day.notes.filter { store.kindFilter == nil || $0.kind == store.kindFilter }) { note in
                            Button {
                                store.send(.noteTapped(id: note.id))
                            } label: {
                                NoteCard(note: note)
                            }
                            .buttonStyle(.pressable(scale: 0.98))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .gymScreen(L10n.journal, subtitle: L10n.noteCount(store.noteCount))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    store.send(.calendarButtonTapped)
                } label: {
                    GymIcon(.calendarBlank, size: 18)
                }
                .accessibilityLabel(L10n.noteCalendar)
                Button {
                    store.send(.addButtonTapped)
                } label: {
                    GymIcon(.plus, weight: .bold, size: 18)
                }
                .buttonStyle(.glassProminent)
                .tint(GymColor.ember)
                .accessibilityLabel(L10n.addNote.titleCased)
            }
        }
    }

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                filter(L10n.allExercisesShort, kind: nil)
                ForEach(NoteKindStyle.kinds, id: \.self) { kind in
                    let count = store.kindCounts[kind] ?? 0
                    if count > 0 { filter("\(L10n.noteKind(kind)) \(count)", kind: kind) }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func filter(_ label: String, kind: String?) -> some View {
        let selected = store.kindFilter == kind
        return Button {
            store.kindFilter = kind
        } label: {
            Text(label)
                .font(.gym(14, .bold))
                .foregroundStyle(selected ? GymColor.text : GymColor.textSecondary)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(GymColor.bgRaised, in: .capsule)
                .overlay(
                    Capsule().strokeBorder(selected ? GymColor.text : GymColor.border, lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.pressable(scale: 0.95))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Journal card with a kind-coloured edge fading out to the right.
struct NoteCard: View {
    let note: NoteRow

    var body: some View {
        let color = NoteKindStyle.color(note.kind)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                NoteKindTag(kind: note.kind)
                Spacer()
                if let exercise = note.exerciseName {
                    Text(exercise).font(.gym(13, .medium)).foregroundStyle(GymColor.textTertiary).lineLimit(1)
                }
            }
            Text(note.title).font(.gym(17, .bold)).foregroundStyle(GymColor.text)
            if !note.body.isEmpty {
                Text(note.body).font(.gym(14, .medium)).foregroundStyle(GymColor.textSecondary).lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(GymColor.bgRaised, in: .rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    LinearGradient(
                        colors: [color, color.opacity(0)], startPoint: .leading, endPoint: UnitPoint(x: 0.3, y: 0.5)),
                    lineWidth: 2.5
                )
        }
        .multilineTextAlignment(.leading)
    }
}

#Preview {
    NavigationStack {
        NotesView(store: Store(initialState: Notes.State()) { Notes() })
    }
}

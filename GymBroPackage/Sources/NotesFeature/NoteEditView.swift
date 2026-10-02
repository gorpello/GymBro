import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct NoteEditView: View {
    @Bindable var store: StoreOf<NoteEdit>
    
    public init(store: StoreOf<NoteEdit>) {
        self.store = store
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                field(L10n.noteKindLabel) {
                    HStack(spacing: 8) {
                        ForEach(NoteKindStyle.kinds, id: \.self) { kind in
                            let selected = store.kind == kind
                            Button {
                                store.kind = kind
                            } label: {
                                VStack(spacing: 6) {
                                    GymIcon(NoteKindStyle.icon(kind), weight: selected ? .fill : .regular, size: 20)
                                    Text(L10n.noteKind(kind)).font(.gym(12, .bold))
                                }
                                .foregroundStyle(selected ? NoteKindStyle.color(kind) : GymColor.textSecondary)
                                .frame(maxWidth: .infinity, minHeight: 64)
                                .background(GymColor.bgRaised, in: .rect(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(selected ? NoteKindStyle.color(kind) : GymColor.border, lineWidth: selected ? 1.5 : 1)
                                )
                            }
                            .buttonStyle(.pressable)
                            .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                }
                field(L10n.noteTextLabel) {
                    TextField(L10n.notePlaceholder, text: $store.text, axis: .vertical)
                        .font(.gym(16, .medium))
                        .lineLimit(5...14)
                        .padding(16)
                        .background(GymColor.bgRaised, in: .rect(cornerRadius: 18))
                }
                field(L10n.noteDateLabel) {
                    DatePicker(L10n.noteDateLabel, selection: $store.date, displayedComponents: .date)
                        .labelsHidden()
                        .tint(GymColor.accent)
                }
                field(L10n.noteExerciseLabel) {
                    Button {
                        store.send(.exerciseButtonTapped)
                    } label: {
                        OptionRow(store.exerciseName ?? L10n.noteGeneral, icon: .barbell, value: "")
                            .background(GymColor.bgRaised, in: .rect(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
                field(L10n.noteMediaLabel) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(store.media, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 14).fill(GymColor.bgRaised2).frame(width: 84, height: 84)
                            }
                            Button {
                                store.send(.attachButtonTapped)
                            } label: {
                                VStack(spacing: 6) {
                                    GymIcon(.paperclip, size: 20)
                                    Text(L10n.noteAttach).font(.gym(12, .bold))
                                }
                                .foregroundStyle(GymColor.textSecondary)
                                .frame(width: 84, height: 84)
                                .background(GymColor.bgRaised, in: .rect(cornerRadius: 14))
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .padding(20)
        }
        .gymScreen(store.id == nil ? L10n.newNote : L10n.editNote)
        .safeAreaInset(edge: .bottom) {
            Button(L10n.save.titleCased) { store.send(.saveButtonTapped) }
                .buttonStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .toolbar {
            if store.id != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) { store.send(.deleteButtonTapped) } label: { GymIcon(.trash, size: 18) }
                        .accessibilityLabel(L10n.deleteNoteTitle)
                }
            }
        }
    }
    
    private func field(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Kicker(title, size: 11, spacing: 2)
            content()
        }
    }
}

#Preview {
    NavigationStack {
        NoteEditView(store: Store(initialState: NoteEdit.State(id: nil)) { NoteEdit() })
    }
}

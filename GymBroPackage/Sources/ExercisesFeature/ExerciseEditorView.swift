import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct ExerciseEditorView: View {
    @Bindable var store: StoreOf<ExerciseEditor>
    
    public init(store: StoreOf<ExerciseEditor>) {
        self.store = store
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                TextField(L10n.exerciseName, text: $store.name)
                    .font(.gym(20, .bold))
                    .padding(16)
                    .background(GymColor.bgRaised, in: .rect(cornerRadius: 18))
                section(L10n.muscleFilter) {
                    FlowLayout {
                        ForEach(muscleIDs, id: \.self) { id in
                            Pill(L10n.muscle(id), selected: store.primary == id) { store.primary = id }
                        }
                    }
                }
                section(L10n.secondaryLabel) {
                    FlowLayout {
                        ForEach(muscleIDs.filter { $0 != store.primary }, id: \.self) { id in
                            ToggleChip(L10n.muscle(id), isOn: store.secondary.contains(id)) {
                                store.send(.secondaryMuscleTapped(id))
                            }
                        }
                    }
                }
                section(L10n.equipmentLabel) {
                    FlowLayout {
                        ForEach(equipmentIDs, id: \.self) { id in
                            Pill(L10n.equipment(id), selected: store.equipment == id) { store.equipment = id }
                        }
                    }
                }
                section(L10n.levelFilter) {
                    SegToggle(
                        ["Beginner", "Intermediate", "Advanced"].map { ($0, L10n.difficulty($0)) },
                        selection: $store.difficulty,
                        fontSize: 13
                    )
                }
                section(L10n.exerciseTypeLabel) {
                    SegToggle(
                        [
                            (ExerciseEditor.LogBy.reps, L10n.typeReps),
                            (.time, L10n.typeTime),
                            (.cardio, L10n.typeCardio),
                        ],
                        selection: $store.logBy,
                        fontSize: 13
                    )
                }
                section(L10n.howToLabel) {
                    TextField(L10n.howToHint, text: $store.howTo, axis: .vertical)
                        .font(.gym(15, .medium))
                        .lineLimit(4...10)
                        .padding(16)
                        .background(GymColor.bgRaised, in: .rect(cornerRadius: 18))
                }
                Button(L10n.addExercise.titleCased) {
                    store.send(.saveButtonTapped)
                }
                .buttonStyle(.primary)
                .disabled(store.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(20)
        }
        .gymScreen(L10n.newExercise)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) { store.send(.cancelButtonTapped) }
            }
        }
    }
    
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Kicker(title, size: 11, spacing: 2)
            content()
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseEditorView(store: Store(initialState: ExerciseEditor.State()) { ExerciseEditor() })
    }
}

import ComposableArchitecture
import Database
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
                        ForEach(Muscle.all, id: \.self) { muscle in
                            Pill(L10n.muscle(muscle.rawValue), selected: store.primary == muscle) {
                                store.primary = muscle
                            }
                        }
                    }
                }
                section(L10n.secondaryLabel) {
                    FlowLayout {
                        ForEach(Muscle.all.filter { $0 != store.primary }, id: \.self) { muscle in
                            ToggleChip(L10n.muscle(muscle.rawValue), isOn: store.secondary.contains(muscle)) {
                                store.send(.secondaryMuscleTapped(muscle))
                            }
                        }
                    }
                }
                section(L10n.equipmentLabel) {
                    FlowLayout {
                        ForEach(Equipment.all, id: \.self) { equipment in
                            Pill(L10n.equipment(equipment.rawValue), selected: store.equipment == equipment) {
                                store.equipment = equipment
                            }
                        }
                    }
                }
                section(L10n.levelFilter) {
                    SegToggle(
                        Difficulty.all.map { ($0, L10n.difficulty($0.rawValue)) },
                        selection: $store.difficulty,
                        fontSize: 13
                    )
                }
                section(L10n.exerciseTypeLabel) {
                    SegToggle(
                        [
                            (ExerciseMode.weight, L10n.typeReps),
                            (.time, L10n.typeTime),
                            (.cardio, L10n.typeCardio),
                        ],
                        selection: $store.mode,
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
                Button(store.isNew ? L10n.addExercise.titleCased : L10n.saveChanges) {
                    store.send(.saveButtonTapped)
                }
                .buttonStyle(.primary)
                .disabled(!store.canSave)
            }
            .padding(20)
        }
        .gymScreen(store.isNew ? L10n.newExercise : L10n.editExercise)
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

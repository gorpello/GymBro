import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct RoutineEditView: View {
    @Bindable var store: StoreOf<RoutineEdit>
    
    public init(store: StoreOf<RoutineEdit>) {
        self.store = store
    }
    
    public var body: some View {
        List {
            Section {
                TextField(L10n.routineName, text: $store.name)
                    .font(.gym(20, .bold))
                    .listRowBackground(GymColor.bgRaised)
            }
            Section {
                HStack {
                    ForEach(Array(L10n.weekdayInitials.enumerated()), id: \.offset) { index, initial in
                        let on = store.weekdays.contains(index)
                        Button {
                            store.send(.weekdayTapped(index))
                        } label: {
                            Text(initial)
                                .font(.gym(13, .bold))
                                .foregroundStyle(on ? GymColor.onEmber : GymColor.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(on ? GymColor.ember : GymColor.bgRaised2, in: .circle)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
                .listRowBackground(GymColor.bgRaised)
                HStack {
                    Text(L10n.routineGroup).font(.gym(15, .medium))
                    Spacer()
                    TextField(L10n.noGroup, text: $store.group)
                        .multilineTextAlignment(.trailing)
                        .font(.gym(15, .medium))
                        .foregroundStyle(GymColor.textSecondary)
                }
                .listRowBackground(GymColor.bgRaised)
            } header: {
                Kicker(L10n.schedule, size: 11, spacing: 2)
            }
            Section {
                if store.exercises.isEmpty {
                    Text(L10n.addFromList).font(.gym(14, .medium)).foregroundStyle(GymColor.textSecondary)
                        .listRowBackground(GymColor.bgRaised)
                }
                ForEach(store.exercises) { row in
                    exerciseRow(row)
                        .listRowBackground(GymColor.bgRaised)
                        .swipeActions {
                            Button(L10n.removeFromRoutine, role: .destructive) { store.send(.removeExerciseTapped(id: row.id)) }
                        }
                }
                .onMove { store.send(.moveExercises(from: $0, to: $1)) }
            } header: {
                Kicker(L10n.exercisesWithCount(store.exercises.count), size: 11, spacing: 2)
            } footer: {
                Text(L10n.setsPlannedHint).font(.gym(12, .medium)).foregroundStyle(GymColor.textSecondary)
            }
            Section {
                SearchField(L10n.searchExercises, text: $store.searchText)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                ForEach(store.library) { row in
                    Button {
                        store.send(.addExerciseTapped(id: row.id))
                    } label: {
                        HStack(spacing: 14) {
                            ExerciseArtView(art: row.art)
                                .frame(width: 48, height: 48)
                                .background(GymColor.bgRaised2, in: .rect(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.name).font(.gym(15, .bold)).foregroundStyle(GymColor.text)
                                Text(row.detail).font(.gym(12.5, .medium)).foregroundStyle(GymColor.textSecondary)
                            }
                            Spacer()
                            GymIcon(.plusCircle, size: 22).foregroundStyle(GymColor.accent)
                        }
                    }
                    .listRowBackground(GymColor.bgRaised)
                }
            } header: {
                Kicker(L10n.addExercises, size: 11, spacing: 2)
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(.active))
        .gymScreen(store.name.isEmpty ? L10n.newRoutine : store.name)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                Button(L10n.save.titleCased) { store.send(.saveButtonTapped) }
                    .buttonStyle(.primary(fill: GymColor.bgRaised2, foreground: GymColor.text))
                Button(L10n.startWorkout.titleCased) { store.send(.startButtonTapped) }
                    .buttonStyle(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
    
    private func exerciseRow(_ row: RoutineExerciseRow) -> some View {
        HStack(spacing: 12) {
            ExerciseArtView(art: row.art)
                .frame(width: 44, height: 44)
                .background(GymColor.bgRaised2, in: .rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(row.name).font(.gym(15, .bold)).foregroundStyle(GymColor.text).lineLimit(1)
                Button {
                    store.send(.supersetToggled(id: row.id))
                } label: {
                    HStack(spacing: 4) {
                        GymIcon(.link, size: 12)
                        Text(row.chained ? L10n.superset : L10n.supersetLink)
                    }
                    .font(.gym(12, .semibold))
                    .foregroundStyle(row.chained ? GymColor.accent : GymColor.textTertiary)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            StepperControl("\(row.sets)", fontSize: 14, buttonSize: 26, minWidth: 22) {
                store.send(.setsChanged(id: row.id, delta: -1))
            } onIncrement: {
                store.send(.setsChanged(id: row.id, delta: 1))
            }
        }
    }
}

#Preview {
    NavigationStack {
        RoutineEditView(store: Store(initialState: RoutineEdit.State(id: nil)) { RoutineEdit() })
    }
}

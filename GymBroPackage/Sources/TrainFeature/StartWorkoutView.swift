import ComposableArchitecture
import Database
import DesignSystem
import L10n
import SwiftUI

public struct StartWorkoutView: View {
    @Bindable var store: StoreOf<StartWorkout>

    public init(store: StoreOf<StartWorkout>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SheetTitle(
                    store.isLogging ? L10n.logTitle : L10n.startTitle,
                    subtitle: store.isLogging ? L10n.logHint : dateTitle
                )
                .padding(.top, 8)
                SegToggle([(false, L10n.startTitle), (true, L10n.logTitle)], selection: $store.isLogging, fontSize: 13)
                if store.options.hasWorkoutInProgress {
                    Button(L10n.resumeWorkout.titleCased) { store.send(.resumeButtonTapped) }
                        .buttonStyle(.primary)
                }
                if let today = store.options.today {
                    Kicker(L10n.todaysRoutine, size: 11, spacing: 2)
                    routineRow(today, prominent: true)
                }
                if !store.options.routines.isEmpty {
                    Kicker(L10n.yourRoutines, size: 11, spacing: 2)
                    VStack(spacing: 8) {
                        ForEach(store.options.routines) { routineRow($0, prominent: false) }
                    }
                }
                Kicker(L10n.orStartFrom, size: 11, spacing: 2)
                HStack(spacing: 12) {
                    option(L10n.pickExercisesOption, icon: .listPlus) { store.send(.pickExercisesButtonTapped) }
                    option(L10n.chooseFocusOption, icon: .person) { store.send(.chooseFocusButtonTapped) }
                }
            }
            .padding(20)
        }
        .gymBackground()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task { await store.send(.task).finish() }
    }

    /// "Saturday, Sep 19".
    private var dateTitle: String {
        store.today?.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()) ?? " "
    }

    private func routineRow(_ row: StartRoutineRow, prominent: Bool) -> some View {
        Button {
            store.send(.routineTapped(id: row.id))
        } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(GymColor.folderHues[row.hue % GymColor.folderHues.count])
                    .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.name)
                        .font(.gym(prominent ? 18 : 15.5, .extraBold))
                        .foregroundStyle(GymColor.text)
                    Text(L10n.exerciseCount(row.exerciseCount))
                        .font(.gym(12.5, .medium))
                        .foregroundStyle(GymColor.textSecondary)
                }
                Spacer()
                GymIcon(.play, weight: .fill, size: 14)
                    .foregroundStyle(GymColor.onEmber)
                    .frame(width: 36, height: 36)
                    .background(GymColor.ember, in: .circle)
            }
            .softCard(padding: 14, radius: 20)
        }
        .buttonStyle(.pressable)
    }

    private func option(_ title: String, icon: Ph, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                GymIcon(icon, size: 22).foregroundStyle(GymColor.text)
                Text(title)
                    .font(.gym(14, .bold))
                    .foregroundStyle(GymColor.text)
            }
            .frame(maxWidth: .infinity)
            .softCard(padding: 18, radius: 20)
        }
        .buttonStyle(.pressable)
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        StartWorkoutView(store: previewStore())
    }
}

/// A store backed by a database seeded with a month of training.
@MainActor
private func previewStore() -> StoreOf<StartWorkout> {
    prepareDependencies {
        // swiftlint:disable:next force_try
        try! $0.bootstrapDatabase()
        // swiftlint:disable:next force_try
        try! $0.seedDatabaseForPreviews()
    }
    return Store(initialState: StartWorkout.State()) { StartWorkout() }
}

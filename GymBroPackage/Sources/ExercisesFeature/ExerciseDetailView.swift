import ComposableArchitecture
import Database
import DesignSystem
import L10n
import SwiftUI

public struct ExerciseDetailView: View {
    @Bindable var store: StoreOf<ExerciseDetail>

    public init(store: StoreOf<ExerciseDetail>) {
        self.store = store
    }

    private var overview: ExerciseOverview { store.overview }
    private var units: WeightUnit { overview.units }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if store.isArchived {
                    Text(L10n.archivedBanner)
                        .font(.gym(13, .semibold))
                        .foregroundStyle(GymColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(GymColor.bgRaised, in: .rect(cornerRadius: 16))
                }
                ExerciseArtView(art: overview.exercise?.art ?? "", live: true)
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .softCard(padding: 0, radius: 26, fill: GymColor.bgRaised2)
                muscles
                if let target = overview.nextTarget {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(L10n.nextTime).foregroundStyle(GymColor.accent)
                        Text(ExerciseFormat.target(target, units: units)).foregroundStyle(GymColor.text)
                    }
                    .font(.gym(14, .semibold))
                }
                recordAndGoal
                history
                notesRow
                steps
                similar
                settings
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .gymScreen(store.name)
        .task { await store.send(.task).finish() }
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(item: $store.scope(state: \.editor, action: \.editor)) { editorStore in
            NavigationStack {
                ExerciseEditorView(store: editorStore)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if store.isCustom {
                        Button(L10n.editExercise) { store.send(.editButtonTapped) }
                    }
                    Button(store.isArchived ? L10n.restoreExercise : L10n.archiveExercise) {
                        store.send(.archiveButtonTapped)
                    }
                    if store.isCustom {
                        Button(L10n.delete, role: .destructive) { store.send(.deleteButtonTapped) }
                    }
                } label: {
                    GymIcon(.dotsThreeVertical, weight: .bold, size: 18)
                }
            }
        }
    }

    private var muscles: some View {
        FlowLayout {
            if let exercise = overview.exercise {
                Pill(L10n.muscle(exercise.primaryMuscle.rawValue), selected: true)
                ForEach(exercise.secondaryMuscles, id: \.self) { Pill(L10n.muscle($0.rawValue)) }
                Pill(L10n.equipment(exercise.equipment.rawValue))
            }
        }
    }

    private var recordAndGoal: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Kicker(L10n.personalRecord, size: 11, spacing: 1.5)
                StatValue(overview.record.map { ExerciseFormat.record($0, units: units) } ?? "–", size: 24)
                if let record = overview.record {
                    Text(UnitFormat.shortDate(record.date))
                        .font(.gym(12, .medium))
                        .foregroundStyle(GymColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .softCard(padding: 18, radius: 22)
            VStack(alignment: .leading, spacing: 8) {
                Kicker(L10n.goal, size: 11, spacing: 1.5)
                if let goalKg = overview.preference?.goalTargetKg, let progress = store.goalProgress {
                    StatValue(UnitFormat.weightLabel(goalKg, units: units), size: 24)
                    ProgressView(value: progress)
                        .tint(GymColor.accent)
                } else {
                    Text(L10n.goalSet)
                        .font(.gym(15, .bold))
                        .foregroundStyle(GymColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .softCard(padding: 18, radius: 22)
        }
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(L10n.history)
                .padding(.bottom, 8)
            if overview.history.isEmpty {
                Text(L10n.noHistory)
                    .font(.gym(13, .medium))
                    .foregroundStyle(GymColor.textSecondary)
            }
            ForEach(Array(overview.history.enumerated()), id: \.element.id) { index, row in
                if index > 0 { Rectangle().fill(GymColor.border).frame(height: 1) }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(UnitFormat.shortDate(row.date))
                            .font(.gym(16, .bold))
                            .foregroundStyle(GymColor.text)
                        Text(L10n.setCount(row.setCount))
                            .font(.gym(13, .medium))
                            .foregroundStyle(GymColor.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(UnitFormat.weightLabel(row.topWeightKg, units: units))
                            .font(.gym(18, .extraBold))
                            .foregroundStyle(GymColor.text)
                        Text(L10n.volumeSuffix(ExerciseFormat.volume(row.volumeKg, units: units)))
                            .font(.gym(13, .medium))
                            .foregroundStyle(GymColor.textSecondary)
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }

    private var notesRow: some View {
        Button {
            store.send(.notesButtonTapped)
        } label: {
            HStack(spacing: 14) {
                GymIcon(.notebook, size: 20)
                    .foregroundStyle(GymColor.text)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.notes.titleCased)
                        .font(.gym(15, .semibold))
                        .foregroundStyle(GymColor.text)
                    Text(L10n.noteCount(overview.noteCount))
                        .font(.gym(12.5, .medium))
                        .foregroundStyle(GymColor.textSecondary)
                }
                Spacer()
                GymIcon(.caretRight, weight: .bold, size: 13)
                    .foregroundStyle(GymColor.textTertiary)
            }
            .padding(18)
            .background(GymColor.bgRaised, in: .rect(cornerRadius: 22))
        }
        .buttonStyle(.pressable(scale: 0.98))
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(L10n.howTo)
            let steps = overview.exercise?.steps ?? []
            if steps.isEmpty {
                Text(L10n.noStepsYet)
                    .font(.gym(13, .medium))
                    .foregroundStyle(GymColor.textSecondary)
            }
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text("\(index + 1)")
                        .font(.gym(12, .extraBold))
                        .foregroundStyle(GymColor.text)
                        .frame(width: 26, height: 26)
                        .background(GymColor.bgRaised2, in: .circle)
                    Text(step)
                        .font(.gym(15, .medium))
                        .foregroundStyle(GymColor.textSecondary)
                        .lineSpacing(4)
                }
            }
        }
    }

    @ViewBuilder
    private var similar: some View {
        if !overview.similar.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(L10n.similar)
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(overview.similar) { row in
                            Button {
                                store.send(.similarTapped(id: row.id))
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    ExerciseArtView(art: row.art)
                                        .frame(width: 120, height: 100)
                                        .background(GymColor.bgRaised2, in: .rect(cornerRadius: 16))
                                    Text(row.name)
                                        .font(.gym(13, .bold))
                                        .foregroundStyle(GymColor.text)
                                        .lineLimit(2)
                                        .frame(width: 120, alignment: .leading)
                                }
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var settings: some View {
        GroupCard {
            OptionRow(L10n.suggestInWorkouts, detail: L10n.suggestInWorkoutsHint) {
                Toggle(
                    L10n.suggestInWorkouts,
                    isOn: $store.suggestInWorkouts.sending(\.suggestInWorkoutsToggled)
                ).labelsHidden().toggleStyle(.gym)
            }
            OptionRow(L10n.autoWarmup, detail: L10n.autoWarmupHint) {
                Toggle(L10n.autoWarmup, isOn: $store.autoWarmup.sending(\.autoWarmupToggled)).labelsHidden()
                    .toggleStyle(.gym)
            }
            OptionRow(L10n.autoProgress) {
                Toggle(L10n.autoProgress, isOn: $store.autoProgress.sending(\.autoProgressToggled)).labelsHidden()
                    .toggleStyle(.gym)
            }
            OptionRow(L10n.restForExercise) {
                StepperControl(
                    ExerciseFormat.rest(store.restSeconds),
                    fontSize: 14,
                    onDecrement: { store.send(.restDecrementButtonTapped) },
                    onIncrement: { store.send(.restIncrementButtonTapped) }
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(store: previewStore())
    }
}

/// The bench press, from a database seeded with a month of training.
@MainActor
private func previewStore() -> StoreOf<ExerciseDetail> {
    prepareDependencies {
        // swiftlint:disable:next force_try
        try! $0.bootstrapDatabase()
        // swiftlint:disable:next force_try
        try! $0.seedDatabaseForPreviews()
    }
    return Store(initialState: ExerciseDetail.State(id: "EIeI8Vf")) { ExerciseDetail() }
}

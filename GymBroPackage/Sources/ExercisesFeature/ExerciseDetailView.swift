import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct ExerciseDetailView: View {
    @Bindable var store: StoreOf<ExerciseDetail>

    public init(store: StoreOf<ExerciseDetail>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ExerciseArtView(art: store.art, live: true)
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .softCard(padding: 0, radius: 26, fill: GymColor.bgRaised2)
                muscles
                if let next = store.nextTime {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(L10n.nextTime).foregroundStyle(GymColor.accent)
                        Text(next).foregroundStyle(GymColor.text)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(L10n.editExercise) { store.send(.editButtonTapped) }
                    Button(L10n.archiveExercise) { store.send(.archiveButtonTapped) }
                    Button(L10n.delete, role: .destructive) { store.send(.deleteButtonTapped) }
                } label: {
                    GymIcon(.dotsThreeVertical, weight: .bold, size: 18)
                }
            }
        }
    }

    private var muscles: some View {
        FlowLayout {
            Pill(L10n.muscle(store.primary), selected: true)
            ForEach(store.secondary, id: \.self) { Pill(L10n.muscle($0)) }
            Pill(L10n.equipment(store.equipment))
        }
    }

    private var recordAndGoal: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Kicker(L10n.personalRecord, size: 11, spacing: 1.5)
                StatValue(store.personalRecord ?? "–", size: 24)
                Text(store.personalRecordDate)
                    .font(.gym(12, .medium))
                    .foregroundStyle(GymColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .softCard(padding: 18, radius: 22)
            VStack(alignment: .leading, spacing: 8) {
                Kicker(L10n.goal, size: 11, spacing: 1.5)
                if let goal = store.goal {
                    StatValue(goal, size: 24)
                    ProgressView(value: store.goalProgress)
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
            if store.history.isEmpty {
                Text(L10n.noHistory)
                    .font(.gym(13, .medium))
                    .foregroundStyle(GymColor.textSecondary)
            }
            ForEach(Array(store.history.enumerated()), id: \.element.id) { index, row in
                if index > 0 { Rectangle().fill(GymColor.border).frame(height: 1) }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.date)
                            .font(.gym(16, .bold))
                            .foregroundStyle(GymColor.text)
                        Text(L10n.setCount(row.sets))
                            .font(.gym(13, .medium))
                            .foregroundStyle(GymColor.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(row.topWeight)
                            .font(.gym(18, .extraBold))
                            .foregroundStyle(GymColor.text)
                        Text(L10n.volumeSuffix(row.volume))
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
                    Text(L10n.noteCount(store.noteCount))
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
            if store.steps.isEmpty {
                Text(L10n.noStepsYet)
                    .font(.gym(13, .medium))
                    .foregroundStyle(GymColor.textSecondary)
            }
            ForEach(Array(store.steps.enumerated()), id: \.offset) { index, step in
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
        if !store.similar.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(L10n.similar)
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(store.similar) { row in
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
                Toggle(L10n.suggestInWorkouts, isOn: $store.suggestInWorkouts).labelsHidden().toggleStyle(.gym)
            }
            OptionRow(L10n.autoWarmup, detail: L10n.autoWarmupHint) {
                Toggle(L10n.autoWarmup, isOn: $store.autoWarmup).labelsHidden().toggleStyle(.gym)
            }
            OptionRow(L10n.autoProgress) {
                Toggle(L10n.autoProgress, isOn: $store.autoProgress).labelsHidden().toggleStyle(.gym)
            }
            OptionRow(L10n.restForExercise) {
                StepperControl(
                    store.restSeconds == 0 ? L10n.restOff : "\(store.restSeconds)s",
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
        ExerciseDetailView(store: Store(initialState: ExerciseDetail.State(id: "EIeI8Vf")) { ExerciseDetail() })
    }
}

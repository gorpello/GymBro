import ComposableArchitecture
import Database
import DesignSystem
import L10n
import SwiftUI

public struct ProgressOverviewView: View {
    @Bindable var store: StoreOf<ProgressOverview>

    public init(store: StoreOf<ProgressOverview>) {
        self.store = store
    }

    private var summary: ProgressSummary { store.summary }
    private var units: WeightUnit { summary.units }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                HStack(spacing: 12) {
                    volumeTile
                    weightTile
                }
                consistency
                HStack(spacing: 12) {
                    totalTile(L10n.allTimeSessions, value: "\(summary.totals.workoutCount)")
                    totalTile(L10n.allTimeSets, value: "\(summary.totals.setCount)")
                    totalTile(
                        L10n.allTimeTime,
                        value: ProgressFormat.hours(summary.totals.trainingSeconds),
                        unit: L10n.unitHours
                    )
                }
                thisWeek
                muscleMap
                strength
                if !summary.records.isEmpty {
                    records
                }
                timeline
                measures
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .gymBackground()
        .toolbar(.hidden, for: .navigationBar)
        .task { await store.send(.task).finish() }
    }

    private var header: some View {
        HStack {
            ScreenTitle(L10n.progressTitle, size: 30)
            Spacer()
            RoundButton(.shareNetwork, label: L10n.share, size: 48) {
                store.send(.shareButtonTapped)
            }
        }
        .padding(.top, 8)
    }

    private var volumeTile: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Kicker(L10n.tileVolume30, size: 11, spacing: 1.5)
                Spacer()
                if let change = summary.volumeChangePercent {
                    HStack(spacing: 3) {
                        GymIcon(change >= 0 ? .trendUp : .trendDown, weight: .bold, size: 12)
                        Text(ProgressFormat.change(change))
                    }
                    .font(.gym(12, .bold))
                    .foregroundStyle(change >= 0 ? GymColor.sage : GymColor.accent)
                }
            }
            let volume = ProgressFormat.volume(summary.volume30Kg, units: units)
            StatValue(volume.value, unit: volume.unit, size: 30)
            Sparkline(summary.volumeTrendKg.map { units.value(fromKilograms: $0) / 1_000 })
                .frame(height: 44)
                .opacity(summary.volumeTrendKg.isEmpty ? 0 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard(padding: 18, radius: 24)
    }

    private var weightTile: some View {
        VStack(alignment: .leading, spacing: 4) {
            Kicker(L10n.weightLabel, size: 11, spacing: 1.5)
                .padding(.bottom, 6)
            if let weight = summary.weight {
                StatValue(ProgressFormat.weight(weight.value, units: units), unit: units.rawValue, size: 30)
                Text(ProgressFormat.shortDate(weight.date))
                    .font(.gym(12.5, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                Sparkline(summary.weightTrendKg.map(units.value(fromKilograms:)))
                    .frame(height: 40)
                    .opacity(summary.weightTrendKg.count < 2 ? 0 : 1)
            } else {
                Text(L10n.tileAddWeight)
                    .font(.gym(16, .bold))
                    .foregroundStyle(GymColor.textSecondary)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .softCard(padding: 18, radius: 24)
    }

    private var consistency: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Kicker(L10n.consistency, size: 11, spacing: 1.5)
                Spacer()
                HStack(spacing: 3) {
                    ForEach(1..<4, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2.5).fill(HeatTone.ember.color(level: level + 1))
                            .frame(width: 10, height: 10)
                    }
                }
            }
            HeatGrid(weeks: summary.activity)
            HStack {
                GymIcon(.flame, weight: .fill, size: 14)
                    .foregroundStyle(GymColor.accent)
                Text(L10n.streakDays(summary.streak))
                    .font(.gym(14, .bold))
                    .foregroundStyle(GymColor.text)
                Spacer()
                Text(L10n.weekOfGoal(n: summary.daysDoneThisWeek, goal: summary.weeklyGoal))
                    .font(.gym(13, .medium))
                    .foregroundStyle(GymColor.textSecondary)
            }
        }
        .softCard(padding: 20, radius: 24)
    }

    private func totalTile(_ label: String, value: String, unit: String? = nil) -> some View {
        StatBlock(label, value: value, unit: unit, size: 28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .softCard(padding: 18, radius: 22)
    }

    private var thisWeek: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Kicker(L10n.thisWeekTitle, size: 11, spacing: 1.5)
                Spacer()
                Text(L10n.setsThisWeek(summary.setsThisWeek.reduce(0, +)))
                    .font(.gym(12.5, .semibold))
                    .foregroundStyle(GymColor.textSecondary)
            }
            let peak = max(summary.setsThisWeek.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(L10n.weekdayInitials.enumerated()), id: \.offset) { index, initial in
                    let sets = index < summary.setsThisWeek.count ? summary.setsThisWeek[index] : 0
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(sets > 0 ? GymColor.accent : GymColor.heatEmpty)
                            .frame(height: max(6, 70 * CGFloat(sets) / CGFloat(peak)))
                        Text(initial)
                            .font(.gym(11, .semibold))
                            .foregroundStyle(GymColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 96, alignment: .bottom)
        }
        .softCard(padding: 20, radius: 24)
    }

    private var muscleMap: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Kicker(L10n.muscleMap, size: 11, spacing: 1.5)
                Spacer()
                SegToggle(
                    [
                        (ProgressOverview.MuscleRange.days7, L10n.days7),
                        (.days30, L10n.days30),
                        (.recovery, L10n.recoveryTab),
                    ],
                    selection: $store.muscleRange
                )
                .fixedSize()
            }
            switch store.muscleRange {
            case .days7:
                BodyMapView(levels: Self.levels(summary.muscleHeat7))
                HeatLegend(low: L10n.heatLow, high: L10n.heatHigh)
            case .days30:
                BodyMapView(levels: Self.levels(summary.muscleHeat30))
                HeatLegend(low: L10n.heatLow, high: L10n.heatHigh)
            case .recovery:
                BodyMapView(levels: Self.levels(summary.fatigueLevels), tone: .green)
                Text(L10n.recoveryOverall(Double(summary.recoveryPercent) / 100))
                    .font(.gym(14, .bold))
                    .foregroundStyle(GymColor.text)
                HeatLegend(low: L10n.recoveryFresh, high: L10n.recoveryTired, tone: .green)
            }
            Text(store.muscleRange == .recovery ? L10n.recoveryHint : L10n.muscleMapHint)
                .font(.gym(12.5, .medium))
                .foregroundStyle(GymColor.textSecondary)
        }
        .softCard(padding: 20, radius: 24)
    }

    private var strength: some View {
        VStack(alignment: .leading, spacing: 4) {
            Kicker(L10n.strength1rm, size: 11, spacing: 1.5)
                .padding(.bottom, 8)
            if summary.strength.isEmpty {
                Text(L10n.strengthEmpty)
                    .font(.gym(13, .medium))
                    .foregroundStyle(GymColor.textSecondary)
            }
            ForEach(summary.strength) { row in
                Button {
                    store.send(.exerciseTapped(id: row.id))
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.name)
                                .font(.gym(14.5, .bold))
                                .foregroundStyle(GymColor.text)
                                .lineLimit(1)
                            Text("\(ProgressFormat.weight(row.bestOneRepMaxKg, units: units)) \(units.rawValue)")
                                .font(.gym(12.5, .medium))
                                .foregroundStyle(GymColor.textSecondary)
                        }
                        Spacer()
                        Sparkline(row.curveKg.map(units.value(fromKilograms:)), showsRange: false)
                            .frame(width: 96, height: 32)
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .softCard(padding: 20, radius: 24)
    }

    private var records: some View {
        VStack(alignment: .leading, spacing: 4) {
            Kicker(L10n.personalRecords, size: 11, spacing: 1.5)
                .padding(.bottom, 8)
            ForEach(summary.records) { row in
                HStack {
                    GymIcon(.trophy, weight: .fill, size: 16)
                        .foregroundStyle(GymColor.brass)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.name)
                            .font(.gym(14.5, .bold))
                            .foregroundStyle(GymColor.text)
                        Text(ProgressFormat.shortDate(row.record.date))
                            .font(.gym(12, .medium))
                            .foregroundStyle(GymColor.textSecondary)
                    }
                    Spacer()
                    Text(ProgressFormat.record(row.record, units: units))
                        .font(.gym(16, .extraBold))
                        .foregroundStyle(GymColor.text)
                }
                .padding(.vertical, 8)
            }
        }
        .softCard(padding: 20, radius: 24)
    }

    private var timeline: some View {
        Button {
            store.send(.timelineButtonTapped)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Kicker(L10n.timeline, size: 11, spacing: 1.5)
                    Spacer()
                    Text(L10n.photoCount(summary.photoCount))
                        .font(.gym(12.5, .semibold))
                        .foregroundStyle(GymColor.textSecondary)
                    GymIcon(.caretRight, weight: .bold, size: 12)
                        .foregroundStyle(GymColor.textTertiary)
                }
                Text(L10n.timelineHint)
                    .font(.gym(13, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                    .multilineTextAlignment(.leading)
                Button(L10n.compare.titleCased) {
                    store.send(.compareButtonTapped)
                }
                .buttonStyle(.ghost)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .softCard(padding: 20, radius: 24)
        }
        .buttonStyle(.pressable(scale: 0.98))
    }

    private var measures: some View {
        Button {
            store.send(.measuresButtonTapped)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Kicker(L10n.measures, size: 11, spacing: 1.5)
                    Spacer()
                    GymIcon(.caretRight, weight: .bold, size: 12)
                        .foregroundStyle(GymColor.textTertiary)
                }
                if summary.measures.isEmpty {
                    Text(L10n.measuresHint)
                        .font(.gym(13, .medium))
                        .foregroundStyle(GymColor.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                    ForEach(summary.measures) { measurement in
                        let shown = ProgressFormat.measure(measurement, units: units)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.measureName(measurement.kind.rawValue))
                                .font(.gym(11.5, .semibold))
                                .foregroundStyle(GymColor.textSecondary)
                            StatValue(shown.value, unit: shown.unit, size: 18)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(GymColor.bgRaised2, in: .rect(cornerRadius: 14))
                    }
                }
            }
            .softCard(padding: 20, radius: 24)
        }
        .buttonStyle(.pressable(scale: 0.98))
    }
}

extension ProgressOverviewView {
    /// Body map levels are keyed by muscle id.
    fileprivate static func levels(_ levels: [Muscle: Int]) -> [String: Int] {
        Dictionary(uniqueKeysWithValues: levels.map { ($0.key.rawValue, $0.value) })
    }
}

#Preview {
    ProgressOverviewView(store: previewStore())
}

/// A store backed by a database seeded with a month of training.
@MainActor
private func previewStore() -> StoreOf<ProgressOverview> {
    prepareDependencies {
        // swiftlint:disable:next force_try
        try! $0.bootstrapDatabase()
        // swiftlint:disable:next force_try
        try! $0.seedDatabaseForPreviews()
    }
    return Store(initialState: ProgressOverview.State()) { ProgressOverview() }
}

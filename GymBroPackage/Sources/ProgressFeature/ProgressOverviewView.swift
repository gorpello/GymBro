import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct ProgressOverviewView: View {
    @Bindable var store: StoreOf<ProgressOverview>
    
    public init(store: StoreOf<ProgressOverview>) {
        self.store = store
    }
    
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
                    totalTile(L10n.allTimeSessions, value: "\(store.totalSessions)")
                    totalTile(L10n.allTimeSets, value: "\(store.totalSets)")
                    totalTile(L10n.allTimeTime, value: store.totalHours, unit: L10n.unitHours)
                }
                thisWeek
                muscleMap
                strength
                records
                timeline
                measures
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .gymBackground()
        .toolbar(.hidden, for: .navigationBar)
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
                HStack(spacing: 3) {
                    GymIcon(.trendUp, weight: .bold, size: 12)
                    Text(store.volumeTrendPercent)
                }
                .font(.gym(12, .bold))
                .foregroundStyle(GymColor.sage)
            }
            StatValue(store.volume30, unit: store.volumeUnit, size: 30)
            Sparkline(store.volumeTrend)
                .frame(height: 44)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard(padding: 18, radius: 24)
    }
    
    private var weightTile: some View {
        VStack(alignment: .leading, spacing: 4) {
            Kicker(L10n.weightLabel, size: 11, spacing: 1.5)
                .padding(.bottom, 6)
            if let weight = store.weight {
                StatValue(weight, unit: store.weightUnit, size: 30)
                Text(store.weightDate)
                    .font(.gym(12.5, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                Sparkline(store.weightTrend)
                    .frame(height: 40)
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
            HeatGrid(weeks: store.activity)
            HStack {
                GymIcon(.flame, weight: .fill, size: 14)
                    .foregroundStyle(GymColor.accent)
                Text(L10n.streakDays(store.streak))
                    .font(.gym(14, .bold))
                    .foregroundStyle(GymColor.text)
                Spacer()
                Text(L10n.weekOfGoal(n: store.weeklySessions, goal: store.weeklyGoal))
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
                Text(L10n.setsThisWeek(store.setsThisWeek.reduce(0, +)))
                    .font(.gym(12.5, .semibold))
                    .foregroundStyle(GymColor.textSecondary)
            }
            let peak = max(store.setsThisWeek.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(L10n.weekdayInitials.enumerated()), id: \.offset) { index, initial in
                    let sets = index < store.setsThisWeek.count ? store.setsThisWeek[index] : 0
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
                BodyMapView(levels: store.muscleLevels7)
                HeatLegend(low: L10n.heatLow, high: L10n.heatHigh)
            case .days30:
                BodyMapView(levels: store.muscleLevels30)
                HeatLegend(low: L10n.heatLow, high: L10n.heatHigh)
            case .recovery:
                BodyMapView(levels: store.recoveryLevels, tone: .green)
                Text(L10n.recoveryOverall(Double(store.recoveryPercent) / 100))
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
            if store.strength.isEmpty {
                Text(L10n.strengthEmpty)
                    .font(.gym(13, .medium))
                    .foregroundStyle(GymColor.textSecondary)
            }
            ForEach(store.strength) { row in
                Button {
                    store.send(.exerciseTapped(id: row.id))
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.name)
                                .font(.gym(14.5, .bold))
                                .foregroundStyle(GymColor.text)
                                .lineLimit(1)
                            Text(row.bestOneRm)
                                .font(.gym(12.5, .medium))
                                .foregroundStyle(GymColor.textSecondary)
                        }
                        Spacer()
                        Sparkline(row.curve, showsRange: false)
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
            ForEach(store.records) { row in
                HStack {
                    GymIcon(.trophy, weight: .fill, size: 16)
                        .foregroundStyle(GymColor.brass)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.name)
                            .font(.gym(14.5, .bold))
                            .foregroundStyle(GymColor.text)
                        Text(row.date)
                            .font(.gym(12, .medium))
                            .foregroundStyle(GymColor.textSecondary)
                    }
                    Spacer()
                    Text(row.best)
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
                    Text(L10n.photoCount(store.photoCount))
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
                Text(L10n.measuresHint)
                    .font(.gym(13, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                    .multilineTextAlignment(.leading)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                    ForEach(store.measureRows) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.measureName(row.id))
                                .font(.gym(11.5, .semibold))
                                .foregroundStyle(GymColor.textSecondary)
                            StatValue(row.value ?? "–", unit: row.value == nil ? nil : row.unit, size: 18)
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

#Preview {
    ProgressOverviewView(store: Store(initialState: ProgressOverview.State()) { ProgressOverview() })
}

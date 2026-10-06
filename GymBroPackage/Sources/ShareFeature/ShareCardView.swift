import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct ShareCardView: View {
    @Bindable var store: StoreOf<ShareCard>

    public init(store: StoreOf<ShareCard>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SheetTitle(L10n.sharePick, subtitle: L10n.shareHint)
                    .padding(.top, 12)
                SegToggle(
                    [
                        (ShareCard.Kind.streak, L10n.shareStreak),
                        (.body, L10n.shareBody),
                        (.compare, L10n.shareCompare),
                    ],
                    selection: $store.kind,
                    fontSize: 11.5
                )
                preview
                    .padding(22)
                    .frame(maxWidth: .infinity)
                    .background(GymColor.bgRaised, in: .rect(cornerRadius: 28))
                    .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(GymColor.border))
                Button(L10n.share.titleCased) { store.send(.shareButtonTapped) }
                    .buttonStyle(.primary)
            }
            .padding(20)
        }
        .gymBackground()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var preview: some View {
        switch store.kind {
        case .streak:
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    GymIcon(.flame, weight: .fill, size: 26).foregroundStyle(GymColor.accent)
                    StatValue("\(store.streak)", size: 40)
                    Kicker(L10n.shareStreakLabel, size: 11)
                }
                HeatGrid(weeks: store.activity)
            }
        case .body:
            BodyMapView(levels: store.muscleLevels)
        case .compare:
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 16).fill(GymColor.bgRaised2).aspectRatio(3 / 4, contentMode: .fit)
                RoundedRectangle(cornerRadius: 16).fill(GymColor.bgRaised2).aspectRatio(3 / 4, contentMode: .fit)
            }
        }
    }
}

public struct StravaExportView: View {
    let store: StoreOf<StravaExport>

    public init(store: StoreOf<StravaExport>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Strava").font(.gym(22, .extraBold)).foregroundStyle(GymColor.text)
                    Text(L10n.stravaBeta)
                        .font(.gym(10.5, .extraBold))
                        .foregroundStyle(GymColor.accent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(GymColor.accentSoft, in: .capsule)
                }
                .padding(.top, 12)
                Text(L10n.stravaIntro).font(.gym(14, .medium)).foregroundStyle(GymColor.textSecondary)
                if store.workouts.isEmpty {
                    Text(L10n.stravaEmpty).font(.gym(14, .semibold)).foregroundStyle(GymColor.textTertiary)
                }
                ForEach(store.workouts) { workout in
                    Button {
                        store.send(.workoutTapped(id: workout.id))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(workout.name).font(.gym(15.5, .bold)).foregroundStyle(GymColor.text)
                                Text("\(workout.date) · \(L10n.setCount(workout.sets))")
                                    .font(.gym(12.5, .medium))
                                    .foregroundStyle(GymColor.textSecondary)
                            }
                            Spacer()
                            GymIcon(.uploadSimple, size: 18).foregroundStyle(GymColor.accent)
                        }
                        .softCard(padding: 16, radius: 20)
                    }
                    .buttonStyle(.pressable)
                }
                Text(L10n.exportForStravaHint).font(.gym(12, .medium)).foregroundStyle(GymColor.textTertiary)
            }
            .padding(20)
        }
        .gymBackground()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    ShareCardView(store: Store(initialState: ShareCard.State()) { ShareCard() })
}

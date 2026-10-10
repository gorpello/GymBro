import AwardsFeature
import ComposableArchitecture
import Database
import DesignSystem
import L10n
import SwiftUI

public struct ProfileView: View {
    @Bindable var store: StoreOf<Profile>

    public init(store: StoreOf<Profile>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                banner
                VStack(alignment: .leading, spacing: 24) {
                    identity
                    stats
                    if summary.gamification {
                        medals
                    }
                    photos
                    year
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea(edges: .top)
        .gymBackground()
        .toolbar(.hidden, for: .navigationBar)
        .task { await store.send(.task).finish() }
        .sheet(item: $store.scope(state: \.edit, action: \.edit)) { editStore in
            ProfileEditView(store: editStore)
                .presentationDetents([.large])
        }
    }

    private var summary: ProfileSummary { store.summary }

    /// The profile's name; until one is set, a prompt to fill it in.
    private var displayName: String {
        summary.profile.name.isEmpty ? L10n.yourProfile : summary.profile.name
    }

    /// "@handle · 78 kg", without the handle until there is one.
    private var subtitle: String {
        let weight = ProfileFormat.weight(kg: summary.profile.weightKg, units: summary.units)
        return summary.profile.handle.isEmpty ? weight : "@\(summary.profile.handle) · \(weight)"
    }

    private var banner: some View {
        ZStack(alignment: .bottom) {
            // The photo fills a container sized by the screen, so its own aspect ratio can't widen the layout.
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .overlay {
                    GymImage.bannerDefault
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .overlay {
                    LinearGradient(colors: [.clear, GymColor.bg], startPoint: .center, endPoint: .bottom)
                }
                .accessibilityHidden(true)
            HStack(alignment: .bottom) {
                GymImage.profileDefault
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(.circle)
                    .overlay(Circle().strokeBorder(GymColor.bg, lineWidth: 3))
                Spacer()
                Button(L10n.editProfile) { store.send(.editProfileButtonTapped) }
                    .buttonStyle(.ghost)
            }
            .padding(.horizontal, 20)
            .offset(y: 30)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 10) {
                RoundButton(.shareNetwork, label: L10n.share, size: 44) { store.send(.shareButtonTapped) }
                RoundButton(.gear, label: L10n.settings.titleCased, size: 44) { store.send(.settingsButtonTapped) }
            }
            .padding(.top, 60)
            .padding(.trailing, 20)
        }
        .padding(.bottom, 44)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(displayName)
                    .font(.gym(28, .extraBold, relativeTo: .largeTitle))
                    .foregroundStyle(GymColor.text)
                GymIcon(.sealCheck, weight: .fill, size: 22)
                    .foregroundStyle(Color(argb: 0xFF3B8DF0))
            }
            Text(subtitle)
                .font(.gym(15, .medium))
                .foregroundStyle(GymColor.textSecondary)
            if summary.gamification {
                level
            }
        }
    }

    private var level: some View {
        HStack(spacing: 10) {
            Text(L10n.levelShort(summary.level))
                .font(.gym(14, .bold))
                .foregroundStyle(GymColor.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(GymColor.bgRaised2, in: .capsule)
            Text(L10n.levelToNext(n: summary.workoutsToNextLevel, next: summary.level + 1))
                .font(.gym(14, .medium))
                .foregroundStyle(GymColor.textSecondary)
        }
    }

    private var stats: some View {
        let totals = summary.totals
        let trained = ProfileFormat.trained(seconds: totals.trainingSeconds)
        let lifted = ProfileFormat.lifted(kg: totals.volumeKg, units: summary.units)
        return ScrollView(.horizontal) {
            HStack(spacing: 28) {
                StatBlock(L10n.statWorkouts, value: "\(totals.workoutCount)")
                StatBlock(L10n.statTrained, value: trained.value, unit: trained.unit)
                StatBlock(L10n.statSets, value: "\(totals.setCount)")
                StatBlock(L10n.statLifted, value: lifted.value, unit: lifted.unit)
                StatBlock(L10n.statStreak, value: "\(totals.streak)", unit: L10n.statDays)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -20)
    }

    private var medals: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                store.send(.medalsButtonTapped)
            } label: {
                SectionHeader(L10n.awardsTitle) {
                    GymIcon(.caretRight, weight: .bold, size: 14)
                        .foregroundStyle(GymColor.textSecondary)
                }
                .overlay(alignment: .leading) {
                    Text("\(summary.medalCount)")
                        .font(.gym(20, .semibold))
                        .foregroundStyle(GymColor.textTertiary)
                        .offset(x: 96)
                }
            }
            .buttonStyle(.plain)
            HStack(alignment: .top) {
                ForEach(summary.shelf) { medal in
                    VStack(spacing: 10) {
                        MedalImage(medal.kind.rawValue, locked: !medal.isEarned)
                            .frame(width: 70, height: 70)
                            .overlay(alignment: .topTrailing) {
                                if medal.isNew {
                                    Circle().fill(GymColor.accent).frame(width: 10, height: 10)
                                }
                            }
                        Text(medal.kind.name)
                            .font(.gym(12, .semibold))
                            .foregroundStyle(GymColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var photos: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                store.send(.photosButtonTapped)
            } label: {
                SectionHeader(L10n.snapshots) {
                    GymIcon(.caretRight, weight: .bold, size: 14)
                        .foregroundStyle(GymColor.textSecondary)
                }
            }
            .buttonStyle(.plain)
            HStack(spacing: 12) {
                Button {
                    store.send(.photosButtonTapped)
                } label: {
                    VStack(spacing: 14) {
                        ZStack {
                            ForEach(0..<3, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(GymColor.bgRaised2)
                                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(GymColor.border))
                                    .frame(width: 70, height: 90)
                                    .rotationEffect(.degrees(Double(i - 1) * 9))
                                    .offset(x: CGFloat(i - 1) * 26)
                            }
                        }
                        .frame(height: 100)
                        HStack(spacing: 6) {
                            Text(L10n.photosCard).foregroundStyle(GymColor.text)
                            Text("\(summary.momentCount)").foregroundStyle(GymColor.textTertiary)
                        }
                        .font(.gym(16, .bold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(GymColor.bgRaised, in: .rect(cornerRadius: 24))
                }
                .buttonStyle(.pressable)
                Button {
                    store.send(.takePhotoButtonTapped)
                } label: {
                    VStack(spacing: 22) {
                        GymIcon(.camera, size: 24)
                            .foregroundStyle(GymColor.text)
                            .frame(width: 72, height: 72)
                            .background(GymColor.bgRaised2, in: .circle)
                        Text(L10n.snapNow)
                            .font(.gym(16, .bold))
                            .foregroundStyle(GymColor.text)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(GymColor.bgRaised, in: .rect(cornerRadius: 24))
                }
                .buttonStyle(.pressable)
            }
        }
    }

    private var year: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(L10n.yearTitle)
            let months = summary.yearMonths
            let peak = max(months.max() ?? 1, 1)
            let initials = Calendar.current.veryShortStandaloneMonthSymbols
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(initials.indices, id: \.self) { month in
                    let value = month < months.count ? months[month] : 0
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(value > 0 ? GymColor.accent : GymColor.heatEmpty)
                            .frame(height: max(6, 80 * CGFloat(value) / CGFloat(peak)))
                        Text(initials[month])
                            .font(.gym(10.5, .semibold))
                            .foregroundStyle(GymColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 104, alignment: .bottom)
            .softCard(padding: 18, radius: 24)
        }
    }
}

#Preview {
    ProfileView(store: previewStore())
}

/// A store backed by a database seeded with a month of training.
@MainActor
private func previewStore() -> StoreOf<Profile> {
    prepareDependencies {
        // swiftlint:disable:next force_try
        try! $0.bootstrapDatabase()
        // swiftlint:disable:next force_try
        try! $0.seedDatabaseForPreviews()
    }
    return Store(initialState: Profile.State()) { Profile() }
}

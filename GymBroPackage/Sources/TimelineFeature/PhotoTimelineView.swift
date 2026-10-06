import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct PhotoTimelineView: View {
    @Bindable var store: StoreOf<Timeline>

    public init(store: StoreOf<Timeline>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                modePicker
                switch store.mode {
                case .photos: photos
                case .body: muscleMaps
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .gymScreen(L10n.timeline, subtitle: L10n.sessionsLogged(store.sessionCount))
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            modeButton(L10n.timelinePhotos, icon: .image, mode: .photos)
            modeButton(L10n.timelineBody, icon: .person, mode: .body)
        }
        .padding(5)
        .background(GymColor.bgRaised, in: .capsule)
        .overlay(Capsule().strokeBorder(GymColor.border))
        .animation(.snappy(duration: 0.2), value: store.mode)
    }

    private func modeButton(_ title: String, icon: Ph, mode: Timeline.Mode) -> some View {
        let selected = store.mode == mode
        return Button {
            store.mode = mode
        } label: {
            HStack(spacing: 8) {
                GymIcon(icon, size: 16)
                Text(title)
            }
            .font(.gym(15, .semibold))
            .foregroundStyle(selected ? GymColor.onEmber : GymColor.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(selected ? GymColor.ember : .clear, in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder
    private var photos: some View {
        Text(L10n.timelineHint).font(.gym(14, .medium)).foregroundStyle(GymColor.textSecondary)
        Button(L10n.addTodayPhotos.titleCased) { store.send(.addPhotosButtonTapped) }
            .buttonStyle(.primary)
        if store.photoDays.count > 1 {
            Button(L10n.compare.titleCased) { store.send(.compareButtonTapped) }
                .buttonStyle(.ghost)
        }
        if store.photoDays.isEmpty {
            EmptyStateView(icon: .camera, title: L10n.timelineEmptyTitle, message: L10n.compareNeedTwo)
        }
        ForEach(store.photoDays) { day in
            rail {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(L10n.dayNumber(day.dayNumber)).font(.gym(16, .extraBold)).foregroundStyle(GymColor.text)
                        Spacer()
                        Text(day.date).font(.gym(13, .medium)).foregroundStyle(GymColor.textSecondary)
                    }
                    HStack(spacing: 8) {
                        ForEach(day.poses, id: \.self) { pose in
                            RoundedRectangle(cornerRadius: 14)
                                .fill(GymColor.bgRaised2)
                                .aspectRatio(3 / 4, contentMode: .fit)
                                .overlay(alignment: .bottomLeading) {
                                    Text(L10n.poseName(pose)).font(.gym(11, .bold)).foregroundStyle(
                                        GymColor.textSecondary
                                    ).padding(8)
                                }
                                .accessibilityLabel(L10n.posePhoto(L10n.poseName(pose)))
                        }
                    }
                }
                .contextMenu {
                    Button(L10n.deleteEntryTitle, role: .destructive) { store.send(.deleteDayTapped(id: day.id)) }
                }
            }
        }
    }

    @ViewBuilder
    private var muscleMaps: some View {
        Text(L10n.timelineBodyHint).font(.gym(14, .medium)).foregroundStyle(GymColor.textSecondary)
        Kicker(L10n.timelineEvery, size: 11, spacing: 2)
        SegToggle([(15, "15"), (30, "30"), (60, "60"), (90, "90")], selection: $store.groupEvery, fontSize: 15)
        HeatLegend(low: L10n.heatLow, high: L10n.heatHigh)
        if store.bodyWindows.isEmpty {
            Text(L10n.timelineBodyEmpty).font(.gym(14, .medium)).foregroundStyle(GymColor.textSecondary)
        }
        ForEach(store.bodyWindows) { window in
            rail {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(window.id).font(.gym(16, .extraBold)).foregroundStyle(GymColor.text)
                        Spacer()
                        Text(L10n.sessionCount(window.sessions)).font(.gym(13, .medium)).foregroundStyle(
                            GymColor.textSecondary)
                    }
                    BodyMapView(levels: window.levels)
                        .padding(16)
                        .background(GymColor.bgRaised, in: .rect(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(GymColor.border))
                }
            }
        }
    }

    /// Dot + dashed rail on the left of each entry.
    private func rail(@ViewBuilder content: () -> some View) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 4) {
                Circle().fill(GymColor.accent).frame(width: 12, height: 12).padding(.top, 4)
                DashedRail()
            }
            .frame(width: 12)
            content()
        }
    }
}

#Preview {
    NavigationStack {
        PhotoTimelineView(store: Store(initialState: Timeline.State()) { Timeline() })
    }
}

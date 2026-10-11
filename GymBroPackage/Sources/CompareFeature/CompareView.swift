import ComposableArchitecture
import Database
import DesignSystem
import L10n
import SwiftUI

public struct CompareView: View {
    @Bindable var store: StoreOf<Compare>

    public init(store: StoreOf<Compare>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if let pair = store.comparison.pair, let pose = store.shownPose {
                pairView(pair, pose: pose)
            } else {
                Text(L10n.compareNeedTwo)
                    .font(.gym(15, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .gymScreen(L10n.compare)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.shareButtonTapped)
                } label: {
                    GymIcon(.shareNetwork, size: 18)
                }
                .accessibilityLabel(L10n.share)
                .disabled(store.comparison.pair == nil)
            }
        }
        .task { await store.send(.task).finish() }
    }

    private func pairView(_ pair: ComparePair, pose: String) -> some View {
        VStack(spacing: 16) {
            SegToggle(
                pair.poses.map { ($0, L10n.poseName($0)) },
                selection: Binding(get: { pose }, set: { store.pose = $0 }),
                fontSize: 13
            )
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 26).fill(GymColor.bgRaised2)
                    RoundedRectangle(cornerRadius: 26).fill(GymColor.bgRaised)
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: proxy.size.width * store.reveal)
                        }
                    Rectangle()
                        .fill(GymColor.text)
                        .frame(width: 2)
                        .offset(x: proxy.size.width * store.reveal - 1)
                }
                .overlay(alignment: .bottom) {
                    HStack {
                        Text(pair.before.date.formatted(.dateTime.month(.abbreviated).day()))
                        Spacer()
                        Text(pair.after.date.formatted(.dateTime.month(.abbreviated).day()))
                    }
                    .font(.gym(13, .bold))
                    .foregroundStyle(GymColor.text)
                    .padding(16)
                }
                .contentShape(.rect)
                .gesture(
                    DragGesture(minimumDistance: 0).onChanged { value in
                        store.reveal = min(1, max(0, value.location.x / proxy.size.width))
                    }
                )
            }
            .aspectRatio(3 / 4, contentMode: .fit)
            Text(L10n.daysApart(pair.daysApart))
                .font(.gym(15, .bold))
                .foregroundStyle(GymColor.textSecondary)
            Spacer()
        }
        .padding(20)
    }
}

#Preview {
    NavigationStack {
        CompareView(store: previewStore())
    }
}

/// A store backed by a database seeded with a month of training.
@MainActor
private func previewStore() -> StoreOf<Compare> {
    prepareDependencies {
        // swiftlint:disable:next force_try
        try! $0.bootstrapDatabase()
        // swiftlint:disable:next force_try
        try! $0.seedDatabaseForPreviews()
    }
    return Store(initialState: Compare.State()) { Compare() }
}

import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct CompareView: View {
    @Bindable var store: StoreOf<Compare>

    public init(store: StoreOf<Compare>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            SegToggle(["front", "side", "back"].map { ($0, L10n.poseName($0)) }, selection: $store.pose, fontSize: 13)
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
                        Text(store.beforeDate)
                        Spacer()
                        Text(store.afterDate)
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
            Text(L10n.daysApart(store.daysApart))
                .font(.gym(15, .bold))
                .foregroundStyle(GymColor.textSecondary)
            Spacer()
        }
        .padding(20)
        .gymScreen(L10n.compare)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.shareButtonTapped)
                } label: {
                    GymIcon(.shareNetwork, size: 18)
                }
                .accessibilityLabel(L10n.share)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CompareView(store: Store(initialState: Compare.State()) { Compare() })
    }
}

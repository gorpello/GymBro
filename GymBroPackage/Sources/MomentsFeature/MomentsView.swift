import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct MomentsView: View {
    let store: StoreOf<Moments>
    
    public init(store: StoreOf<Moments>) {
        self.store = store
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if store.groups.isEmpty {
                    EmptyStateView(
                        icon: .images,
                        title: L10n.momentsEmptyTitle,
                        message: L10n.momentsEmptyHint
                    )
                }
                ForEach(store.groups) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Kicker(group.id, size: 11, spacing: 2)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                            ForEach(group.photos, id: \.self) { photo in
                                Button {
                                    store.send(.photoTapped(id: photo))
                                } label: {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(GymColor.bgRaised2)
                                        .aspectRatio(3 / 4, contentMode: .fit)
                                }
                                .buttonStyle(.pressable)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                store.send(.takePhotoButtonTapped)
            } label: {
                Label { Text(L10n.snapNow) } icon: { GymIcon(.camera, weight: .fill, size: 16) }
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .gymScreen(L10n.photosCard, subtitle: L10n.momentCount(store.groups.map(\.photos.count).reduce(0, +)))
    }
}

#Preview {
    NavigationStack {
        MomentsView(store: Store(initialState: Moments.State()) { Moments() })
    }
}

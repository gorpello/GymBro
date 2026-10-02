import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct PlacesView: View {
    let store: StoreOf<Places>
    
    public init(store: StoreOf<Places>) {
        self.store = store
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.placesHint)
                    .font(.gym(14.5, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                if store.places.isEmpty {
                    EmptyStateView(icon: .mapPin, title: L10n.placeEmptyTitle, message: L10n.placeEmptyBody)
                }
                ForEach(store.places) { place in
                    card(place, active: place.id == store.activePlaceID)
                }
                Button {
                    store.send(.newPlaceButtonTapped)
                } label: {
                    Label { Text(L10n.placeNew) } icon: { GymIcon(.plus, weight: .bold, size: 16) }
                        .font(.gym(16, .bold))
                        .foregroundStyle(GymColor.text)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(GymColor.border, lineWidth: 1.2))
                }
                .buttonStyle(.pressable)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .gymScreen(L10n.places, subtitle: store.activeName.map(L10n.placeActive) ?? L10n.placeAll)
    }
    
    private func card(_ place: PlaceRow, active: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Button {
                    store.send(.placeSelected(id: place.id))
                } label: {
                    ZStack {
                        Circle().strokeBorder(active ? GymColor.text : GymColor.textTertiary, lineWidth: 2)
                        if active {
                            Circle().fill(GymColor.ember)
                            GymIcon(.check, weight: .bold, size: 15).foregroundStyle(GymColor.onEmber)
                        }
                    }
                    .frame(width: 34, height: 34)
                }
                .buttonStyle(.pressable(scale: 0.9))
                .accessibilityLabel(place.name)
                .accessibilityAddTraits(active ? .isSelected : [])
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name).font(.gym(21, .extraBold)).foregroundStyle(GymColor.text)
                    Text(L10n.placeExercises(place.exerciseCount)).font(.gym(13.5, .medium)).foregroundStyle(GymColor.textTertiary)
                }
                Spacer()
                Button { store.send(.editButtonTapped(id: place.id)) } label: { GymIcon(.pencilSimple, size: 18) }
                    .foregroundStyle(GymColor.textSecondary)
                    .accessibilityLabel(L10n.editEntry)
                Button { store.send(.deleteButtonTapped(id: place.id)) } label: { GymIcon(.trash, size: 18) }
                    .foregroundStyle(GymColor.textSecondary)
                    .accessibilityLabel(L10n.delete)
            }
            Kicker(L10n.placeGearLabel, size: 11, spacing: 2)
            FlowLayout(spacing: 8, lineSpacing: 10) {
                ForEach(equipmentIDs, id: \.self) { id in
                    ToggleChip(L10n.equipment(id), isOn: place.equipment.contains(id)) {
                        store.send(.equipmentTapped(placeID: place.id, equipment: id))
                    }
                }
            }
            if place.equipment.contains("Barbell") {
                Button {
                    store.send(.platesButtonTapped(id: place.id))
                } label: {
                    HStack(spacing: 12) {
                        GymIcon(.circlesThree, size: 18).foregroundStyle(GymColor.textSecondary)
                        Text(L10n.placePlates).font(.gym(15, .bold)).foregroundStyle(GymColor.text)
                        Spacer()
                        DisclosureValue(place.plateSizes == 0 ? L10n.platesAll : L10n.platesOwned(place.plateSizes))
                    }
                    .padding(16)
                    .background(GymColor.bgRaised2, in: .rect(cornerRadius: 16))
                }
                .buttonStyle(.pressable(scale: 0.98))
            }
        }
        .padding(22)
        .background(GymColor.bgRaised, in: .rect(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(active ? GymColor.text : GymColor.border, lineWidth: active ? 1.5 : 1))
    }
}

#Preview {
    NavigationStack {
        PlacesView(store: Store(initialState: Places.State()) { Places() })
    }
}

import ComposableArchitecture

/// Places you train and the kit each one has, so the library only offers what fits.
@Reducer
public struct Places {
    @ObservableState
    public struct State: Equatable {
        public var activePlaceID: String? = "basement"

        // TODO: Remove templates elements
        // swiftlint:disable line_length
        public var places: [PlaceRow] = [
            .init(
                id: "basement", equipment: ["Barbell", "Dumbbell", "Bodyweight", "Kettlebell", "Rings"],
                exerciseCount: 363, name: "Basement gym", plateSizes: 3),
            .init(
                id: "hotel", equipment: ["Dumbbell", "Bodyweight"], exerciseCount: 236, name: "Hotel", plateSizes: 0),
        ]
        // swiftlint:disable line_length

        public var activeName: String? { places.first { $0.id == activePlaceID }?.name }

        public init() {}
    }

    public enum Action {
        case deleteButtonTapped(id: String)
        case editButtonTapped(id: String)
        case equipmentTapped(placeID: String, equipment: String)
        case newPlaceButtonTapped
        case placeSelected(id: String)
        case platesButtonTapped(id: String)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .deleteButtonTapped, .editButtonTapped, .newPlaceButtonTapped, .platesButtonTapped:
                return .none
            case let .equipmentTapped(placeID, equipment):
                guard let index = state.places.firstIndex(where: { $0.id == placeID }) else { return .none }
                if state.places[index].equipment.remove(equipment) == nil {
                    state.places[index].equipment.insert(equipment)
                }
                return .none
            case let .placeSelected(id):
                state.activePlaceID = state.activePlaceID == id ? nil : id
                return .none
            }
        }
    }
}

public struct PlaceRow: Equatable, Identifiable, Sendable {
    public var id: String
    public var equipment: Set<String>
    public var exerciseCount: Int
    public var name: String
    /// Plate sizes owned; 0 means everything is available.
    public var plateSizes: Int

    public init(id: String, equipment: Set<String>, exerciseCount: Int, name: String, plateSizes: Int) {
        self.id = id
        self.equipment = equipment
        self.exerciseCount = exerciseCount
        self.name = name
        self.plateSizes = plateSizes
    }
}

/// Equipment ids (`kEquipment`).
let equipmentIDs = [
    "Barbell", "Dumbbell", "Cable", "Machine", "Bodyweight", "Weighted", "Band", "Kettlebell", "Rings", "Other",
]

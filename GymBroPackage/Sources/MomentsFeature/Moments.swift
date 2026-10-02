import ComposableArchitecture

/// "Your photos": gym snaps grouped into today, this week and by month.
@Reducer
public struct Moments {
    @ObservableState
    public struct State: Equatable {
        public var groups: [MomentGroup] = [
            .init(id: "Today", photos: ["m1", "m2"]),
            .init(id: "This week", photos: ["m3", "m4", "m5"]),
            .init(id: "August", photos: ["m6", "m7", "m8", "m9"]),
        ]
        
        public init() {}
    }
    
    public enum Action {
        case photoTapped(id: String)
        case takePhotoButtonTapped
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .photoTapped, .takePhotoButtonTapped:
                return .none
            }
        }
    }
}

public struct MomentGroup: Equatable, Identifiable, Sendable {
    /// Group title: today, this week or a month name.
    public var id: String
    /// Photo file names.
    public var photos: [String]
    
    public init(id: String, photos: [String]) {
        self.id = id
        self.photos = photos
    }
}

import ComposableArchitecture
import Routing

/// Progress photos on a timeline, or the same timeline drawn as muscle maps per window.
@Reducer
public struct Timeline {
    @ObservableState
    public struct State: Equatable {
        public var groupEvery: Int = 30
        public var mode: Mode = .photos
        
        // TODO: Remove templates elements
        // swiftlint:disable line_length
        public var bodyWindows: [BodyWindow] = [
            .init(id: "Aug 21 – Sep 19", levels: ["chest": 4, "triceps": 3, "shoulders": 2, "quads": 4, "hamstrings": 2, "glutes": 3, "back": 3, "biceps": 1, "calves": 1], sessions: 14),
            .init(id: "Jul 22 – Aug 20", levels: ["chest": 3, "quads": 4, "back": 2, "glutes": 3, "shoulders": 1], sessions: 13),
        ]
        // swiftlint:enable line_length
        
        public var photoDays: [PhotoDay] = [
            .init(id: "d3", dayNumber: 90, date: "Sep 19", poses: ["front", "side", "back"]),
            .init(id: "d2", dayNumber: 45, date: "Aug 5", poses: ["front", "back"]),
            .init(id: "d1", dayNumber: 1, date: "Jun 22", poses: ["front", "side", "back"]),
        ]
        public var sessionCount: Int = 64
        
        public init() {}
    }
    
    public enum Mode: Hashable, Sendable {
        case photos, body
    }
    
    public enum Action: BindableAction {
        case addPhotosButtonTapped
        case binding(BindingAction<State>)
        case compareButtonTapped
        case delegate(Delegate)
        case deleteDayTapped(id: String)
        
        public enum Delegate {
            case navigate(Route)
        }
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { _, action in
            switch action {
            case .addPhotosButtonTapped, .binding, .delegate, .deleteDayTapped:
                return .none
            case .compareButtonTapped:
                return .send(.delegate(.navigate(.compare)))
            }
        }
    }
}

public struct BodyWindow: Equatable, Identifiable, Sendable {
    /// "Aug 21 – Sep 19".
    public var id: String
    /// Heat level 0…4 per muscle id.
    public var levels: [String: Int]
    public var sessions: Int
    
    public init(id: String, levels: [String: Int], sessions: Int) {
        self.id = id
        self.levels = levels
        self.sessions = sessions
    }
}

public struct PhotoDay: Equatable, Identifiable, Sendable {
    public var id: String
    /// "Day 12".
    public var dayNumber: Int
    public var date: String
    /// Poses shot that day: `front`, `side`, `back`.
    public var poses: [String]
    
    public init(id: String, dayNumber: Int, date: String, poses: [String]) {
        self.id = id
        self.dayNumber = dayNumber
        self.date = date
        self.poses = poses
    }
}

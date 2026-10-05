import ComposableArchitecture

/// Pick a card to share: streak and consistency, muscles worked, or before and after.
@Reducer
public struct ShareCard {
    @ObservableState
    public struct State: Equatable {
        public var kind: Kind = .streak
        
        // TODO: Remove templates elements
        // swiftlint:disable line_length
        public var activity: [[Int]] = [[0, 4, 0, 0, 0, 4, 4], [4, 0, 4, 4, 0, 0, 0], [4, 0, 4, 0, 3, 0, 4], [0, 3, 0, 4, 4, 4, 0], [0, 4, 4, 0, 0, 4, 0], [4, 0, 0, 4, 2, 0, 4], [0, 4, 0, 4, 0, 4, 0], [4, 4, 0, 0, 4, 0, 4], [0, 0, 4, 3, 0, 4, 4], [4, 0, 4, 4, 4, 0, 0], [0, 4, 0, 4, 0, 4, 4], [0, 0, 0, 4, 4, 4, 4]]
        public var muscleLevels: [String: Int] = ["chest": 4, "triceps": 3, "shoulders": 2, "quads": 4, "hamstrings": 2, "glutes": 3, "back": 3, "biceps": 1, "calves": 1]
        // swiftlint:enable line_length
        
        public var streak: Int = 4
        
        public init() {}
    }
    
    public enum Kind: Hashable, Sendable {
        case streak, body, compare
    }
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case shareButtonTapped
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { _, action in
            switch action {
            case .binding, .shareButtonTapped:
                return .none
            }
        }
    }
}

/// Export one workout as a `.fit` file for Strava.
@Reducer
public struct StravaExport {
    @ObservableState
    public struct State: Equatable {
        public var workouts: [StravaWorkout] = [
            .init(id: "w1", date: "Sat, Sep 19", name: "Push", sets: 12),
            .init(id: "w2", date: "Thu, Sep 17", name: "Legs", sets: 14),
            .init(id: "w3", date: "Wed, Sep 16", name: "Pull", sets: 12),
        ]
        
        public init() {}
    }
    
    public enum Action {
        case workoutTapped(id: String)
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .workoutTapped:
                return .none
            }
        }
    }
}

public struct StravaWorkout: Equatable, Identifiable, Sendable {
    public var id: String
    public var date: String
    public var name: String
    public var sets: Int
    
    public init(id: String, date: String, name: String, sets: Int) {
        self.id = id
        self.date = date
        self.name = name
        self.sets = sets
    }
}

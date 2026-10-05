import ComposableArchitecture

/// Bodyweight and ten body measurements, each with its own curve and history.
@Reducer
public struct Measures {
    @ObservableState
    public struct State: Equatable {
        @Presents public var entry: MeasureEntry.State?
        
        // TODO: Remove templates elements
        // swiftlint:disable line_length
        public var rows: [MeasureRowState] = [
            .init(id: "neck", history: [.init(id: "1", date: "Aug 1", value: 38.5), .init(id: "2", date: "Sep 1", value: 38)]),
            .init(id: "shoulders", history: []),
            .init(id: "chest", history: [.init(id: "1", date: "Aug 1", value: 102), .init(id: "2", date: "Sep 1", value: 103), .init(id: "3", date: "Sep 19", value: 104)]),
            .init(id: "arm", history: [.init(id: "1", date: "Aug 1", value: 36.5), .init(id: "2", date: "Sep 19", value: 37.5)]),
            .init(id: "forearm", history: []),
            .init(id: "waist", history: [.init(id: "1", date: "Aug 1", value: 84), .init(id: "2", date: "Sep 1", value: 83), .init(id: "3", date: "Sep 19", value: 82)]),
            .init(id: "hips", history: []),
            .init(id: "thigh", history: []),
            .init(id: "calf", history: []),
            .init(id: "bodyfat", history: [.init(id: "1", date: "Sep 1", value: 15), .init(id: "2", date: "Sep 19", value: 14)]),
        ]
        // swiftlint:enable line_length
        
        public var unit: String = "cm"
        
        public var readingCount: Int { rows.map(\.history.count).reduce(0, +) }
        
        public init() {}
    }
    
    public enum Action {
        case entry(PresentationAction<MeasureEntry.Action>)
        case measureTapped(key: String)
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .entry:
                return .none
            case let .measureTapped(key):
                guard let row = state.rows.first(where: { $0.id == key }) else { return .none }
                state.entry = MeasureEntry.State(key: key, value: row.history.last?.value ?? 0, history: row.history)
                return .none
            }
        }
        .ifLet(\.$entry, action: \.entry) {
            MeasureEntry()
        }
    }
}

public struct MeasureRowState: Equatable, Identifiable, Sendable {
    /// `neck`, `shoulders`, … `bodyfat`.
    public var id: String
    public var history: [MeasureReading]
    
    public init(id: String, history: [MeasureReading]) {
        self.id = id
        self.history = history
    }
}

public struct MeasureReading: Equatable, Identifiable, Sendable {
    public var id: String
    public var date: String
    public var value: Double
    
    public init(id: String, date: String, value: Double) {
        self.id = id
        self.date = date
        self.value = value
    }
}

/// Log one reading and see the history.
@Reducer
public struct MeasureEntry {
    @ObservableState
    public struct State: Equatable {
        public let key: String
        public var value: Double
        public var history: [MeasureReading]
        
        public init(key: String, value: Double, history: [MeasureReading]) {
            self.key = key
            self.value = value
            self.history = history
        }
    }
    
    public enum Action {
        case deleteReadingTapped(id: String)
        case saveButtonTapped
        case valueChanged(Double)
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .deleteReadingTapped(id):
                state.history.removeAll { $0.id == id }
                return .none
            case .saveButtonTapped:
                return .run { [dismiss] _ in await dismiss() }
            case let .valueChanged(delta):
                state.value = max(0, state.value + delta)
                return .none
            }
        }
    }
}

import ComposableArchitecture

/// All 20 medals, earned first.
@Reducer
public struct Awards {
    @ObservableState
    public struct State: Equatable {
        public var earned: [AwardRow] = [
            .init(id: "firstStep", name: "First step", line: "Open the app and set it up", date: "Jun 2"),
            .init(id: "firstWorkout", name: "First workout", line: "Log your first session", date: "Jun 3"),
            .init(id: "firstRoutine", name: "First routine", line: "Build your first routine", date: "Jun 5"),
            .init(id: "firstRecord", name: "First record", line: "Beat your best on any lift", date: "Jun 10"),
            .init(id: "streak3", name: "On a roll", line: "Train three days in a row", date: "Jun 12"),
            .init(id: "workouts10", name: "Ten down", line: "Log ten workouts", date: "Jul 1"),
        ]
        public var locked: [AwardRow] = [
            .init(id: "streak30", name: "Iron month", line: "Train 30 days in a row", date: nil),
            .init(id: "tonnes100", name: "Hundred tonnes", line: "Lift 100 t in total", date: nil),
            .init(id: "workouts365", name: "A year of it", line: "Log 365 workouts", date: nil),
        ]
        
        public init() {}
    }
    
    public enum Action {
        case medalTapped(id: String)
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .medalTapped:
                return .none
            }
        }
    }
}

public struct AwardRow: Equatable, Identifiable, Sendable {
    /// Award id, also the artwork name under `Badges/`.
    public var id: String
    public var name: String
    public var line: String
    public var date: String?
    
    public init(id: String, name: String, line: String, date: String?) {
        self.id = id
        self.name = name
        self.line = line
        self.date = date
    }
}

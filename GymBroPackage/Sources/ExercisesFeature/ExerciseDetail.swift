import ComposableArchitecture
import Routing

/// One exercise: live demo, muscles, next-time target, record, goal, history, notes, steps,
/// similar moves and per-exercise settings.
@Reducer
public struct ExerciseDetail {
    @ObservableState
    public struct State: Equatable {
        public let id: String

        public var art: String = "bench-press"
        public var autoProgress: Bool = true
        public var autoWarmup: Bool = false
        public var equipment: String = "Barbell"
        public var goal: String? = "100 kg × 5"
        public var goalProgress: Double = 0.8
        public var history: [HistoryRow] = [
            .init(id: "1", date: "Sep 19", sets: 4, topWeight: "92.5 kg", volume: "2.6 t"),
            .init(id: "2", date: "Sep 18", sets: 4, topWeight: "92.5 kg", volume: "2.6 t"),
            .init(id: "3", date: "Sep 16", sets: 4, topWeight: "91 kg", volume: "2.5 t"),
            .init(id: "4", date: "Sep 4", sets: 4, topWeight: "89.5 kg", volume: "2.5 t"),
        ]
        public var name: String = "Barbell Bench Press"
        public var nextTime: String? = "92.5 kg × 8"
        public var noteCount: Int = 1
        public var personalRecord: String? = "92.5 kg"
        public var personalRecordDate: String = "Sep 19"
        public var primary: String = "chest"
        public var restSeconds: Int = 150
        public var secondary: [String] = ["triceps", "shoulders"]
        public var similar: [SimilarRow] = [
            .init(id: "SpYC0Kp", art: "dumbbell-bench-press", name: "Dumbbell Bench Press"),
            .init(id: "3TZduzM", art: "incline-bench-press", name: "Barbell Incline Bench Press"),
            .init(id: "x1", art: "smith-machine-bench-press", name: "Smith Machine Bench Press"),
        ]
        public var steps: [String] = [
            "Lie flat on a bench with your feet flat on the ground and your back pressed against the bench.",
            "Grasp the barbell with an overhand grip slightly wider than shoulder-width apart.",
            "Lift the barbell off the rack and hold it directly above your chest with your arms fully extended.",
            "Lower the barbell slowly towards your chest, keeping your elbows tucked in.",
            "Pause for a moment when the barbell touches your chest.",
        ]
        public var suggestInWorkouts: Bool = true

        public init(id: String) {
            self.id = id
        }
    }

    public enum Action: BindableAction {
        case archiveButtonTapped
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case deleteButtonTapped
        case editButtonTapped
        case notesButtonTapped
        case restDecrementButtonTapped
        case restIncrementButtonTapped
        case similarTapped(id: String)

        public enum Delegate {
            case navigate(Route)
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .archiveButtonTapped, .binding, .delegate, .deleteButtonTapped, .editButtonTapped:
                return .none
            case .notesButtonTapped:
                return .send(.delegate(.navigate(.notes)))
            case .restDecrementButtonTapped:
                state.restSeconds = max(0, state.restSeconds - 15)
                return .none
            case .restIncrementButtonTapped:
                state.restSeconds += 15
                return .none
            case let .similarTapped(id):
                return .send(.delegate(.navigate(.exerciseDetail(id: id))))
            }
        }
    }
}

public struct HistoryRow: Equatable, Identifiable, Sendable {
    public var id: String
    public var date: String
    public var sets: Int
    public var topWeight: String
    public var volume: String

    public init(id: String, date: String, sets: Int, topWeight: String, volume: String) {
        self.id = id
        self.date = date
        self.sets = sets
        self.topWeight = topWeight
        self.volume = volume
    }
}

public struct SimilarRow: Equatable, Identifiable, Sendable {
    public var id: String
    public var art: String
    public var name: String

    public init(id: String, art: String, name: String) {
        self.id = id
        self.art = art
        self.name = name
    }
}

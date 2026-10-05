import ComposableArchitecture
import Routing

/// The Progress tab: volume and weight tiles, consistency, all-time totals, muscle map,
/// strength curves, records, photo timeline and body measurements.
@Reducer
public struct ProgressOverview {
    @ObservableState
    public struct State: Equatable {
        public var muscleRange: MuscleRange = .days7
        
        /// Consistency grid, `activity[week][weekday]`, levels 0…4.
        // TODO: Remove templates elements
        // swiftlint:disable line_length
        public var activity: [[Int]] = [[0, 4, 0, 0, 0, 4, 4], [4, 0, 4, 4, 0, 0, 0], [4, 0, 4, 0, 3, 0, 4], [0, 3, 0, 4, 4, 4, 0], [0, 4, 4, 0, 0, 4, 0], [4, 0, 0, 4, 2, 0, 4], [0, 4, 0, 4, 0, 4, 0], [4, 4, 0, 0, 4, 0, 4], [0, 0, 4, 3, 0, 4, 4], [4, 0, 4, 4, 4, 0, 0], [0, 4, 0, 4, 0, 4, 4], [0, 0, 0, 4, 4, 4, 4]]
        public var measureRows: [MeasureRow] = [
            .init(id: "neck", value: "38", unit: "cm"),
            .init(id: "chest", value: "104", unit: "cm"),
            .init(id: "arm", value: "37.5", unit: "cm"),
            .init(id: "waist", value: "82", unit: "cm"),
            .init(id: "thigh", value: nil, unit: "cm"),
            .init(id: "bodyfat", value: "14", unit: "%"),
        ]
        
        /// Heat level 0…4 per muscle id for the last 7 days.
        public var muscleLevels7: [String: Int] = ["chest": 4, "triceps": 3, "shoulders": 2, "quads": 4, "hamstrings": 2, "glutes": 3, "back": 3, "biceps": 1, "calves": 1]
        /// Heat level 0…4 per muscle id for the last 30 days.
        public var muscleLevels30: [String: Int] = ["chest": 4, "triceps": 4, "shoulders": 3, "quads": 4, "hamstrings": 3, "glutes": 4, "back": 4, "biceps": 3, "calves": 2, "abdomen": 1, "trapezius": 2, "forearm": 1]
        // swiftlint:enable line_length
        
        
        /// Recovery level 0 (fresh) … 4 (fatigued) per muscle id.
        public var recoveryLevels: [String: Int] = ["chest": 4, "triceps": 3, "shoulders": 2, "quads": 1]
        public var recoveryPercent: Int = 72
        public var photoCount: Int = 3
        public var records: [RecordRow] = [
            .init(id: "EIeI8Vf", name: "Barbell Bench Press", best: "92.5 kg", date: "Sep 19"),
            .init(id: "squat", name: "Barbell Full Squat", best: "120 kg", date: "Sep 17"),
            .init(id: "deadlift", name: "Barbell Deadlift", best: "150 kg", date: "Sep 12"),
        ]
        public var setsThisWeek: [Int] = [0, 0, 12, 10, 14, 10, 0]
        public var strength: [StrengthRow] = [
            .init(id: "EIeI8Vf", name: "Barbell Bench Press", bestOneRm: "110 kg", curve: [95, 98, 101, 104, 108, 110]),
            .init(id: "squat", name: "Barbell Full Squat", bestOneRm: "142 kg", curve: [120, 124, 128, 133, 138, 142]),
        ]
        public var streak: Int = 4
        public var totalHours: String = "60"
        public var totalSessions: Int = 64
        public var totalSets: Int = 640
        public var volume30: String = "98.4"
        public var volumeTrend: [Double] = [60, 64, 70, 72, 78, 80, 79, 88, 92, 98]
        public var volumeTrendPercent: String = "16%"
        public var volumeUnit: String = "t"
        public var weeklyGoal: Int = 4
        public var weeklySessions: Int = 4
        public var weight: String? = "81.4"
        public var weightDate: String = "Sep 19"
        public var weightTrend: [Double] = [78, 78.6, 79.4, 80, 80.2, 81, 81.4]
        public var weightUnit: String = "kg"
        
        public init() {}
    }
    
    public enum MuscleRange: Hashable, Sendable {
        case days7, days30, recovery
    }
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case compareButtonTapped
        case delegate(Delegate)
        case exerciseTapped(id: String)
        case measuresButtonTapped
        case shareButtonTapped
        case timelineButtonTapped
        
        public enum Delegate {
            case navigate(Route)
        }
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { _, action in
            switch action {
            case .binding, .delegate:
                return .none
            case .compareButtonTapped:
                return .send(.delegate(.navigate(.compare)))
            case let .exerciseTapped(id):
                return .send(.delegate(.navigate(.exerciseDetail(id: id))))
            case .measuresButtonTapped:
                return .send(.delegate(.navigate(.measures)))
            case .shareButtonTapped:
                return .send(.delegate(.navigate(.share)))
            case .timelineButtonTapped:
                return .send(.delegate(.navigate(.timeline)))
            }
        }
    }
}

public struct StrengthRow: Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var bestOneRm: String
    public var curve: [Double]
    
    public init(id: String, name: String, bestOneRm: String, curve: [Double]) {
        self.id = id
        self.name = name
        self.bestOneRm = bestOneRm
        self.curve = curve
    }
}

public struct RecordRow: Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var best: String
    public var date: String
    
    public init(id: String, name: String, best: String, date: String) {
        self.id = id
        self.name = name
        self.best = best
        self.date = date
    }
}

public struct MeasureRow: Equatable, Identifiable, Sendable {
    /// Measure key: `neck`, `waist`, … `bodyfat`.
    public var id: String
    public var value: String?
    public var unit: String
    
    public init(id: String, value: String?, unit: String) {
        self.id = id
        self.value = value
        self.unit = unit
    }
}

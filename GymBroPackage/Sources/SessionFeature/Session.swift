import ComposableArchitecture
import Routing

/// The live workout: one exercise at a time with its demo, rest timer and set table,
/// a lock screen, an overview of all exercises and the finish summary.
@Reducer
public struct Session {
    @ObservableState
    public struct State: Equatable {
        public var currentIndex = 0
        public var isFinished = false
        public var isLocked = false
        public var isPaused = false
        public var showsOverview = false
        
        public var elapsed: String = "00:03"
        
        // TODO: Remove templates elements
        // swiftlint:disable line_length
        public var exercises: [SessionExercise] = [
            .init(id: "EIeI8Vf", art: "bench-press", last: "90×8 · 90×8 · 92.5×6 · 92.5×6", muscle: "chest", name: "Barbell Bench Press", next: "92.5 kg × 8", sets: [.init(id: 1, kind: .normal, reps: 8, weight: 90, done: true), .init(id: 2, kind: .normal, reps: 8, weight: 90, done: true), .init(id: 3, kind: .normal, reps: 6, weight: 92.5, done: false), .init(id: 4, kind: .normal, reps: 6, weight: 92.5, done: false)]),
            .init(id: "ns0SIbU", art: "incline-dumbbell-press", last: "30×10 · 30×10 · 30×9", muscle: "chest", name: "Dumbbell Incline Bench Press", next: "30 kg × 10", sets: [.init(id: 1, kind: .normal, reps: 10, weight: 30, done: false), .init(id: 2, kind: .normal, reps: 10, weight: 30, done: false), .init(id: 3, kind: .normal, reps: 10, weight: 30, done: false)]),
            .init(id: "ohp", art: "overhead-press", last: nil, muscle: "shoulders", name: "Overhead Press", next: nil, sets: [.init(id: 1, kind: .normal, reps: 8, weight: 50, done: false), .init(id: 2, kind: .normal, reps: 8, weight: 50, done: false), .init(id: 3, kind: .normal, reps: 8, weight: 50, done: false)]),
            .init(id: "tri1", art: "rope-tricep-pushdown", last: "25×12 · 25×12", muscle: "triceps", name: "Rope Triceps Pushdown", next: "27.5 kg × 12", sets: [.init(id: 1, kind: .normal, reps: 12, weight: 25, done: false), .init(id: 2, kind: .normal, reps: 12, weight: 25, done: false)]),
        ]
        // swiftlint:enable line_length
        
        /// Rest countdown ("2:30"); `nil` when not resting.
        public var restRemaining: String? = "2:30"
        /// Rest progress from 1 (just started) to 0 (over).
        public var restProgress: Double = 0.85
        
        // TODO: Remove templates elements
        // swiftlint:disable line_length
        public var summary: SessionSummary? = SessionSummary(duration: "58 min", prCount: 2, volume: "8.4", volumeUnit: "t", vsLastTime: "+320 kg volume, one more set")
        // swiftlint:enable line_length
        
        public var unit: String = "kg"
        
        public var current: SessionExercise? {
            exercises.indices.contains(currentIndex) ? exercises[currentIndex] : nil
        }
        
        public var setsDone: Int { exercises.flatMap(\.sets).filter(\.done).count }
        public var setsTotal: Int { exercises.flatMap(\.sets).count }
        
        public init() {}
    }
    
    public enum Action: BindableAction {
        case addExerciseButtonTapped
        case addSetButtonTapped
        case addWarmupButtonTapped
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case doneButtonTapped
        case exerciseSelected(index: Int)
        case finishButtonTapped
        case lockButtonTapped
        case nextExerciseButtonTapped
        case overviewButtonTapped
        case pauseButtonTapped
        case repsChanged(setID: Int, delta: Int)
        case restAdjustButtonTapped(seconds: Int)
        case saveAsRoutineButtonTapped
        case setDoneButtonTapped(setID: Int)
        case shareButtonTapped
        case skipRestButtonTapped
        case stickerButtonTapped
        case unlockCompleted
        case weightChanged(setID: Int, delta: Double)
        
        public enum Delegate {
            case navigate(Route)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .addExerciseButtonTapped, .binding, .delegate, .restAdjustButtonTapped,
                    .saveAsRoutineButtonTapped, .skipRestButtonTapped:
                return .none
            case .addSetButtonTapped:
                guard let last = state.current?.sets.last else { return .none }
                state.exercises[state.currentIndex].sets.append(
                    SessionSet(id: last.id + 1, kind: .normal, reps: last.reps, weight: last.weight, done: false)
                )
                return .none
            case .addWarmupButtonTapped:
                guard let first = state.current?.sets.first else { return .none }
                state.exercises[state.currentIndex].sets.insert(
                    SessionSet(id: (state.current?.sets.map(\.id).max() ?? 0) + 1, kind: .warmup, reps: first.reps, weight: first.weight / 2, done: false),
                    at: 0
                )
                return .none
            case .doneButtonTapped:
                return .run { [dismiss] _ in await dismiss() }
            case let .exerciseSelected(index):
                state.currentIndex = index
                state.showsOverview = false
                return .none
            case .finishButtonTapped:
                state.isFinished = true
                return .none
            case .lockButtonTapped:
                state.isLocked = true
                return .none
            case .nextExerciseButtonTapped:
                state.currentIndex = min(state.currentIndex + 1, state.exercises.count - 1)
                return .none
            case .overviewButtonTapped:
                state.showsOverview = true
                return .none
            case .pauseButtonTapped:
                state.isPaused.toggle()
                return .none
            case let .repsChanged(setID, delta):
                state.updateSet(setID) { $0.reps = max(0, $0.reps + delta) }
                return .none
            case let .setDoneButtonTapped(setID):
                state.updateSet(setID) { $0.done.toggle() }
                return .none
            case .shareButtonTapped:
                return .send(.delegate(.navigate(.share)))
            case .stickerButtonTapped:
                return .send(.delegate(.navigate(.sticker)))
            case .unlockCompleted:
                state.isLocked = false
                return .none
            case let .weightChanged(setID, delta):
                state.updateSet(setID) { $0.weight = max(0, $0.weight + delta) }
                return .none
            }
        }
    }
}

extension Session.State {
    mutating func updateSet(_ id: Int, _ update: (inout SessionSet) -> Void) {
        guard
            exercises.indices.contains(currentIndex),
            let index = exercises[currentIndex].sets.firstIndex(where: { $0.id == id })
                else { return }
        update(&exercises[currentIndex].sets[index])
    }
}

public struct SessionExercise: Equatable, Identifiable, Sendable {
    public var id: String
    public var art: String
    /// "90×8 · 90×8 · 92.5×6" from the last time.
    public var last: String?
    public var muscle: String
    public var name: String
    /// "92.5 kg × 8".
    public var next: String?
    public var sets: [SessionSet]
    
    public init(id: String, art: String, last: String?, muscle: String, name: String, next: String?, sets: [SessionSet]) {
        self.id = id
        self.art = art
        self.last = last
        self.muscle = muscle
        self.name = name
        self.next = next
        self.sets = sets
    }
}

public struct SessionSet: Equatable, Identifiable, Sendable {
    public enum Kind: Sendable { case normal, warmup, drop, failure, restPause }
    
    public var id: Int
    public var kind: Kind
    public var reps: Int
    public var weight: Double
    public var done: Bool
    
    public init(id: Int, kind: Kind, reps: Int, weight: Double, done: Bool) {
        self.id = id
        self.kind = kind
        self.reps = reps
        self.weight = weight
        self.done = done
    }
}

public struct SessionSummary: Equatable, Sendable {
    public var duration: String
    public var prCount: Int
    public var volume: String
    public var volumeUnit: String
    public var vsLastTime: String?
    
    public init(duration: String, prCount: Int, volume: String, volumeUnit: String, vsLastTime: String?) {
        self.duration = duration
        self.prCount = prCount
        self.volume = volume
        self.volumeUnit = volumeUnit
        self.vsLastTime = vsLastTime
    }
}

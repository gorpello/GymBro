import ComposableArchitecture
import Foundation
import Routing

/// Build or change a routine: name, days, group, ordered exercises with sets and supersets,
/// and a library list to add from.
@Reducer
public struct RoutineEdit {
    @ObservableState
    public struct State: Equatable {
        public let id: String?
        public var searchText = ""

        /// Exercises available to add.
        public var library: [RoutineLibraryRow] = [
            .init(id: "pec", art: "pec-deck", detail: "Chest · Machine", name: "Pec Deck"),
            .init(id: "lat", art: "lateral-raise", detail: "Shoulders · Dumbbell", name: "Lateral Raise"),
            .init(id: "dip", art: "dip", detail: "Triceps · Bodyweight", name: "Dip"),
        ]
        public var exercises: [RoutineExerciseRow] = [
            .init(id: "EIeI8Vf", art: "bench-press", name: "Barbell Bench Press", sets: 4, chained: false),
            .init(
                id: "ns0SIbU", art: "incline-dumbbell-press", name: "Dumbbell Incline Bench Press", sets: 3,
                chained: true),
            .init(id: "ohp", art: "overhead-press", name: "Overhead Press", sets: 3, chained: false),
            .init(id: "tri1", art: "rope-tricep-pushdown", name: "Rope Triceps Pushdown", sets: 3, chained: false),
        ]
        public var group: String = "PPL"
        public var name: String = "Push"
        /// Weekdays (0 = Monday) this routine is planned on.
        public var weekdays: Set<Int> = [0, 5]

        public init(id: String?) {
            self.id = id
        }
    }

    public enum Action: BindableAction {
        case addExerciseTapped(id: String)
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case moveExercises(from: IndexSet, to: Int)
        case removeExerciseTapped(id: String)
        case saveButtonTapped
        case setsChanged(id: String, delta: Int)
        case startButtonTapped
        case supersetToggled(id: String)
        case weekdayTapped(Int)

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
            case let .addExerciseTapped(id):
                guard let row = state.library.first(where: { $0.id == id }) else { return .none }
                state.exercises.append(
                    RoutineExerciseRow(id: row.id, art: row.art, name: row.name, sets: 3, chained: false))
                return .none
            case .binding, .delegate:
                return .none
            case let .moveExercises(from, to):
                state.exercises.move(fromOffsets: from, toOffset: to)
                return .none
            case let .removeExerciseTapped(id):
                state.exercises.removeAll { $0.id == id }
                return .none
            case .saveButtonTapped:
                return .run { [dismiss] _ in await dismiss() }
            case let .setsChanged(id, delta):
                guard let index = state.exercises.firstIndex(where: { $0.id == id }) else { return .none }
                state.exercises[index].sets = max(1, state.exercises[index].sets + delta)
                return .none
            case .startButtonTapped:
                return .send(.delegate(.navigate(.session)))
            case let .supersetToggled(id):
                guard let index = state.exercises.firstIndex(where: { $0.id == id }) else { return .none }
                state.exercises[index].chained.toggle()
                return .none
            case let .weekdayTapped(day):
                if state.weekdays.remove(day) == nil { state.weekdays.insert(day) }
                return .none
            }
        }
    }
}

public struct RoutineExerciseRow: Equatable, Identifiable, Sendable {
    public var id: String
    public var art: String
    public var name: String
    public var sets: Int
    /// Chained to the next exercise as a superset.
    public var chained: Bool

    public init(id: String, art: String, name: String, sets: Int, chained: Bool) {
        self.id = id
        self.art = art
        self.name = name
        self.sets = sets
        self.chained = chained
    }
}

public struct RoutineLibraryRow: Equatable, Identifiable, Sendable {
    public var id: String
    public var art: String
    public var detail: String
    public var name: String

    public init(id: String, art: String, detail: String, name: String) {
        self.id = id
        self.art = art
        self.detail = detail
        self.name = name
    }
}

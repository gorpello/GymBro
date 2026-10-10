import ComposableArchitecture
import Foundation
import Routing

/// Training journal: notes grouped by day, filterable by kind, or browsed on a calendar.
@Reducer
public struct Notes {
    @ObservableState
    public struct State: Equatable {
        public var calendarDate = Date.now
        public var kindFilter: String?
        public var showsCalendar = false

        public var days: [NoteDay] = [
            .init(
                id: "TODAY", subtitle: "Saturday, Sep 19, 2026",
                notes: [
                    .init(
                        id: "n1", body: "last two were a grind, but clean", exerciseName: "Barbell Bench Press",
                        kind: "done", title: "First full 5x5 at 82.5")
                ]),
            .init(
                id: "SEP 17", subtitle: "Thursday, Sep 17, 2026",
                notes: [
                    .init(
                        id: "n2", body: "film the next heavy set", exerciseName: "Barbell Full Squat", kind: "note",
                        title: "Knees drifting in on the last rep")
                ]),
            .init(
                id: "SEP 14", subtitle: "Monday, Sep 14, 2026",
                notes: [
                    .init(
                        id: "n3", body: "warm up longer next time", exerciseName: nil, kind: "pain",
                        title: "Right shoulder tight after pressing")
                ]),
        ]

        /// Note count per kind id (`note`, `plan`, `done`, `pain`).
        public var kindCounts: [String: Int] = ["note": 1, "done": 1, "pain": 1]

        public var noteCount: Int { days.map(\.notes.count).reduce(0, +) }

        public init() {}
    }

    public enum Action: BindableAction {
        case addButtonTapped
        case binding(BindingAction<State>)
        case calendarButtonTapped
        case delegate(Delegate)
        case noteTapped(id: String)

        public enum Delegate {
            case navigate(Route)
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                return .send(.delegate(.navigate(.noteEdit(id: nil))))
            case .binding, .delegate:
                return .none
            case .calendarButtonTapped:
                state.showsCalendar.toggle()
                return .none
            case let .noteTapped(id):
                return .send(.delegate(.navigate(.noteEdit(id: id))))
            }
        }
    }
}

public struct NoteDay: Equatable, Identifiable, Sendable {
    /// "TODAY", "SEP 17".
    public var id: String
    /// "Saturday, Sep 19, 2026".
    public var subtitle: String
    public var notes: [NoteRow]

    public init(id: String, subtitle: String, notes: [NoteRow]) {
        self.id = id
        self.subtitle = subtitle
        self.notes = notes
    }
}

public struct NoteRow: Equatable, Identifiable, Sendable {
    public var id: String
    public var body: String
    public var exerciseName: String?
    /// `note`, `plan`, `done` or `pain`.
    public var kind: String
    public var title: String

    public init(id: String, body: String, exerciseName: String?, kind: String, title: String) {
        self.id = id
        self.body = body
        self.exerciseName = exerciseName
        self.kind = kind
        self.title = title
    }
}

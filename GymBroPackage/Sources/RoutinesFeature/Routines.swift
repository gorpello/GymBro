import ComposableArchitecture
import Routing

/// Weekly plan plus every routine, grouped into folders, with templates and AI import.
@Reducer
public struct Routines {
    @ObservableState
    public struct State: Equatable {
        @Presents public var templates: Templates.State?

        public var groups: [RoutineGroup] = [
            .init(
                id: "PPL",
                routines: [
                    .init(id: "push", exerciseCount: 4, hue: 3, name: "Push"),
                    .init(id: "pull", exerciseCount: 4, hue: 2, name: "Pull"),
                    .init(id: "legs", exerciseCount: 4, hue: 5, name: "Legs"),
                ])
        ]

        /// Routine name planned for each weekday, Monday first; `nil` is a rest day.
        public var weeklyPlan: [String?] = ["Push", nil, "Pull", nil, "Legs", "Push", nil]

        public init() {}
    }

    public enum Action {
        case aiRoutineButtonTapped
        case delegate(Delegate)
        case duplicateButtonTapped(id: String)
        case importButtonTapped
        case newRoutineButtonTapped
        case routineTapped(id: String)
        case shareButtonTapped
        case startButtonTapped(id: String)
        case templates(PresentationAction<Templates.Action>)
        case templatesButtonTapped
        case weekdayTapped(Int)

        public enum Delegate {
            case navigate(Route)
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .aiRoutineButtonTapped:
                return .send(.delegate(.navigate(.aiPlan)))
            case .delegate, .duplicateButtonTapped, .templates, .weekdayTapped:
                return .none
            case .importButtonTapped:
                return .send(.delegate(.navigate(.planImport)))
            case .newRoutineButtonTapped:
                return .send(.delegate(.navigate(.routineEdit(id: nil))))
            case let .routineTapped(id):
                return .send(.delegate(.navigate(.routineEdit(id: id))))
            case .shareButtonTapped:
                return .none
            case .startButtonTapped:
                return .send(.delegate(.navigate(.session)))
            case .templatesButtonTapped:
                state.templates = Templates.State()
                return .none
            }
        }
        .ifLet(\.$templates, action: \.templates) {
            Templates()
        }
    }
}

public struct RoutineGroup: Equatable, Identifiable, Sendable {
    /// Group name; empty for ungrouped routines.
    public var id: String
    public var routines: [RoutineCard]

    public init(id: String, routines: [RoutineCard]) {
        self.id = id
        self.routines = routines
    }
}

public struct RoutineCard: Equatable, Identifiable, Sendable {
    public var id: String
    public var exerciseCount: Int
    /// Index into `GymColor.folderHues`.
    public var hue: Int
    public var name: String

    public init(id: String, exerciseCount: Int, hue: Int, name: String) {
        self.id = id
        self.exerciseCount = exerciseCount
        self.hue = hue
        self.name = name
    }
}

/// "Ready-made plans": classic programmes built from the library.
@Reducer
public struct Templates {
    @ObservableState
    public struct State: Equatable {
        public var templates: [TemplateRow] = [
            .init(
                id: "fullbody", blurb: "Three full-body days a week. The simplest way to get strong.", dayCount: 3,
                name: "Full Body"),
            .init(
                id: "ppl", blurb: "Push, pull and legs, each trained twice a week.", dayCount: 6, name: "Push Pull Legs"
            ),
            .init(
                id: "upperlower", blurb: "Upper and lower body on alternating days.", dayCount: 4, name: "Upper / Lower"
            ),
        ]

        public init() {}
    }

    public enum Action {
        case templateTapped(id: String)
    }

    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .templateTapped:
                return .run { [dismiss] _ in await dismiss() }
            }
        }
    }
}

public struct TemplateRow: Equatable, Identifiable, Sendable {
    public var id: String
    public var blurb: String
    public var dayCount: Int
    public var name: String

    public init(id: String, blurb: String, dayCount: Int, name: String) {
        self.id = id
        self.blurb = blurb
        self.dayCount = dayCount
        self.name = name
    }
}

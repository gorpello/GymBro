import ComposableArchitecture
import Database
import L10n
import Routing
import SQLiteData

/// Weekly plan plus every routine, grouped into folders, with templates and AI import. Read from
/// the database (see `RoutineListing`) and kept up to date as routines change.
@Reducer
public struct Routines: Sendable {
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        @ObservationStateIgnored
        @Fetch public var listing = RoutineListing()
        @Presents public var templates: Templates.State?

        public init() {}
    }

    public enum Action {
        case aiRoutineButtonTapped
        case alert(PresentationAction<Alert>)
        case deleteButtonTapped(id: Routine.ID)
        case delegate(Delegate)
        case duplicateButtonTapped(id: Routine.ID)
        case importButtonTapped
        case newRoutineButtonTapped
        case routineTapped(id: Routine.ID)
        case shareButtonTapped
        case startButtonTapped(id: Routine.ID)
        case task
        case templates(PresentationAction<Templates.Action>)
        case templatesButtonTapped
        case weekdayTapped(Int)

        @CasePathable
        public enum Alert: Equatable {
            case confirmDeleteButtonTapped(id: Routine.ID)
        }

        @CasePathable
        public enum Delegate {
            case navigate(Route)
        }
    }

    @Dependency(\.defaultDatabase) var database
    @Dependency(\.date.now) var now

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .aiRoutineButtonTapped:
                return .send(.delegate(.navigate(.aiPlan)))
            case let .alert(.presented(.confirmDeleteButtonTapped(id))):
                return .run { _ in
                    await withErrorReporting {
                        try await database.write { db in
                            try Routine.find(id).delete().execute(db)
                        }
                    }
                }
            case let .deleteButtonTapped(id):
                guard let routine = state.listing.routine(id: id) else { return .none }
                state.alert = .deleteRoutine(id: id, title: routine.title)
                return .none
            case .alert, .delegate, .shareButtonTapped, .templates, .weekdayTapped:
                return .none
            case let .duplicateButtonTapped(id):
                guard let routine = state.listing.routine(id: id) else { return .none }
                let name = L10n.copySuffix(routine.title)
                return .run { _ in
                    await withErrorReporting {
                        try await database.write { db in
                            try Routine.duplicate(db, id: id, name: name)
                        }
                    }
                }
            case .importButtonTapped:
                return .send(.delegate(.navigate(.planImport)))
            case .newRoutineButtonTapped:
                return .send(.delegate(.navigate(.routineEdit(id: nil))))
            case let .routineTapped(id):
                return .send(.delegate(.navigate(.routineEdit(id: id))))
            case let .startButtonTapped(id):
                // Starting while a workout is in progress resumes it instead (see `LiveWorkout.start`).
                return .run { [now] send in
                    await withErrorReporting {
                        _ = try await database.write { db in
                            try LiveWorkout.start(db, routineID: id, now: now)
                        }
                        await send(.delegate(.navigate(.session)))
                    }
                }
            case .task:
                return .run { [listing = state.$listing] _ in
                    await withErrorReporting {
                        try await listing.load(RoutineListing.Request()).task
                    }
                }
            case .templatesButtonTapped:
                state.templates = Templates.State()
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$templates, action: \.templates) {
            Templates()
        }
    }
}

extension RoutineCard {
    /// The name, or "New routine" while it has none.
    public var title: String {
        name.isEmpty ? L10n.newRoutineName : name
    }
}

extension AlertState where Action == Routines.Action.Alert {
    public static func deleteRoutine(id: Routine.ID, title: String) -> Self {
        AlertState {
            TextState(L10n.deleteRoutine)
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeleteButtonTapped(id: id)) {
                TextState(L10n.delete)
            }
            ButtonState(role: .cancel) {
                TextState(L10n.cancel)
            }
        } message: {
            TextState(title)
        }
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

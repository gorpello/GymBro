import ComposableArchitecture
import Database
import Foundation
import Routing
import SQLiteData

/// "Start workout" sheet from the tab bar accessory: today's routine, your routines, or pick / focus.
/// Switches to "Log a workout" for sessions done without the timer.
@Reducer
public struct StartWorkout: Sendable {
    @ObservableState
    public struct State: Equatable {
        @ObservationStateIgnored
        @Fetch public var options = StartOptions()
        public var isLogging = false
        /// Start of the day the sheet was opened; `nil` until it appears.
        public var today: Date?

        public init() {}
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case chooseFocusButtonTapped
        case delegate(Delegate)
        case pickExercisesButtonTapped
        case resumeButtonTapped
        case routineTapped(id: Routine.ID)
        case task

        @CasePathable
        public enum Delegate {
            case navigate(Route)
        }
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.defaultDatabase) var database
    @Dependency(\.date.now) var now

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .delegate:
                return .none
            case .chooseFocusButtonTapped, .pickExercisesButtonTapped:
                return .send(.delegate(.navigate(.train)))
            case .resumeButtonTapped:
                return .send(.delegate(.navigate(.session)))
            case let .routineTapped(id):
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
                let today = calendar.startOfDay(for: now)
                state.today = today
                return .run { [options = state.$options, calendar] _ in
                    await withErrorReporting {
                        try await options.load(StartOptions.Request(today: today, calendar: calendar)).task
                    }
                }
            }
        }
    }
}

/// What the Start sheet offers: the workout in progress, today's routine and the rest.
public struct StartOptions: Equatable, Sendable {
    public var hasWorkoutInProgress = false
    /// The routine planned for today; a second workout today moves on to the next one planned.
    public var today: StartRoutineRow?
    /// Every other routine, in list order.
    public var routines: [StartRoutineRow] = []

    public init() {}

    public struct Request: FetchKeyRequest {
        public var today: Date
        public var calendar: Calendar

        public init(today: Date, calendar: Calendar) {
            self.today = today
            self.calendar = calendar
        }

        public func fetch(_ db: Database) throws -> StartOptions {
            var options = StartOptions()
            options.hasWorkoutInProgress = try LiveWorkout.fetch(db) != nil

            let routines =
                try Routine
                .order(by: \.position)
                .leftJoin(RoutineExercise.all) { $0.id.eq($1.routineID) }
                .group { routines, _ in routines.id }
                .select { routines, routineExercises in
                    StartRoutineRow.Columns(
                        id: routines.id,
                        exerciseCount: routineExercises.id.count(distinct: true),
                        hue: routines.colorIndex ?? routines.position,
                        name: routines.name
                    )
                }
                .fetchAll(db)

            let start = calendar.startOfDay(for: today)
            let end = calendar.day(byAdding: 1, to: start)
            let plannedToday =
                try RoutineSchedule
                .where { $0.weekday.eq(calendar.mondayIndex(of: start) + 1) }
                .select(\.routineID)
                .fetchAll(db)
            let workoutsToday =
                try Workout
                .where { $0.finishedAt.isNot(nil) && $0.startedAt.gte(start) && $0.startedAt.lt(end) }
                .fetchCount(db)

            let todayRows = routines.filter { plannedToday.contains($0.id) }
            options.today = todayRows.isEmpty ? nil : todayRows[min(workoutsToday, todayRows.count - 1)]
            options.routines = routines.filter { $0.id != options.today?.id }
            return options
        }
    }
}

@Selection
public struct StartRoutineRow: Equatable, Identifiable, Sendable {
    public var id: Routine.ID
    public var exerciseCount: Int
    /// Index into the folder hues.
    public var hue: Int
    public var name: String
}

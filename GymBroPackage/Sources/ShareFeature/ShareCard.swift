import ComposableArchitecture
import Database
import Foundation
import SQLiteData

/// Pick a card to share: streak and consistency, muscles worked, or before and after.
@Reducer
public struct ShareCard: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var kind: Kind = .streak
        @ObservationStateIgnored
        @Fetch public var summary = ShareSummary()

        public init() {}
    }

    public enum Kind: Hashable, Sendable {
        case streak, body, compare
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case shareButtonTapped
        case task
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .shareButtonTapped:
                return .none
            case .task:
                return .run { [summary = state.$summary, now, calendar] _ in
                    await withErrorReporting {
                        try await summary.load(ShareSummary.Request(today: now, calendar: calendar)).task
                    }
                }
            }
        }
    }
}

/// What the share cards show, read from the training history.
public struct ShareSummary: Equatable, Sendable {
    /// Twelve weeks of heat, oldest first, Monday first.
    public var activity: [[Int]] = Array(repeating: Array(repeating: 0, count: 7), count: ActivityGrid.weeks)
    /// Heat 1…4 per body-map muscle id over the last seven days.
    public var muscleLevels: [String: Int] = [:]
    public var streak = 0

    public init() {}

    public struct Request: FetchKeyRequest {
        public var today: Date
        public var calendar: Calendar

        public init(today: Date, calendar: Calendar) {
            self.today = today
            self.calendar = calendar
        }

        public func fetch(_ db: Database) throws -> ShareSummary {
            let today = calendar.startOfDay(for: today)
            var summary = ShareSummary()
            summary.activity = try ActivityGrid.fetch(db, today: today, calendar: calendar)
            summary.streak = try Streak.fetch(db, today: today, calendar: calendar)
            let sets = try MuscleLoad.fetchSets(db, since: calendar.day(byAdding: -6, to: today))
            summary.muscleLevels = Dictionary(
                uniqueKeysWithValues: MuscleLoad.heatLevels(sets, days: 7).map { ($0.key.rawValue, $0.value) }
            )
            return summary
        }
    }
}

/// Export one workout as a `.fit` file for Strava.
@Reducer
public struct StravaExport: Sendable {
    @ObservableState
    public struct State: Equatable {
        @ObservationStateIgnored
        @Fetch public var workouts: [StravaWorkout] = []

        public init() {}
    }

    public enum Action {
        case task
        case workoutTapped(id: Workout.ID)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [workouts = state.$workouts] _ in
                    await withErrorReporting {
                        try await workouts.load(StravaWorkout.Request()).task
                    }
                }
            case .workoutTapped:
                return .none
            }
        }
    }
}

/// A finished workout that can be sent to Strava.
@Selection
public struct StravaWorkout: Equatable, Identifiable, Sendable {
    public var id: Workout.ID
    public var startedAt: Date
    /// The routine it was started from, if any.
    public var routineName: String?
    public var durationSeconds: Int
    /// Completed working sets.
    public var setCount: Int
}

extension StravaWorkout {
    /// Finished workouts with at least one completed working set, newest first.
    public struct Request: FetchKeyRequest {
        public init() {}

        public func fetch(_ db: Database) throws -> [StravaWorkout] {
            try Workout
                .where { $0.finishedAt.isNot(nil) }
                .group(by: \.id)
                .order { $0.startedAt.desc() }
                .leftJoin(Routine.all) { $0.routineID.eq($1.id) }
                .join(WorkoutExercise.all) { $0.id.eq($2.workoutID) }
                .join(WorkoutSet.all) { $2.id.eq($3.workoutExerciseID) }
                .where { _, _, _, workoutSets in workoutSets.isCompleted && workoutSets.kind.neq(SetKind.warmup) }
                .select { workouts, routines, _, workoutSets in
                    StravaWorkout.Columns(
                        id: workouts.id,
                        startedAt: workouts.startedAt,
                        routineName: routines.name,
                        durationSeconds: workouts.durationSeconds,
                        setCount: workoutSets.id.count()
                    )
                }
                .fetchAll(db)
        }
    }
}

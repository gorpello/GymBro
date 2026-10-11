import ComposableArchitecture
import Database
import Foundation
import Routing
import SQLiteData

/// The live workout: one exercise at a time with its demo, rest timer and set table,
/// a lock screen, an overview of all exercises and the finish summary.
///
/// The workout lives in the database (see `LiveWorkout`): every tap is written straight away and
/// the screen re-reads it, so leaving and coming back picks up exactly where it was.
@Reducer
public struct Session: Sendable {
    @ObservableState
    public struct State: Equatable {
        @ObservationStateIgnored
        @Fetch public var session = LiveSession()
        /// Set once the workout is filed; shows the summary.
        public var finished: FinishedWorkout?
        public var isLocked = false
        public var showsOverview = false
        /// The clock the timers are drawn from, ticked every second while the screen is up.
        public var now: Date?
        /// Length of the rest that's running, so its progress can be drawn.
        public var restTotalSeconds: Int?

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
        case repsChanged(setID: WorkoutSet.ID, delta: Int)
        case restAdjustButtonTapped(seconds: Int)
        case saveAsRoutineButtonTapped
        case setDoneButtonTapped(setID: WorkoutSet.ID)
        case shareButtonTapped
        case skipRestButtonTapped
        case stickerButtonTapped
        case task
        case timerTicked
        case unlockCompleted
        /// `delta` is in the user's unit, e.g. +5 lb.
        case weightChanged(setID: WorkoutSet.ID, delta: Double)
        case workoutFinished(FinishedWorkout?)

        @CasePathable
        public enum Delegate {
            case navigate(Route)
        }
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.continuousClock) var clock
    @Dependency(\.defaultDatabase) var database
    @Dependency(\.date.now) var now
    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .addExerciseButtonTapped, .binding, .delegate, .saveAsRoutineButtonTapped:
                return .none

            case .addSetButtonTapped:
                guard let entry = state.current else { return .none }
                return write { db in try LiveWorkout.addSet(db, to: entry.id) }

            case .addWarmupButtonTapped:
                guard let entry = state.current else { return .none }
                return write { db in try LiveWorkout.addWarmup(db, to: entry.id) }

            case .doneButtonTapped:
                return .run { _ in await dismiss() }

            case let .exerciseSelected(index):
                state.showsOverview = false
                return move(state, to: index)

            case .finishButtonTapped:
                guard let workoutID = state.session.workout?.id else { return .none }
                return .run { [now, calendar] send in
                    await withErrorReporting {
                        let finished = try await database.write { db in
                            try LiveWorkout.finish(db, workoutID: workoutID, now: now, calendar: calendar)
                        }
                        await send(.workoutFinished(finished))
                    }
                }

            case .lockButtonTapped:
                state.isLocked = true
                return .none

            case .nextExerciseButtonTapped:
                return move(state, to: state.currentIndex + 1)

            case .overviewButtonTapped:
                state.showsOverview = true
                return .none

            case .pauseButtonTapped:
                guard let workout = state.session.workout else { return .none }
                state.now = now
                return write { [now] db in
                    if workout.isPaused {
                        try LiveWorkout.resume(db, workoutID: workout.id, now: now)
                    } else {
                        try LiveWorkout.pause(db, workoutID: workout.id, now: now)
                    }
                }

            case let .repsChanged(setID, delta):
                return write { db in try LiveWorkout.adjustSet(db, id: setID, reps: delta) }

            case let .restAdjustButtonTapped(seconds):
                guard let workout = state.session.workout, let remaining = workout.restRemainingSeconds(at: now)
                else { return .none }
                let adjusted = min(max(remaining + seconds, 5), 600)
                state.restTotalSeconds = max(adjusted, (state.restTotalSeconds ?? remaining) + adjusted - remaining)
                return write { [now] db in
                    try LiveWorkout.adjustRest(db, workoutID: workout.id, by: seconds, now: now)
                }

            case let .setDoneButtonTapped(setID):
                guard
                    let workout = state.session.workout,
                    let entry = state.session.exercises.first(where: { $0.sets.contains { $0.id == setID } }),
                    let set = entry.sets.first(where: { $0.id == setID })
                else { return .none }
                // Ticking a set starts the rest; unticking leaves the clock alone.
                let startsRest = !set.isCompleted && !workout.isPaused && entry.restSeconds > 0
                if startsRest {
                    state.now = now
                    state.restTotalSeconds = entry.restSeconds
                }
                return write { [now] db in
                    try LiveWorkout.toggleSet(db, id: setID)
                    if startsRest {
                        try LiveWorkout.startRest(db, workoutID: workout.id, seconds: entry.restSeconds, now: now)
                    }
                }

            case .shareButtonTapped:
                return .send(.delegate(.navigate(.share)))

            case .skipRestButtonTapped:
                guard let workout = state.session.workout else { return .none }
                state.restTotalSeconds = nil
                return write { db in try LiveWorkout.skipRest(db, workoutID: workout.id) }

            case .stickerButtonTapped:
                return .send(.delegate(.navigate(.sticker)))

            case .task:
                state.now = now
                return .merge(
                    .run { [session = state.$session] _ in
                        await withErrorReporting {
                            try await session.load(LiveSession.Request()).task
                        }
                    },
                    .run { send in
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.timerTicked)
                        }
                    }
                )

            case .timerTicked:
                state.now = now
                if state.restRemainingSeconds == nil {
                    state.restTotalSeconds = nil
                }
                return .none

            case .unlockCompleted:
                state.isLocked = false
                return .none

            case let .weightChanged(setID, delta):
                let units = state.session.units
                return write { db in try LiveWorkout.adjustSet(db, id: setID, weightKg: delta * units.kilograms) }

            case let .workoutFinished(finished):
                guard let finished else {
                    // Nothing was ticked, so nothing was logged.
                    return .run { _ in await dismiss() }
                }
                state.finished = finished
                state.isLocked = false
                state.restTotalSeconds = nil
                return .none
            }
        }
    }

    private func move(_ state: State, to index: Int) -> Effect<Action> {
        guard let workout = state.session.workout, state.session.exercises.indices.contains(index) else {
            return .none
        }
        return write { db in try LiveWorkout.move(db, workoutID: workout.id, toPosition: index) }
    }

    private func write(_ change: @escaping @Sendable (Database) throws -> Void) -> Effect<Action> {
        .run { _ in
            await withErrorReporting {
                try await database.write(change)
            }
        }
    }
}

extension Session.State {
    public var isFinished: Bool { finished != nil }
    public var isPaused: Bool { session.workout?.isPaused ?? false }

    /// The exercise on screen.
    public var currentIndex: Int {
        let position = session.workout?.currentPosition ?? 0
        return min(max(position, 0), max(session.exercises.count - 1, 0))
    }

    public var current: LiveSession.Entry? {
        session.exercises.indices.contains(currentIndex) ? session.exercises[currentIndex] : nil
    }

    public var elapsedSeconds: Int {
        guard let workout = session.workout, let now else { return 0 }
        return workout.elapsedSeconds(at: now)
    }

    /// `nil` when not resting.
    public var restRemainingSeconds: Int? {
        guard let workout = session.workout, let now else { return nil }
        return workout.restRemainingSeconds(at: now)
    }

    /// From 1 (rest just started) down to 0.
    public var restProgress: Double {
        guard let remaining = restRemainingSeconds, let total = restTotalSeconds, total > 0 else { return 0 }
        return min(Double(remaining) / Double(total), 1)
    }

    /// The weight stepper's step, in the user's unit.
    public var weightStep: Double { session.units == .kg ? 2.5 : 5 }
}

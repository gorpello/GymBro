import ComposableArchitecture
import CoreGraphics
import Database
import Foundation
import SQLiteData

/// Put a workout sticker on a photo: move, pinch and turn it, then save or share.
@Reducer
public struct Sticker: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var offset: CGSize = .zero
        public var rotation: Double = 0
        public var scale: Double = 1
        public var style: Style = .workout

        public var hasPhoto = false
        @ObservationStateIgnored
        @Fetch public var summary = StickerSummary()

        public init() {}
    }

    public enum Style: Hashable, Sendable {
        case workout, streak, date, week
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case cameraButtonTapped
        case galleryButtonTapped
        case saveButtonTapped
        case shareButtonTapped
        case stickerDragged(translation: CGSize)
        case stickerPinched(magnification: Double)
        case stickerRotated(degrees: Double)
        case task
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .cameraButtonTapped, .galleryButtonTapped, .saveButtonTapped, .shareButtonTapped:
                return .none
            case let .stickerDragged(translation):
                state.offset.width += translation.width
                state.offset.height += translation.height
                return .none
            case let .stickerPinched(magnification):
                state.scale = min(4, max(0.3, state.scale * magnification))
                return .none
            case let .stickerRotated(degrees):
                state.rotation += degrees
                return .none
            case .task:
                return .run { [summary = state.$summary, now, calendar] _ in
                    await withErrorReporting {
                        try await summary.load(StickerSummary.Request(today: now, calendar: calendar)).task
                    }
                }
            }
        }
    }
}

/// What the stickers show: the latest finished workout, the streak and this week.
public struct StickerSummary: Equatable, Sendable {
    /// The day the stickers show: the latest workout's, or today before the first one.
    public var date: Date?
    /// The latest finished workout; `nil` before the first one.
    public var workout: Workout?
    /// Its exercises, in order.
    public var exercises: [StickerExercise] = []
    /// Its completed working sets and their volume.
    public var setCount = 0
    public var volumeKg = 0.0
    public var units = AppSettings().units
    public var streak = 0
    /// Days of the current week with a finished workout, Monday first.
    public var weekDone = Array(repeating: false, count: 7)

    public init() {}

    public struct Request: FetchKeyRequest {
        public var today: Date
        public var calendar: Calendar

        public init(today: Date, calendar: Calendar) {
            self.today = today
            self.calendar = calendar
        }

        public func fetch(_ db: Database) throws -> StickerSummary {
            let today = calendar.startOfDay(for: today)
            let weekStart = calendar.day(byAdding: -calendar.mondayIndex(of: today), to: today)
            var summary = StickerSummary()
            summary.date = today
            if let units = try AppSettings.find(AppSettings.singletonID).select(\.units).fetchOne(db) {
                summary.units = units
            }
            summary.streak = try Streak.fetch(db, today: today, calendar: calendar)
            let weekEnd = calendar.day(byAdding: 7, to: weekStart)
            let thisWeek =
                try Workout
                .where { $0.finishedAt.isNot(nil) && $0.startedAt.gte(weekStart) && $0.startedAt.lt(weekEnd) }
                .select(\.startedAt)
                .fetchAll(db)
            for startedAt in thisWeek {
                summary.weekDone[calendar.mondayIndex(of: startedAt)] = true
            }

            let latest = try Workout.where { $0.finishedAt.isNot(nil) }.order { $0.startedAt.desc() }.fetchOne(db)
            guard let workout = latest else { return summary }
            summary.workout = workout
            summary.date = workout.startedAt
            summary.exercises =
                try WorkoutExercise
                .where { $0.workoutID.eq(workout.id) }
                .order(by: \.position)
                .join(Exercise.all) { $0.exerciseID.eq($1.id) }
                .select { _, exercises in StickerExercise.Columns(id: exercises.id, name: exercises.name) }
                .fetchAll(db)
            if let total = try WorkoutTotal.fetch(db, from: workout.startedAt).first(where: { $0.id == workout.id }) {
                summary.setCount = total.setCount
                summary.volumeKg = total.volumeKg
            }
            return summary
        }
    }
}

@Selection
public struct StickerExercise: Equatable, Identifiable, Sendable {
    public var id: Exercise.ID
    public var name: String
}

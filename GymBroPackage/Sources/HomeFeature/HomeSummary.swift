import Database
import Foundation
import SQLiteData

/// Everything Home shows. Read in one transaction by `HomeSummary.Request` and re-read whenever a
/// workout, check-in, routine, note or the profile changes. Weeks start on Monday.
nonisolated public struct HomeSummary: Equatable, Sendable {

    public static let activityWeeks = ActivityGrid.weeks

    /// Last twelve weeks, `activity[week][weekday]`, oldest week first, levels 0…4.
    public var activity = Array(repeating: Array(repeating: 0, count: 7), count: activityWeeks)
    /// Days this week with a workout or a check-in.
    public var daysDoneThisWeek = 0
    public var noteCount = 0
    /// Exercises whose all-time best was set this week.
    public var prCount = 0
    public var routineCount = 0
    /// Working sets logged today.
    public var setsToday = 0
    /// Consecutive training days up to today; unscheduled days don't break it.
    public var streak = 0
    public var todayExerciseCount = 0
    /// Routine planned for today; `nil` when nothing is scheduled.
    public var todayRoutineName: String?
    /// 0 = Monday … 6 = Sunday.
    public var todayWeekdayIndex = 0
    public var volumeThisWeekKg = 0.0
    public var weekDone = Array(repeating: false, count: 7)
    public var weeklyGoal = 4

    public init() {}
}

extension HomeSummary {

    nonisolated public struct Request: FetchKeyRequest {
        public var today: Date
        public var calendar: Calendar

        public init(today: Date, calendar: Calendar) {
            self.today = today
            self.calendar = calendar
        }

        public func fetch(_ db: Database) throws -> HomeSummary {

            let today = calendar.startOfDay(for: today)
            let todayIndex = calendar.mondayIndex(of: today)
            let weekStart = calendar.day(byAdding: -todayIndex, to: today)
            let weekEnd = calendar.day(byAdding: 7, to: weekStart)
            let activityStart = calendar.day(byAdding: -7 * (HomeSummary.activityWeeks - 1), to: weekStart)

            let sessions =
                try Workout
                .where { $0.finishedAt.isNot(nil) }
                .select { Session.Columns(id: $0.id, startedAt: $0.startedAt) }
                .fetchAll(db)
            let checkIns = try CheckIn.select(\.day).fetchAll(db)
            let scheduledWeekdays = try Set(RoutineSchedule.select(\.weekday).fetchAll(db))
            let totals = try fetchWorkoutTotals(db, since: activityStart)
            let todayRoutines = try fetchRoutines(db, onWeekday: todayIndex + 1)
            let recordSets = try PersonalRecord.fetchSets(
                db,
                exerciseIDs: fetchExerciseIDs(db, trainedFrom: weekStart, to: weekEnd)
            )

            var summary = HomeSummary()
            summary.todayWeekdayIndex = todayIndex
            summary.routineCount = try Routine.all.fetchCount(db)
            summary.noteCount = try Note.all.fetchCount(db)
            if let weeklyGoal = try UserProfile.find(UserProfile.singletonID).select(\.weeklyGoal).fetchOne(db),
                weeklyGoal > 0
            {
                summary.weeklyGoal = weeklyGoal
            }

            let sessionDays = Dictionary(
                uniqueKeysWithValues: sessions.map { ($0.id, calendar.startOfDay(for: $0.startedAt)) }
            )
            let checkInDays = Set(checkIns.map { calendar.startOfDay(for: $0) })
            let trainedDays = Set(sessionDays.values).union(checkInDays)

            if !todayRoutines.isEmpty {
                // A second session on the same day moves on to the next routine planned for it.
                let sessionsToday = sessionDays.values.count { $0 == today }
                let routine = todayRoutines[min(sessionsToday, todayRoutines.count - 1)]
                summary.todayRoutineName = routine.name
                summary.todayExerciseCount = routine.exerciseCount
            }

            summary.weekDone = (0..<7).map { trainedDays.contains(calendar.day(byAdding: $0, to: weekStart)) }
            summary.daysDoneThisWeek = summary.weekDone.count { $0 }

            for workout in totals {
                guard let day = sessionDays[workout.id] else { continue }
                if day == today { summary.setsToday += workout.setCount }
                if day >= weekStart, day < weekEnd { summary.volumeThisWeekKg += workout.volumeKg }
            }

            summary.activity = ActivityGrid.levels(
                from: activityStart,
                through: today,
                sessionDays: sessionDays,
                checkInDays: checkInDays,
                setCounts: Dictionary(uniqueKeysWithValues: totals.map { ($0.id, $0.setCount) }),
                calendar: calendar
            )
            summary.streak = Streak.count(
                endingOn: today,
                trainedDays: trainedDays,
                scheduledWeekdays: scheduledWeekdays,
                calendar: calendar
            )
            summary.prCount = PersonalRecord.records(from: recordSets).count { record in
                record.date >= weekStart && record.date < weekEnd
            }
            return summary
        }

        /// Working sets and volume of each finished workout since `start`. Workouts without a
        /// working set are left out.
        private func fetchWorkoutTotals(_ db: Database, since start: Date) throws -> [WorkoutTotals] {
            try Workout
                .where { $0.finishedAt.isNot(nil) && $0.startedAt.gte(start) }
                .group(by: \.id)
                .join(WorkoutExercise.all) { $0.id.eq($1.workoutID) }
                .join(WorkoutSet.all) { $1.id.eq($2.workoutExerciseID) }
                .where { _, _, workoutSets in
                    workoutSets.isCompleted && workoutSets.kind.neq(SetKind.warmup)
                }
                .select { workouts, _, workoutSets in
                    WorkoutTotals.Columns(
                        id: workouts.id,
                        setCount: workoutSets.id.count(),
                        volumeKg: (workoutSets.reps.cast(as: Double.self) * workoutSets.weightKg).total()
                    )
                }
                .fetchAll(db)
        }

        /// Routines scheduled on `weekday` (1 = Monday), in list order, with their exercise counts.
        private func fetchRoutines(_ db: Database, onWeekday weekday: Int) throws -> [TodayRoutine] {
            try RoutineSchedule
                .where { $0.weekday.eq(weekday) }
                .join(Routine.all) { $0.routineID.eq($1.id) }
                .leftJoin(RoutineExercise.all) { $1.id.eq($2.routineID) }
                .group { _, routines, _ in routines.id }
                .order { _, routines, _ in routines.position }
                .select { _, routines, routineExercises in
                    TodayRoutine.Columns(
                        name: routines.name,
                        exerciseCount: routineExercises.id.count(distinct: true)
                    )
                }
                .fetchAll(db)
        }

        /// Exercises in finished workouts started in `start..<end`.
        private func fetchExerciseIDs(_ db: Database, trainedFrom start: Date, to end: Date) throws -> [Exercise.ID] {
            try WorkoutExercise
                .join(Workout.all) { $0.workoutID.eq($1.id) }
                .where { _, workouts in
                    workouts.finishedAt.isNot(nil) && workouts.startedAt.gte(start) && workouts.startedAt.lt(end)
                }
                .select { workoutExercises, _ in workoutExercises.exerciseID }
                .distinct()
                .fetchAll(db)
        }
    }
}

@Selection
nonisolated private struct Session {
    let id: Workout.ID
    let startedAt: Date
}

@Selection
nonisolated private struct WorkoutTotals {
    let id: Workout.ID
    let setCount: Int
    let volumeKg: Double
}

@Selection
nonisolated private struct TodayRoutine {
    let name: String
    let exerciseCount: Int
}

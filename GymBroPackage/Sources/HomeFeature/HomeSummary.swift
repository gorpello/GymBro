import Database
import Foundation
import SQLiteData

/// Everything Home shows. Read in one transaction by `HomeSummary.Request` and re-read whenever a
/// workout, check-in, routine, note or the profile changes. Weeks start on Monday.
nonisolated public struct HomeSummary: Equatable, Sendable {
    
    public static let activityWeeks = 12

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

            let sessions = try Workout
                .where { $0.finishedAt.isNot(nil) }
                .select { Session.Columns(id: $0.id, startedAt: $0.startedAt) }
                .fetchAll(db)
            let checkIns = try CheckIn.select(\.day).fetchAll(db)
            let scheduledWeekdays = try Set(RoutineSchedule.select(\.weekday).fetchAll(db))
            let totals = try fetchWorkoutTotals(db, since: activityStart)
            let todayRoutines = try fetchRoutines(db, onWeekday: todayIndex + 1)
            let recordSets = try fetchRecordSets(db, forExercisesTrainedFrom: weekStart, to: weekEnd)

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

            summary.activity = activityLevels(
                from: activityStart,
                through: today,
                sessionDays: sessionDays,
                checkInDays: checkInDays,
                setCounts: Dictionary(uniqueKeysWithValues: totals.map { ($0.id, $0.setCount) })
            )
            summary.streak = streak(endingOn: today, trainedDays: trainedDays, scheduledWeekdays: scheduledWeekdays)
            summary.prCount = Dictionary(grouping: recordSets, by: \.exerciseID).values.count { sets in
                guard let date = RecordKind.bestDate(of: sets) else { return false }
                return date >= weekStart && date < weekEnd
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

        /// Every working set, oldest first, of the exercises trained in `start..<end`.
        private func fetchRecordSets(
            _ db: Database,
            forExercisesTrainedFrom start: Date,
            to end: Date
        ) throws -> [RecordSet] {
            try WorkoutSet
                .where { $0.isCompleted && $0.kind.neq(SetKind.warmup) }
                .join(WorkoutExercise.all) { $0.workoutExerciseID.eq($1.id) }
                .join(Workout.all) { $1.workoutID.eq($2.id) }
                .where { _, workoutExercises, workouts in
                    workouts.finishedAt.isNot(nil)
                        && workoutExercises.exerciseID.in(
                            WorkoutExercise
                                .join(Workout.all) { $0.workoutID.eq($1.id) }
                                .where { _, workouts in
                                    workouts.finishedAt.isNot(nil)
                                        && workouts.startedAt.gte(start)
                                        && workouts.startedAt.lt(end)
                                }
                                .select { workoutExercises, _ in workoutExercises.exerciseID }
                        )
                }
                .order { workoutSets, workoutExercises, workouts in
                    (workouts.startedAt, workoutExercises.position, workoutSets.position)
                }
                .select { workoutSets, workoutExercises, workouts in
                    RecordSet.Columns(
                        exerciseID: workoutExercises.exerciseID,
                        startedAt: workouts.startedAt,
                        reps: workoutSets.reps,
                        weightKg: workoutSets.weightKg,
                        rpe: workoutSets.rpe,
                        durationSeconds: workoutSets.durationSeconds,
                        distanceKm: workoutSets.distanceKm
                    )
                }
                .fetchAll(db)
        }

        /// Each day's load is its working sets (at least 1 per workout) plus 1 for a check-in, scaled
        /// against the busiest day in the window.
        private func activityLevels(
            from start: Date,
            through today: Date,
            sessionDays: [Workout.ID: Date],
            checkInDays: Set<Date>,
            setCounts: [Workout.ID: Int]
        ) -> [[Int]] {
            var load: [Date: Double] = [:]
            for day in checkInDays where day >= start && day <= today {
                load[day] = 1
            }
            for (id, day) in sessionDays where day >= start && day <= today {
                load[day, default: 0] += Double(max(1, setCounts[id] ?? 0))
            }
            let busiest = load.values.max() ?? 0
            return (0..<HomeSummary.activityWeeks).map { week in
                (0..<7).map { weekday in
                    let day = calendar.day(byAdding: week * 7 + weekday, to: start)
                    guard busiest > 0, let value = load[day] else { return 0 }
                    return heatLevel(value / busiest)
                }
            }
        }

        /// Counts back from today (or yesterday, if today isn't trained yet). Once any routine is
        /// scheduled, days with nothing scheduled are rest days and are skipped instead of ending it.
        private func streak(endingOn today: Date, trainedDays: Set<Date>, scheduledWeekdays: Set<Int>) -> Int {
            guard let first = trainedDays.min() else { return 0 }
            var day = trainedDays.contains(today) ? today : calendar.day(byAdding: -1, to: today)
            var streak = 0
            while day >= first {
                if trainedDays.contains(day) {
                    streak += 1
                } else if scheduledWeekdays.isEmpty || scheduledWeekdays.contains(calendar.mondayIndex(of: day) + 1) {
                    break
                }
                day = calendar.day(byAdding: -1, to: day)
            }
            return streak
        }

        private func heatLevel(_ fraction: Double) -> Int {
            switch fraction {
            case ...0: 0
            case ..<0.25: 1
            case ..<0.5: 2
            case ..<0.75: 3
            default: 4
            }
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

@Selection
nonisolated private struct RecordSet {
    let exerciseID: Exercise.ID
    let startedAt: Date
    let reps: Int
    let weightKg: Double
    let rpe: Double?
    let durationSeconds: Int?
    let distanceKm: Double?
}

/// What an exercise's record is measured in: the first kind any of its sets has a value for.
nonisolated private enum RecordKind: CaseIterable {
    case weight, distance, time, reps

    func score(_ set: RecordSet) -> Double {
        switch self {
        case .weight: set.weightKg
        case .distance: set.distanceKm ?? 0
        case .time: Double(set.durationSeconds ?? 0)
        case .reps: Double(set.reps)
        }
    }

    /// When the exercise's best set was first lifted. Weight records compare estimated one-rep
    /// maxes; matching an earlier best doesn't count. `sets` must be oldest first.
    static func bestDate(of sets: [RecordSet]) -> Date? {
        let kind = allCases.first { kind in sets.contains { kind.score($0) > 0 } } ?? .reps
        var best = 0.0
        var date: Date?
        for set in sets {
            let score = kind == .weight
                ? WorkoutSet.estimatedOneRepMaxKg(weightKg: set.weightKg, reps: set.reps, rpe: set.rpe)
                : kind.score(set)
            if score > best {
                best = score
                date = set.startedAt
            }
        }
        return date
    }
}

extension Calendar {
    /// 0 = Monday … 6 = Sunday, whatever the calendar's first weekday.
    fileprivate func mondayIndex(of date: Date) -> Int {
        (component(.weekday, from: date) + 5) % 7
    }

    fileprivate func day(byAdding days: Int, to date: Date) -> Date {
        self.date(byAdding: .day, value: days, to: date) ?? date
    }
}

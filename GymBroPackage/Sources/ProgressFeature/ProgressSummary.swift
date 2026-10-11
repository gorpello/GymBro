import Database
import Foundation
import SQLiteData

/// Everything the Progress tab shows. Read in one transaction by `ProgressSummary.Request` and
/// re-read whenever workouts, body measurements, progress photos, settings or the profile change.
/// Only completed working sets of finished workouts count; weeks start on Monday.
public struct ProgressSummary: Equatable, Sendable {
    public static let measureChips = 6
    public static let strengthPoints = 24
    public static let strengthRows = 3
    public static let trendPoints = 12

    public var units = AppSettings().units

    /// Volume lifted in the last 30 days.
    public var volume30Kg = 0.0
    /// Against the 30 days before; `nil` when nothing was lifted then.
    public var volumeChangePercent: Int?
    /// Running total over the last 30 days, sampled at `trendPoints` points.
    public var volumeTrendKg: [Double] = []

    /// Latest bodyweight entry.
    public var weight: BodyMeasurement?
    /// Every bodyweight entry, oldest first.
    public var weightTrendKg: [Double] = []

    /// Last twelve weeks, `activity[week][weekday]`, oldest week first, levels 0…4.
    public var activity = Array(repeating: Array(repeating: 0, count: 7), count: ActivityGrid.weeks)
    public var streak = 0
    /// Days this week with a workout or a check-in.
    public var daysDoneThisWeek = 0
    public var weeklyGoal = 4
    public var totals = TrainingTotals()
    /// Working sets per day this week, Monday first.
    public var setsThisWeek = Array(repeating: 0, count: 7)

    /// Heat 1…4 per muscle over the last 7 and 30 days.
    public var muscleHeat7: [Muscle: Int] = [:]
    public var muscleHeat30: [Muscle: Int] = [:]
    /// Fatigue 0 (fresh) … 4 (tired) per muscle right now.
    public var fatigueLevels: [Muscle: Int] = [:]
    public var recoveryPercent = 100

    /// Estimated one-rep max over time of the weighted exercises trained most often.
    public var strength: [StrengthRow] = []
    public var records: [RecordRow] = []
    public var photoCount = 0
    /// Latest value of each circumference and body fat, in display order.
    public var measures: [BodyMeasurement] = []

    public init() {}

    /// Circumferences top to bottom, then body fat.
    public static let measureOrder: [MeasurementKind] = [
        .neck, .shoulders, .chest, .arm, .forearm, .waist, .hips, .thigh, .calf, .bodyFat,
    ]
}

public struct StrengthRow: Equatable, Identifiable, Sendable {
    public var id: Exercise.ID
    public var name: String
    public var bestOneRepMaxKg: Double
    /// Best estimated one-rep max of each of the latest workouts, oldest first.
    public var curveKg: [Double]

    public init(id: Exercise.ID, name: String, bestOneRepMaxKg: Double, curveKg: [Double]) {
        self.id = id
        self.name = name
        self.bestOneRepMaxKg = bestOneRepMaxKg
        self.curveKg = curveKg
    }
}

public struct RecordRow: Equatable, Identifiable, Sendable {
    public var name: String
    public var record: PersonalRecord

    public var id: Exercise.ID { record.exerciseID }

    public init(name: String, record: PersonalRecord) {
        self.name = name
        self.record = record
    }
}

extension ProgressSummary {
    public struct Request: FetchKeyRequest {
        public var now: Date
        public var calendar: Calendar

        public init(now: Date, calendar: Calendar) {
            self.now = now
            self.calendar = calendar
        }

        public func fetch(_ db: Database) throws -> ProgressSummary {
            let today = calendar.startOfDay(for: now)
            let todayIndex = calendar.mondayIndex(of: today)
            let weekStart = calendar.day(byAdding: -todayIndex, to: today)
            let activityStart = calendar.day(byAdding: -7 * (ActivityGrid.weeks - 1), to: weekStart)

            var summary = ProgressSummary()
            if let units = try AppSettings.find(AppSettings.singletonID).select(\.units).fetchOne(db) {
                summary.units = units
            }
            if let weeklyGoal = try UserProfile.find(UserProfile.singletonID).select(\.weeklyGoal).fetchOne(db),
                weeklyGoal > 0
            {
                summary.weeklyGoal = weeklyGoal
            }
            summary.totals = try TrainingTotals.fetch(db, today: now, calendar: calendar)

            let sessions =
                try Workout
                .where { $0.finishedAt.isNot(nil) }
                .select { Session.Columns(id: $0.id, startedAt: $0.startedAt) }
                .fetchAll(db)
            let sessionDays = Dictionary(
                uniqueKeysWithValues: sessions.map { ($0.id, calendar.startOfDay(for: $0.startedAt)) }
            )
            let checkInDays = try Set(CheckIn.select(\.day).fetchAll(db).map { calendar.startOfDay(for: $0) })
            let trainedDays = Set(sessionDays.values).union(checkInDays)
            let sets = try PersonalRecord.fetchSets(db)
            let setCounts = Dictionary(grouping: sets, by: \.workoutID).mapValues(\.count)

            summary.activity = ActivityGrid.levels(
                from: activityStart,
                through: today,
                sessionDays: sessionDays,
                checkInDays: checkInDays,
                setCounts: setCounts,
                calendar: calendar
            )
            summary.streak = Streak.count(
                endingOn: today,
                trainedDays: trainedDays,
                scheduledWeekdays: try Set(RoutineSchedule.select(\.weekday).fetchAll(db)),
                calendar: calendar
            )
            summary.daysDoneThisWeek = (0..<7).count { offset in
                trainedDays.contains(calendar.day(byAdding: offset, to: weekStart))
            }
            for (id, day) in sessionDays {
                let index = days(from: weekStart, to: day)
                if summary.setsThisWeek.indices.contains(index) {
                    summary.setsThisWeek[index] += setCounts[id] ?? 0
                }
            }

            readVolume(of: sets, today: today, into: &summary)
            try readBody(db, into: &summary)
            try readMuscles(db, today: today, into: &summary)

            let names = try Dictionary(
                uniqueKeysWithValues:
                    Exercise
                    .where { $0.id.in(Array(Set(sets.map(\.exerciseID)))) }
                    .select { ($0.id, $0.name) }
                    .fetchAll(db)
            )
            summary.records = PersonalRecord.records(from: sets).map { record in
                RecordRow(name: names[record.exerciseID] ?? "", record: record)
            }
            summary.strength = Self.strength(of: sets, names: names)
            return summary
        }

        /// Last 30 days against the 30 before, by workout start.
        private func readVolume(of sets: [PersonalRecord.LoggedSet], today: Date, into summary: inout ProgressSummary) {
            let monthAgo = calendar.day(byAdding: -30, to: now)
            let twoMonthsAgo = calendar.day(byAdding: -60, to: now)
            let firstDay = calendar.day(byAdding: -29, to: today)
            var previousKg = 0.0
            var dailyKg = Array(repeating: 0.0, count: 30)
            for set in sets where set.startedAt > twoMonthsAgo && set.startedAt <= now {
                let volumeKg = Double(set.reps) * set.weightKg
                guard set.startedAt > monthAgo else {
                    previousKg += volumeKg
                    continue
                }
                summary.volume30Kg += volumeKg
                let index = days(from: firstDay, to: set.startedAt)
                if dailyKg.indices.contains(index) {
                    dailyKg[index] += volumeKg
                }
            }
            if previousKg > 0 {
                summary.volumeChangePercent = Int(((summary.volume30Kg - previousKg) / previousKg * 100).rounded())
            }
            guard !sets.isEmpty else { return }
            var runningKg = dailyKg
            for index in runningKg.indices.dropFirst() {
                runningKg[index] += runningKg[index - 1]
            }
            summary.volumeTrendKg = (0..<ProgressSummary.trendPoints).map { point in
                let index = Double((runningKg.count - 1) * point) / Double(ProgressSummary.trendPoints - 1)
                return runningKg[Int(index.rounded())]
            }
        }

        private func readBody(_ db: Database, into summary: inout ProgressSummary) throws {
            let weights =
                try BodyMeasurement
                .where { $0.kind.eq(MeasurementKind.bodyweight) }
                .order(by: \.date)
                .fetchAll(db)
            summary.weight = weights.last
            summary.weightTrendKg = weights.map(\.value)

            let measures =
                try BodyMeasurement
                .where { $0.kind.neq(MeasurementKind.bodyweight) }
                .order(by: \.date)
                .fetchAll(db)
            let latest = Dictionary(measures.map { ($0.kind, $0) }, uniquingKeysWith: { _, newer in newer })
            summary.measures = Array(
                ProgressSummary.measureOrder.compactMap { latest[$0] }.prefix(ProgressSummary.measureChips)
            )

            summary.photoCount =
                try ProgressEntry.where { $0.frontPhoto.isNot(nil) }.fetchCount(db)
                + ProgressEntry.where { $0.sidePhoto.isNot(nil) }.fetchCount(db)
                + ProgressEntry.where { $0.backPhoto.isNot(nil) }.fetchCount(db)
        }

        private func readMuscles(_ db: Database, today: Date, into summary: inout ProgressSummary) throws {
            let weekStart = calendar.day(byAdding: -6, to: today)
            let monthStart = calendar.day(byAdding: -29, to: today)
            let sets = try MuscleLoad.fetchSets(db, since: monthStart)
            summary.muscleHeat7 = MuscleLoad.heatLevels(sets.filter { $0.startedAt >= weekStart }, days: 7)
            summary.muscleHeat30 = MuscleLoad.heatLevels(sets, days: 30)
            let recovery = MuscleLoad.recovery(sets, at: now)
            summary.fatigueLevels = recovery.mapValues { HeatLevel.of(1 - $0) }.filter { $0.value > 0 }
            summary.recoveryPercent = MuscleLoad.overallRecovery(recovery)
        }

        /// Whole days from the start of `start`'s day to `date`'s day.
        private func days(from start: Date, to date: Date) -> Int {
            calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: date))
                .day ?? 0
        }

        /// Weighted exercises trained in at least two workouts, most often trained first, each
        /// with its best estimated one-rep max per workout.
        ///
        /// - Parameter sets: Working sets, oldest first.
        static func strength(
            of sets: [PersonalRecord.LoggedSet],
            names: [Exercise.ID: String]
        ) -> [StrengthRow] {
            let curves = Dictionary(grouping: sets.filter { $0.weightKg > 0 }, by: \.exerciseID)
                .mapValues { sets in
                    var workoutIDs: [Workout.ID] = []
                    var bestKg: [Workout.ID: Double] = [:]
                    for set in sets {
                        if bestKg[set.workoutID] == nil { workoutIDs.append(set.workoutID) }
                        bestKg[set.workoutID] = max(bestKg[set.workoutID] ?? 0, set.estimatedOneRepMaxKg)
                    }
                    return workoutIDs.compactMap { bestKg[$0] }.map { ($0 * 10).rounded() / 10 }
                }
                .filter { $0.value.count >= 2 }
            let order = curves.keys.sorted { lhs, rhs in
                let (left, right) = (curves[lhs]?.count ?? 0, curves[rhs]?.count ?? 0)
                return left != right ? left > right : (names[lhs] ?? lhs) < (names[rhs] ?? rhs)
            }
            return order.prefix(ProgressSummary.strengthRows).map { exerciseID in
                let curveKg = curves[exerciseID] ?? []
                return StrengthRow(
                    id: exerciseID,
                    name: names[exerciseID] ?? "",
                    bestOneRepMaxKg: curveKg.max() ?? 0,
                    curveKg: Array(curveKg.suffix(ProgressSummary.strengthPoints))
                )
            }
        }
    }
}

@Selection
private struct Session {
    let id: Workout.ID
    let startedAt: Date
}

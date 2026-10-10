import Foundation
import OSLog
import SQLiteData

private let logger = Logger(subsystem: "com.unicorndonkeys.gymbro", category: "Database")

extension DependencyValues {
    
    /// Opens the app database, runs migrations and installs it as `defaultDatabase`.
    /// Call once, from `prepareDependencies` at launch and in previews that touch the database.
    public mutating func bootstrapDatabase() throws {
        let context = self.context
        var configuration = Configuration()
        configuration.foreignKeysEnabled = true
        configuration.prepareDatabase { db in
            db.add(function: $uuid)
            #if DEBUG
                db.trace(options: .profile) {
                    guard !$0.expandedDescription.hasPrefix("--") else { return }
                    switch context {
                    case .live:
                        logger.debug("\($0.expandedDescription)")
                    case .preview:
                        print($0.expandedDescription)
                    case .test:
                        break
                    }
                }
            #endif
        }
        let database = try SQLiteData.defaultDatabase(configuration: configuration)
        logger.debug("App database: open \"\(database.path)\"")

        // Shipped migrations must never be edited; add a new one instead.
        // Kept iCloud-ready: single-column primary keys, no unique indexes, no reserved CloudKit names.
        var migrator = DatabaseMigrator()
        #if DEBUG
            migrator.eraseDatabaseOnSchemaChange = true
        #endif
        migrator.registerMigration("Create initial tables") { db in
            try #sql(
                """
                CREATE TABLE "exercises" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "name" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "primaryMuscle" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'chest',
                  "secondaryMuscles" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '[]',
                  "equipment" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'Other',
                  "difficulty" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'Beginner',
                  "art" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "steps" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '[]',
                  "mode" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'weight',
                  "isCustom" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "isArchived" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "exercisePreferences" (
                  "exerciseID" TEXT PRIMARY KEY NOT NULL REFERENCES "exercises"("id") ON DELETE CASCADE,
                  "isFavorite" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "modeOverride" TEXT,
                  "restSeconds" INTEGER,
                  "progressStepKg" REAL,
                  "autoWarmup" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "repsOnly" INTEGER,
                  "suggestsNextStep" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 1,
                  "keepsLevel" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "nextStepSnoozedUntil" TEXT,
                  "barWeightKg" REAL,
                  "customMediaFile" TEXT,
                  "videoMarks" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '[]',
                  "goalTargetKg" REAL,
                  "goalDueDate" TEXT
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "routines" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "name" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "group" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "colorIndex" INTEGER,
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "routineExercises" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "routineID" TEXT NOT NULL REFERENCES "routines"("id") ON DELETE CASCADE,
                  "exerciseID" TEXT NOT NULL REFERENCES "exercises"("id") ON DELETE CASCADE,
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "setCount" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 3,
                  "isChainedToNext" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "plannedSets" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "routineExerciseID" TEXT NOT NULL REFERENCES "routineExercises"("id") ON DELETE CASCADE,
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "reps" INTEGER,
                  "weightKg" REAL,
                  "kind" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'normal',
                  "durationSeconds" INTEGER,
                  "distanceKm" REAL
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "routineSchedules" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "routineID" TEXT NOT NULL REFERENCES "routines"("id") ON DELETE CASCADE,
                  "weekday" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 1 CHECK ("weekday" BETWEEN 1 AND 7)
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "workouts" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "startedAt" TEXT NOT NULL,
                  "finishedAt" TEXT,
                  "durationSeconds" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "routineID" TEXT REFERENCES "routines"("id") ON DELETE SET NULL,
                  "isManual" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "currentPosition" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "elapsedBeforePauseSeconds" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "resumedAt" TEXT,
                  "restEndsAt" TEXT,
                  "restPausedRemaining" INTEGER
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "workoutExercises" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "workoutID" TEXT NOT NULL REFERENCES "workouts"("id") ON DELETE CASCADE,
                  "exerciseID" TEXT NOT NULL REFERENCES "exercises"("id") ON DELETE RESTRICT,
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "isChainedToNext" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "workoutSets" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "workoutExerciseID" TEXT NOT NULL REFERENCES "workoutExercises"("id") ON DELETE CASCADE,
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "reps" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "weightKg" REAL NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "kind" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'normal',
                  "rpe" REAL,
                  "durationSeconds" INTEGER,
                  "distanceKm" REAL,
                  "isCompleted" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "bodyMeasurements" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "date" TEXT NOT NULL,
                  "kind" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'bodyweight',
                  "value" REAL NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "progressEntries" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "date" TEXT NOT NULL,
                  "weightKg" REAL,
                  "note" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "frontPhoto" TEXT,
                  "sidePhoto" TEXT,
                  "backPhoto" TEXT
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "notes" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "exerciseID" TEXT REFERENCES "exercises"("id") ON DELETE SET NULL,
                  "date" TEXT NOT NULL,
                  "kind" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'note',
                  "text" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "createdAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "noteAttachments" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "noteID" TEXT NOT NULL REFERENCES "notes"("id") ON DELETE CASCADE,
                  "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "fileName" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT ''
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "moments" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "date" TEXT NOT NULL,
                  "fileName" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "note" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT ''
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "checkIns" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "day" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "places" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "name" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "barWeightKg" REAL
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "placeEquipment" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "placeID" TEXT NOT NULL REFERENCES "places"("id") ON DELETE CASCADE,
                  "equipment" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'Other'
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "placePlates" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "placeID" TEXT NOT NULL REFERENCES "places"("id") ON DELETE CASCADE,
                  "weightKg" REAL NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "count" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "awards" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "earnedAt" TEXT NOT NULL,
                  "isSeen" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE TABLE "userProfiles" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "name" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "handle" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "sex" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'male',
                  "age" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 28,
                  "heightCm" REAL NOT NULL ON CONFLICT REPLACE DEFAULT 175,
                  "weightKg" REAL NOT NULL ON CONFLICT REPLACE DEFAULT 75,
                  "activityFactor" REAL NOT NULL ON CONFLICT REPLACE DEFAULT 1.55,
                  "weeklyGoal" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 4,
                  "photoFile" TEXT,
                  "bannerFile" TEXT,
                  "badge" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'blue',
                  "memberSince" TEXT
                ) STRICT
                """
            )
            .execute(db)
        }
        migrator.registerMigration("Create indexes") { db in
            try #sql(
                """
                CREATE INDEX "index_routineExercises_on_routineID" ON "routineExercises"("routineID")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_routineExercises_on_exerciseID" ON "routineExercises"("exerciseID")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_plannedSets_on_routineExerciseID" ON "plannedSets"("routineExerciseID")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_routineSchedules_on_routineID" ON "routineSchedules"("routineID")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_workouts_on_startedAt" ON "workouts"("startedAt")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_workouts_on_routineID" ON "workouts"("routineID")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_workoutExercises_on_workoutID" ON "workoutExercises"("workoutID")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_workoutExercises_on_exerciseID" ON "workoutExercises"("exerciseID")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_workoutSets_on_workoutExerciseID" ON "workoutSets"("workoutExerciseID")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_bodyMeasurements_on_kind_date" ON "bodyMeasurements"("kind", "date")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_progressEntries_on_date" ON "progressEntries"("date")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_notes_on_exerciseID" ON "notes"("exerciseID")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_noteAttachments_on_noteID" ON "noteAttachments"("noteID")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_checkIns_on_day" ON "checkIns"("day")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_placeEquipment_on_placeID" ON "placeEquipment"("placeID")
                """
            )
            .execute(db)
            try #sql(
                """
                CREATE INDEX "index_placePlates_on_placeID" ON "placePlates"("placeID")
                """
            )
            .execute(db)
        }
        migrator.registerMigration("Create app settings") { db in
            try #sql(
                """
                CREATE TABLE "appSettings" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                  "theme" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'dark',
                  "units" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'kg',
                  "weekStart" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 1 CHECK ("weekStart" BETWEEN 1 AND 7),
                  "heatmapLabels" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 1,
                  "background" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'dots',
                  "restSeconds" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 90,
                  "effort" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'off',
                  "autoAdvance" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 1,
                  "countdown" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 1,
                  "keepScreenOn" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 1,
                  "multiPlan" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "levelHints" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 1,
                  "demoSize" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'large',
                  "trainReminderMinutes" INTEGER,
                  "alarmSound" TEXT,
                  "alarmSoundName" TEXT,
                  "alarmStyle" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'quiet',
                  "focusCard" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 1,
                  "homeRecommended" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 1,
                  "gamification" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 1
                ) STRICT
                """
            )
            .execute(db)
        }
        try migrator.migrate(database)
        try database.write { db in
            try Exercise.seedCatalog(db)
        }
        defaultDatabase = database
    }
}

/// Overrides SQLite's `uuid()`, used by primary-key defaults, so tests can control it with
/// `.dependency(\.uuid, .incrementing)`.
@DatabaseFunction
nonisolated func uuid() -> UUID {
    @Dependency(\.uuid) var uuid
    return uuid()
}

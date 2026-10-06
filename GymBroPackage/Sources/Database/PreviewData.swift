import Foundation
import SQLiteData

extension DependencyValues {
    /// Fills the database with a believable month of training for Xcode previews: a profile, two
    /// scheduled routines, eight finished workouts, bodyweight entries, a place, a note and a medal.
    /// Call right after `bootstrapDatabase()`, which has already seeded the exercise catalogue.
    ///
    /// ```swift
    /// #Preview {
    ///     let _ = prepareDependencies {
    ///         try! $0.bootstrapDatabase()
    ///         try! $0.seedDatabaseForPreviews()
    ///     }
    ///     HomeView(store: …)
    /// }
    /// ```
    public func seedDatabaseForPreviews() throws {
        let now = Date()
        try defaultDatabase.write { db in
            try db.seed {
                UserProfile(
                    id: UserProfile.singletonID,
                    name: "Alex",
                    handle: "alex",
                    memberSince: now.addingTimeInterval(-120 * day)
                )

                Routine(id: UUID(1), name: "Push", group: "Push / Pull", position: 0)
                Routine(id: UUID(2), name: "Pull", group: "Push / Pull", position: 1)
                RoutineSchedule(id: UUID(), routineID: UUID(1), weekday: 1)
                RoutineSchedule(id: UUID(), routineID: UUID(2), weekday: 3)
                RoutineSchedule(id: UUID(), routineID: UUID(1), weekday: 5)

                for (routine, exercises) in [(1, PreviewLift.push), (2, PreviewLift.pull)] {
                    for (position, lift) in exercises.enumerated() {
                        RoutineExercise(
                            id: UUID(routine * 100 + position),
                            routineID: UUID(routine),
                            exerciseID: lift.exerciseID,
                            position: position
                        )
                        for set in 0..<3 {
                            PlannedSet(
                                id: UUID(),
                                routineExerciseID: UUID(routine * 100 + position),
                                position: set,
                                reps: 8
                            )
                        }
                    }
                }

                // Eight workouts over four weeks, alternating Push and Pull, getting slightly stronger.
                for index in 0..<8 {
                    let isPush = index.isMultiple(of: 2)
                    let startedAt = now.addingTimeInterval(-Double(28 - index * 3) * day + 18 * hour)
                    Workout(
                        id: UUID(1_000 + index),
                        startedAt: startedAt,
                        finishedAt: startedAt.addingTimeInterval(55 * 60),
                        durationSeconds: 55 * 60,
                        routineID: UUID(isPush ? 1 : 2)
                    )
                    for (position, lift) in (isPush ? PreviewLift.push : PreviewLift.pull).enumerated() {
                        WorkoutExercise(
                            id: UUID(10_000 + index * 10 + position),
                            workoutID: UUID(1_000 + index),
                            exerciseID: lift.exerciseID,
                            position: position
                        )
                        for set in 0..<4 {
                            WorkoutSet(
                                id: UUID(),
                                workoutExerciseID: UUID(10_000 + index * 10 + position),
                                position: set,
                                reps: set == 0 ? 10 : 8,
                                weightKg: set == 0
                                    ? lift.startKg * 0.5
                                    : lift.startKg + Double(index / 2) * lift.stepKg,
                                kind: set == 0 ? .warmup : .normal,
                                isCompleted: true
                            )
                        }
                    }
                }

                for week in 0..<8 {
                    BodyMeasurement(
                        id: UUID(),
                        date: now.addingTimeInterval(-Double(49 - week * 7) * day),
                        kind: .bodyweight,
                        value: 79.4 - Double(week) * 0.35
                    )
                }
                BodyMeasurement(id: UUID(), date: now.addingTimeInterval(-14 * day), kind: .waist, value: 84)
                BodyMeasurement(id: UUID(), date: now.addingTimeInterval(-14 * day), kind: .bodyFat, value: 17.5)

                Place(id: UUID(1), name: "City Gym", barWeightKg: 20)
                for equipment in [Equipment.barbell, .dumbbell, .cable, .machine, .bodyweight] {
                    PlaceEquipment(id: UUID(), placeID: UUID(1), equipment: equipment)
                }
                for (weightKg, count) in [(25.0, 4), (20, 4), (10, 4), (5, 4), (2.5, 4), (1.25, 2)] {
                    PlacePlate(id: UUID(), placeID: UUID(1), weightKg: weightKg, count: count)
                }

                Note(
                    id: UUID(),
                    exerciseID: PreviewLift.push[0].exerciseID,
                    date: now.addingTimeInterval(-4 * day),
                    kind: .plan,
                    text: "Pause reps next week\nTwo-second pause on the chest, same weight.",
                    createdAt: now.addingTimeInterval(-4 * day)
                )
                Award(id: "firstWorkout", earnedAt: now.addingTimeInterval(-28 * day), isSeen: true)
                CheckIn(id: UUID(), day: Calendar.current.startOfDay(for: now.addingTimeInterval(-2 * day)))
            }
        }
    }
}

private let hour: TimeInterval = 60 * 60
private let day: TimeInterval = 24 * hour

/// Catalogue exercises used by the preview data, with a starting weight and weekly progression.
private struct PreviewLift {
    var exerciseID: Exercise.ID
    var startKg: Double
    var stepKg: Double

    static let push = [
        PreviewLift(exerciseID: "EIeI8Vf", startKg: 70, stepKg: 2.5),  // Barbell Bench Press
        PreviewLift(exerciseID: "kTbSH9h", startKg: 40, stepKg: 2.5),  // Barbell Seated Overhead Press
        PreviewLift(exerciseID: "DsgkuIt", startKg: 10, stepKg: 1),  // Dumbbell Lateral Raise
    ]

    static let pull = [
        PreviewLift(exerciseID: "ila4NZS", startKg: 100, stepKg: 5),  // Barbell Deadlift
        PreviewLift(exerciseID: "eZyBC3j", startKg: 60, stepKg: 2.5),  // Barbell Bent Over Row
        PreviewLift(exerciseID: "25GPyDY", startKg: 30, stepKg: 1.25),  // Barbell Curl
    ]
}

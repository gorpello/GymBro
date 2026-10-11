import ComposableArchitecture
import DependenciesTestSupport
import Foundation
import L10n
import OnboardingFeature
import SQLiteData
import Testing

@testable import Database

/// First run, on a fresh database, on Wednesday 7 October 2026 at 20:00 UTC.
@MainActor
@Suite(
    .dependencies {
        $0.calendar = calendar
        $0.date.now = now
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct OnboardingTests {
    @Dependency(\.defaultDatabase) var database

    @Test func finishingSavesTheAnswersAndThePlaces() async throws {
        var state = Onboarding.State()
        state.step = .places
        state.name = "  Sam "
        state.sex = "female"
        state.age = 31
        state.weeklyGoal = 3
        state.units = "lb"
        state.places = ["home", "outdoors"]
        let isDismissed = LockIsolated(false)
        let store = TestStore(initialState: state) {
            Onboarding()
        } withDependencies: {
            $0.dismiss = DismissEffect { isDismissed.setValue(true) }
        }

        await store.send(.nextButtonTapped).finish()

        let profile = try #require(
            try await database.read { db in try UserProfile.find(UserProfile.singletonID).fetchOne(db) })
        #expect(profile.name == "Sam")
        #expect(profile.sex == .female)
        #expect(profile.age == 31)
        #expect(profile.weeklyGoal == 3)
        #expect(profile.memberSince == now)
        let units = try await database.read { db in
            try AppSettings.find(AppSettings.singletonID).select(\.units).fetchOne(db)
        }
        #expect(units == .lb)
        let places = try await database.read { db in try Place.order(by: \.name).select(\.name).fetchAll(db) }
        #expect(places.sorted() == [L10n.placePresetName("home"), L10n.placePresetName("outdoors")].sorted())
        // Being set up is worth a medal.
        #expect(try await database.read { db in try Award.all.fetchCount(db) } > 0)
        #expect(isDismissed.value)
    }

    @Test func skippingStillSetsTheAppUp() async throws {
        let store = TestStore(initialState: Onboarding.State()) {
            Onboarding()
        } withDependencies: {
            $0.dismiss = DismissEffect {}
        }

        await store.send(.skipButtonTapped).finish()

        #expect(try await database.read { db in try UserProfile.all.fetchCount(db) } == 1)
        let gym = try await database.read { db in try PlaceEquipment.all.fetchCount(db) }
        #expect(gym == Equipment.all.count)
    }

    @Test func goingBackAndForthSavesNothing() async throws {
        let store = TestStore(initialState: Onboarding.State()) { Onboarding() }

        await store.send(.nextButtonTapped) {
            $0.step = .name
        }
        await store.send(.backButtonTapped) {
            $0.step = .welcome
        }
        #expect(try await database.read { db in try UserProfile.all.fetchCount(db) } == 0)
    }
}

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 20))!

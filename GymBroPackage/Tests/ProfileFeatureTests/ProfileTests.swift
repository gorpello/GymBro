import ComposableArchitecture
import Foundation
import ProfileFeature
import SQLiteData
import Testing

@testable import Database

extension ProfileFeatureSuite {
    @MainActor
    @Suite struct ProfileTests {
        @Dependency(\.defaultDatabase) var database

        @Test func shortcutsNavigate() async {
            let store = TestStore(initialState: Profile.State()) { Profile() }

            await store.send(.medalsButtonTapped)
            await store.receive(\.delegate.navigate, .awards)
            await store.send(.photosButtonTapped)
            await store.receive(\.delegate.navigate, .moments)
            await store.send(.settingsButtonTapped)
            await store.receive(\.delegate.navigate, .settings)
            await store.send(.shareButtonTapped)
            await store.receive(\.delegate.navigate, .share)
        }

        @Test func editingStartsFromTheSavedProfileAndUnits() async throws {
            try await database.write(seedAlex)
            let state = Profile.State()
            try await state.$summary.load(request)
            let store = TestStore(initialState: state) { Profile() }

            await store.send(.editProfileButtonTapped) {
                $0.edit = ProfileEdit.State(profile: alex, units: .lb)
            }
            await store.send(\.edit.doneButtonTapped)
            await store.receive(\.edit.dismiss) {
                $0.edit = nil
            }
        }

        @Test func editsShowUpOnTheProfile() async throws {
            let store = TestStore(initialState: Profile.State()) { Profile() }
            store.exhaustivity = .off

            let task = await store.send(.task)
            await store.send(.editProfileButtonTapped)
            await store.send(.edit(.presented(.binding(.set(\.profile.name, "Sam"))))).finish()

            try await waitUntil { store.state.summary.profile.name == "Sam" }
            await task.cancel()
        }
    }

    @MainActor
    @Suite struct ProfileEditTests {
        @Dependency(\.defaultDatabase) var database

        @Test func changesAreSaved() async throws {
            let store = TestStore(initialState: ProfileEdit.State()) { ProfileEdit() }

            await store.send(.binding(.set(\.profile.name, "Alex"))) {
                $0.profile.name = "Alex"
            }
            .finish()
            await store.send(.binding(.set(\.profile.sex, .female))) {
                $0.profile.sex = .female
            }
            .finish()
            #expect(try savedProfile() == store.state.profile)
            #expect(try database.read { db in try UserProfile.all.fetchCount(db) } == 1)
        }

        @Test func handlesKeepOnlyLettersDigitsUnderscoresAndDots() async throws {
            let store = TestStore(initialState: ProfileEdit.State()) { ProfileEdit() }

            await store.send(.binding(.set(\.profile.handle, "@alex lifts_2.0!"))) {
                $0.profile.handle = "alexlifts_2.0"
            }
            .finish()
            #expect(try savedProfile()?.handle == "alexlifts_2.0")
        }

        @Test func steppersStayWithinBounds() async throws {
            var profile = UserProfile()
            profile.age = 90
            profile.weeklyGoal = 1
            profile.heightCm = 250
            let store = TestStore(initialState: ProfileEdit.State(profile: profile)) { ProfileEdit() }

            await store.send(.incrementButtonTapped(.age)).finish()
            await store.send(.decrementButtonTapped(.weeklyGoal)).finish()
            await store.send(.incrementButtonTapped(.height)).finish()
            await store.send(.decrementButtonTapped(.age)) {
                $0.profile.age = 89
            }
            .finish()
            #expect(try savedProfile()?.age == 89)
        }

        @Test func weightStepsByHalfAKiloOrAPound() async {
            let kilograms = TestStore(initialState: ProfileEdit.State(units: .kg)) { ProfileEdit() }
            await kilograms.send(.incrementButtonTapped(.weight)) {
                $0.profile.weightKg = 75.5
            }
            .finish()

            let pounds = TestStore(initialState: ProfileEdit.State(units: .lb)) { ProfileEdit() }
            await pounds.send(.decrementButtonTapped(.weight)) {
                $0.profile.weightKg = 75 - 0.45359237
            }
            .finish()
        }

        private func savedProfile() throws -> UserProfile? {
            try database.read { db in try UserProfile.find(UserProfile.singletonID).fetchOne(db) }
        }
    }
}

/// Database observations deliver on their own schedule; polls until `condition` holds.
@MainActor
private func waitUntil(
    timeout: Duration = .seconds(2),
    sourceLocation: SourceLocation = #_sourceLocation,
    _ condition: () -> Bool
) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while !condition() {
        guard clock.now < deadline else {
            Issue.record("Condition not met within \(timeout)", sourceLocation: sourceLocation)
            return
        }
        try await clock.sleep(for: .milliseconds(10))
    }
}

import ComposableArchitecture
import CustomDump
import DependenciesTestSupport
import Foundation
import SQLiteData
import SettingsFeature
import Testing

@testable import Database

@MainActor
@Suite(
    .dependencies {
        $0.uuid = .incrementing
        try $0.bootstrapDatabase()
    }
)
struct PreferencesTests {
    @Dependency(\.defaultDatabase) var database

    @Test func schemaDefaultsMatchTheModel() throws {
        let saved = try #require(
            try database.write { db in
                try #sql(#"INSERT INTO "appSettings" DEFAULT VALUES"#).execute(db)
                return try AppSettings.all.fetchOne(db)
            }
        )
        expectNoDifference(saved, AppSettings(id: saved.id))
    }

    @Test func taskWithNothingSavedKeepsTheDefaults() async {
        let store = TestStore(initialState: Preferences.State()) { Preferences() }

        await store.send(.task).finish()
    }

    @Test func taskLoadsTheSavedSettings() async throws {
        var saved = AppSettings()
        saved.theme = .light
        saved.units = .lb
        saved.restSeconds = 120
        saved.alarmSoundName = "Gong"
        try await database.write { [saved] db in
            try db.seed { saved }
        }
        let store = TestStore(initialState: Preferences.State()) { Preferences() }

        await store.send(.task)
        await store.receive(\.settingsLoaded) {
            $0.settings = saved
        }
    }

    @Test func changesAreSaved() async throws {
        let store = TestStore(initialState: Preferences.State()) { Preferences() }

        await store.send(.binding(.set(\.settings.units, .lb))) {
            $0.settings.units = .lb
        }
        .finish()
        #expect(try fetchSettings() == store.state.settings)

        await store.send(.binding(.set(\.settings.theme, .system))) {
            $0.settings.theme = .system
        }
        .finish()
        await store.send(.binding(.set(\.settings.keepScreenOn, false))) {
            $0.settings.keepScreenOn = false
        }
        .finish()
        #expect(try fetchSettings() == store.state.settings)
        await #expect(try database.read { db in try AppSettings.all.fetchCount(db) } == 1)
    }

    @Test func restTimerStepsByFifteenWithinBounds() async throws {
        var state = Preferences.State()
        state.settings.restSeconds = 15
        let store = TestStore(initialState: state) { Preferences() }

        await store.send(.restDecrementButtonTapped) {
            $0.settings.restSeconds = 0
        }
        .finish()
        await store.send(.restDecrementButtonTapped).finish()
        await store.send(.restIncrementButtonTapped) {
            $0.settings.restSeconds = 15
        }
        .finish()
        #expect(try fetchSettings()?.restSeconds == 15)

        store.exhaustivity = .off
        for _ in 0..<50 {
            await store.send(.restIncrementButtonTapped).finish()
        }
        #expect(store.state.settings.restSeconds == 600)
        #expect(try fetchSettings()?.restSeconds == 600)
    }

    @Test func shortcutsNavigate() async {
        let store = TestStore(initialState: Preferences.State()) { Preferences() }

        await store.send(.aboutButtonTapped)
        await store.receive(\.delegate.navigate, .about)
        await store.send(.placesButtonTapped)
        await store.receive(\.delegate.navigate, .places)
        await store.send(.stravaButtonTapped)
        await store.receive(\.delegate.navigate, .strava)
    }

    private func fetchSettings() throws -> AppSettings? {
        try database.read { db in
            try AppSettings.find(AppSettings.singletonID).fetchOne(db)
        }
    }
}

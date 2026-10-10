import ComposableArchitecture
import Database
import Routing
import SQLiteData

/// Settings: general, training, reminders, home, data & backup, support.
@Reducer
public struct Preferences: Sendable {
    @ObservableState
    public struct State: Equatable {
        /// Defaults until `.task` reads the saved row; every change is written straight back.
        public var settings = AppSettings()

        public init() {}
    }

    public enum Action: BindableAction {
        case aboutButtonTapped
        case binding(BindingAction<State>)
        case buyCoffeeButtonTapped
        case delegate(Delegate)
        case deleteAllButtonTapped
        case exportBackupButtonTapped
        case exportCsvButtonTapped
        case importBackupButtonTapped
        case importFromAppButtonTapped
        case placesButtonTapped
        case reportBugButtonTapped
        case requestFeatureButtonTapped
        case restDecrementButtonTapped
        case restIncrementButtonTapped
        case settingsLoaded(AppSettings)
        case starButtonTapped
        case stravaButtonTapped
        case task

        @CasePathable
        public enum Delegate {
            case navigate(Route)
        }
    }

    @Dependency(\.defaultDatabase) var database

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .aboutButtonTapped:
                return .send(.delegate(.navigate(.about)))
            case .binding:
                return save(state.settings)
            case .buyCoffeeButtonTapped, .delegate, .deleteAllButtonTapped, .exportBackupButtonTapped,
                .exportCsvButtonTapped, .importBackupButtonTapped, .importFromAppButtonTapped, .reportBugButtonTapped,
                .requestFeatureButtonTapped, .starButtonTapped:
                return .none
            case .placesButtonTapped:
                return .send(.delegate(.navigate(.places)))
            case .restDecrementButtonTapped:
                state.settings.restSeconds = max(
                    AppSettings.restRange.lowerBound, state.settings.restSeconds - AppSettings.restStep
                )
                return save(state.settings)
            case .restIncrementButtonTapped:
                state.settings.restSeconds = min(
                    AppSettings.restRange.upperBound, state.settings.restSeconds + AppSettings.restStep
                )
                return save(state.settings)
            case let .settingsLoaded(settings):
                state.settings = settings
                return .none
            case .stravaButtonTapped:
                return .send(.delegate(.navigate(.strava)))
            case .task:
                return .run { send in
                    await withErrorReporting {
                        let settings = try await database.read { db in
                            try AppSettings.find(AppSettings.singletonID).fetchOne(db)
                        }
                        if let settings {
                            await send(.settingsLoaded(settings))
                        }
                    }
                }
            }
        }
    }

    /// Saves the whole row; the first save inserts it.
    private func save(_ settings: AppSettings) -> Effect<Action> {
        .run { _ in
            await withErrorReporting {
                try await database.write { db in
                    try AppSettings.upsert { AppSettings.Draft(settings) }.execute(db)
                }
            }
        }
    }
}

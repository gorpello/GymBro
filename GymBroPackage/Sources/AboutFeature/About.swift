import ComposableArchitecture
import Database
import Foundation
import SQLiteData

/// About: what the app promises, what's inside, version, credits and source.
@Reducer
public struct About: Sendable {
    @ObservableState
    public struct State: Equatable {
        /// Exercises in the built-in catalogue.
        @ObservationStateIgnored
        @FetchOne(Exercise.where { !$0.isCustom }.count()) public var exerciseCount = 0
        public var version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

        public init() {}
    }

    public enum Action {
        case buyCoffeeButtonTapped
        case sourceCodeButtonTapped
    }

    @Dependency(\.openURL) var openURL

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .buyCoffeeButtonTapped:
                return .none

            case .sourceCodeButtonTapped:
                return .run { [openURL] _ in await openURL(URL(string: "https://github.com/gorpello/GymBro")!) }
            }
        }
    }
}

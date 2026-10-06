import ComposableArchitecture
import Database
import DesignSystem
import SwiftUI

extension AppFeature {
    /// One-time setup at launch: opens the database, registers Nunito and styles navigation bars.
    @MainActor public static func bootstrap() {
        prepareDependencies {
            // If there are an error on the database the user can't do nothing.
            // swiftlint:disable next force_try
            try! $0.bootstrapDatabase()
        }
        GymFont.register()
        GymAppearance.apply()
    }
}

/// The app's root view; owns the root store.
public struct AppRootView: View {
    @State private var store = Store(initialState: AppFeature.State()) { AppFeature() }

    public init() {}

    public var body: some View {
        AppView(store: store)
            // GymMane defaults to the dark theme; Settings will drive this once it has data.
            .preferredColorScheme(.dark)
    }
}

import ComposableArchitecture
import Database
import DesignSystem
import SQLiteData
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
    @FetchOne(AppSettings.find(AppSettings.singletonID).select { $0.theme })
    private var theme: ThemePreference = AppSettings().theme

    public init() {}

    public var body: some View {
        AppView(store: store)
            .preferredColorScheme(theme.colorScheme)
    }
}

extension ThemePreference {
    /// `nil` lets the system decide.
    fileprivate var colorScheme: ColorScheme? {
        switch self {
        case .dark: .dark
        case .light: .light
        default: nil
        }
    }
}

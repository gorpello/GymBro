import ComposableArchitecture
import DesignSystem
import SwiftUI

extension AppFeature {
    /// One-time setup at launch: registers Nunito and styles navigation bars.
    @MainActor public static func bootstrap() {
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

import AppFeature
import SwiftUI

@main
struct GymBroApp: App {
    init() {
        AppFeature.bootstrap()
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

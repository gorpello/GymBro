import ComposableArchitecture
import Testing
import TrainFeature

@testable import AppFeature

@MainActor
struct AppFeatureTests {
    @Test func selectingATabSwitchesToIt() async {
        let store = TestStore(initialState: AppFeature.State()) { AppFeature() }
        
        await store.send(.tabSelected(.progress)) {
            $0.selectedTab = .progress
        }
        await store.send(.tabSelected(.profile)) {
            $0.selectedTab = .profile
        }
    }
    
    @Test func startWorkoutOpensTheStartSheetWithoutChangingTab() async {
        let store = TestStore(initialState: AppFeature.State()) { AppFeature() }
        
        await store.send(.tabSelected(.exercises)) {
            $0.selectedTab = .exercises
        }
        await store.send(.startWorkoutTapped) {
            $0.destination = .start(StartWorkout.State())
        }
    }
}

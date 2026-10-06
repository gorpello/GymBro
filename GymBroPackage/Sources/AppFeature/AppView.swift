import AIPlanFeature
import AboutFeature
import AwardsFeature
import CompareFeature
import ComposableArchitecture
import DesignSystem
import ExercisesFeature
import HomeFeature
import L10n
import MeasuresFeature
import MomentsFeature
import NotesFeature
import OnboardingFeature
import PlacesFeature
import ProfileFeature
import ProgressFeature
import RoutinesFeature
import SessionFeature
import SettingsFeature
import ShareFeature
import StickerFeature
import SwiftUI
import TimelineFeature
import ToolsFeature
import TrainFeature

public struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        tabs
            .tint(GymColor.text)
            .modifier(Modals(store: store))
    }

    private var tabs: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            // SF Symbols in system chrome (HIG); the tab bar picks the filled variant for the selection.
            Tab(L10n.home.titleCased, systemImage: "house", value: AppFeature.Tab.home) { homeTab }
            Tab(L10n.progress.titleCased, systemImage: "chart.line.uptrend.xyaxis", value: AppFeature.Tab.progress) {
                progressTab
            }
            Tab(L10n.exercises.titleCased, systemImage: "dumbbell", value: AppFeature.Tab.exercises) { exercisesTab }
            Tab(L10n.profile, systemImage: "person.crop.circle", value: AppFeature.Tab.profile) { profileTab }
        }
        // HIG: tab bars are for navigation, not actions. Starting a workout lives in the tab bar accessory.
        .tabViewBottomAccessory {
            Button(L10n.startWorkout, systemImage: "play.fill") { store.send(.startWorkoutTapped) }
        }
    }

    private var homeTab: some View {
        NavigationStack(path: $store.scope(state: \.homePath, action: \.homePath)) {
            HomeView(store: store.scope(state: \.home, action: \.home))
        } destination: {
            destination($0)
        }
    }

    private var progressTab: some View {
        NavigationStack(path: $store.scope(state: \.progressPath, action: \.progressPath)) {
            ProgressOverviewView(store: store.scope(state: \.progress, action: \.progress))
        } destination: {
            destination($0)
        }
    }

    private var exercisesTab: some View {
        NavigationStack(path: $store.scope(state: \.exercisesPath, action: \.exercisesPath)) {
            ExerciseLibraryView(store: store.scope(state: \.exercises, action: \.exercises))
        } destination: {
            destination($0)
        }
    }

    private var profileTab: some View {
        NavigationStack(path: $store.scope(state: \.profilePath, action: \.profilePath)) {
            ProfileView(store: store.scope(state: \.profile, action: \.profile))
        } destination: {
            destination($0)
        }
    }

    @ViewBuilder
    private func destination(_ store: StoreOf<AppPath>) -> some View {
        switch store.case {
        case let .about(store): AboutView(store: store)
        case let .aiPlan(store): AIPlanView(store: store)
        case let .awards(store): AwardsView(store: store)
        case let .compare(store): CompareView(store: store)
        case let .exerciseDetail(store): ExerciseDetailView(store: store)
        case let .measures(store): MeasuresView(store: store)
        case let .moments(store): MomentsView(store: store)
        case let .noteEdit(store): NoteEditView(store: store)
        case let .notes(store): NotesView(store: store)
        case let .places(store): PlacesView(store: store)
        case let .preferences(store): PreferencesView(store: store)
        case let .routineEdit(store): RoutineEditView(store: store)
        case let .routines(store): RoutinesView(store: store)
        case let .sticker(store): StickerView(store: store)
        case let .timeline(store): PhotoTimelineView(store: store)
        case let .toolDetail(store): ToolDetailView(store: store)
        case let .tools(store): ToolsView(store: store)
        }
    }
}

/// Sheets and full-screen covers for `AppDestination`.
private struct Modals: ViewModifier {
    @Bindable var store: StoreOf<AppFeature>

    func body(content: Content) -> some View {
        content
            .sheet(item: $store.scope(state: \.destination?.start, action: \.destination.start)) {
                StartWorkoutView(store: $0)
            }
            .sheet(item: $store.scope(state: \.destination?.planImport, action: \.destination.planImport)) {
                PlanImportView(store: $0)
            }
            .sheet(item: $store.scope(state: \.destination?.share, action: \.destination.share)) {
                ShareCardView(store: $0)
            }
            .sheet(item: $store.scope(state: \.destination?.strava, action: \.destination.strava)) {
                StravaExportView(store: $0)
            }
            .modifier(Covers(store: store))
    }
}

private struct Covers: ViewModifier {
    @Bindable var store: StoreOf<AppFeature>

    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: $store.scope(state: \.destination?.train, action: \.destination.train)) {
                TrainView(store: $0)
            }
            .fullScreenCover(item: $store.scope(state: \.destination?.session, action: \.destination.session)) {
                SessionView(store: $0)
            }
            .fullScreenCover(item: $store.scope(state: \.destination?.onboarding, action: \.destination.onboarding)) {
                OnboardingView(store: $0)
            }
    }
}

#Preview {
    AppView(store: Store(initialState: AppFeature.State()) { AppFeature() })
}

import ComposableArchitecture
import ExercisesFeature
import HomeFeature
import ProfileFeature
import ProgressFeature
import Routing
import TrainFeature

/// Root of the app: four tabs, each with its own navigation stack, a "Start workout" action in
/// the tab bar accessory, and modal destinations on top.
@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: AppDestination.State?
        public var exercises = ExerciseLibrary.State()
        public var exercisesPath = StackState<AppPath.State>()
        public var home = Home.State()
        public var homePath = StackState<AppPath.State>()
        public var profile = Profile.State()
        public var profilePath = StackState<AppPath.State>()
        public var progress = ProgressOverview.State()
        public var progressPath = StackState<AppPath.State>()
        public var selectedTab: Tab = .home
        
        public init() {}
    }
    
    public enum Tab: Hashable, Sendable {
        case home, progress, exercises, profile
    }
    
    public enum Action {
        case destination(PresentationAction<AppDestination.Action>)
        case exercises(ExerciseLibrary.Action)
        case exercisesPath(StackActionOf<AppPath>)
        case home(Home.Action)
        case homePath(StackActionOf<AppPath>)
        case profile(Profile.Action)
        case profilePath(StackActionOf<AppPath>)
        case progress(ProgressOverview.Action)
        case progressPath(StackActionOf<AppPath>)
        case startWorkoutTapped
        case tabSelected(Tab)
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.home, action: \.home) { Home() }
        Scope(state: \.progress, action: \.progress) { ProgressOverview() }
        Scope(state: \.exercises, action: \.exercises) { ExerciseLibrary() }
        Scope(state: \.profile, action: \.profile) { Profile() }
        Reduce { state, action in
            switch action {
            case let .destination(.presented(action)):
                guard let route = action.route else { return .none }
                // A modal asking for another modal replaces itself (Train → Session, Start → Train…).
                if let destination = AppDestination.State(route) {
                    state.destination = destination
                } else if let screen = AppPath.State(route) {
                    state.destination = nil
                    state.push(screen)
                }
                return .none
                
            case let .exercises(.delegate(.navigate(route))),
                let .home(.delegate(.navigate(route))),
                let .profile(.delegate(.navigate(route))),
                let .progress(.delegate(.navigate(route))):
                state.navigate(to: route)
                return .none
                
            case let .exercisesPath(.element(_, action)),
                let .homePath(.element(_, action)),
                let .profilePath(.element(_, action)),
                let .progressPath(.element(_, action)):
                if let route = action.route { state.navigate(to: route) }
                return .none
                
            case .startWorkoutTapped:
                state.destination = .start(StartWorkout.State())
                return .none
                
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case .destination, .exercises, .exercisesPath, .home, .homePath, .profile, .profilePath,
                    .progress, .progressPath:
                return .none
            }
        }
        .forEach(\.homePath, action: \.homePath)
        .forEach(\.progressPath, action: \.progressPath)
        .forEach(\.exercisesPath, action: \.exercisesPath)
        .forEach(\.profilePath, action: \.profilePath)
        .ifLet(\.$destination, action: \.destination)
    }
}

extension AppFeature.State {
    mutating func navigate(to route: Route) {
        if let destination = AppDestination.State(route) {
            self.destination = destination
        } else if let screen = AppPath.State(route) {
            push(screen)
        }
    }
    
    mutating func push(_ screen: AppPath.State) {
        switch selectedTab {
        case .home: homePath.append(screen)
        case .progress: progressPath.append(screen)
        case .exercises: exercisesPath.append(screen)
        case .profile: profilePath.append(screen)
        }
    }
}

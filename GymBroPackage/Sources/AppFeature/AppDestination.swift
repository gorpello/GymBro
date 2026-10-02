import ComposableArchitecture
import OnboardingFeature
import Routing
import RoutinesFeature
import SessionFeature
import ShareFeature
import TrainFeature

/// Everything presented modally over the tabs.
@Reducer
public enum AppDestination {
    case onboarding(Onboarding)
    case planImport(PlanImport)
    case session(Session)
    case share(ShareCard)
    case start(StartWorkout)
    case strava(StravaExport)
    case train(Train)
}

extension AppDestination.State: Equatable {}

extension AppDestination.State {
    /// The modal for a presented route, or `nil` if the route is pushed.
    init?(_ route: Route) {
        switch route {
        case .onboarding: self = .onboarding(Onboarding.State())
        case .planImport: self = .planImport(PlanImport.State())
        case .session: self = .session(Session.State())
        case .share: self = .share(ShareCard.State())
        case .start: self = .start(StartWorkout.State())
        case .strava: self = .strava(StravaExport.State())
        case .train: self = .train(Train.State())
        default: return nil
        }
    }
}

extension AppDestination.Action {
    /// The route a modal asked for, if this action is one of its navigation delegates.
    var route: Route? {
        switch self {
        case let .session(.delegate(.navigate(route))),
            let .start(.delegate(.navigate(route))),
            let .train(.delegate(.navigate(route))):
            return route
        default:
            return nil
        }
    }
}

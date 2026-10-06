import AIPlanFeature
import AboutFeature
import AwardsFeature
import CompareFeature
import ComposableArchitecture
import ExercisesFeature
import MeasuresFeature
import MomentsFeature
import NotesFeature
import PlacesFeature
import RoutinesFeature
import Routing
import SettingsFeature
import StickerFeature
import TimelineFeature
import ToolsFeature

/// Every screen that can be pushed onto a tab's navigation stack.
@Reducer
public enum AppPath {
    case about(About)
    case aiPlan(AIPlan)
    case awards(Awards)
    case compare(Compare)
    case exerciseDetail(ExerciseDetail)
    case measures(Measures)
    case moments(Moments)
    case noteEdit(NoteEdit)
    case notes(Notes)
    case places(Places)
    case preferences(Preferences)
    case routineEdit(RoutineEdit)
    case routines(Routines)
    case sticker(Sticker)
    case timeline(Timeline)
    case toolDetail(ToolDetail)
    case tools(Tools)
}

extension AppPath.State: Equatable {}

extension AppPath.State {
    /// The screen for a pushed route, or `nil` if the route is presented modally.
    init?(_ route: Route) {
        switch route {
        case .about: self = .about(About.State())
        case .aiPlan: self = .aiPlan(AIPlan.State())
        case .awards: self = .awards(Awards.State())
        case .compare: self = .compare(Compare.State())
        case let .exerciseDetail(id): self = .exerciseDetail(ExerciseDetail.State(id: id))
        case .measures: self = .measures(Measures.State())
        case .moments: self = .moments(Moments.State())
        case let .noteEdit(id): self = .noteEdit(NoteEdit.State(id: id))
        case .notes: self = .notes(Notes.State())
        case .places: self = .places(Places.State())
        case let .routineEdit(id): self = .routineEdit(RoutineEdit.State(id: id))
        case .routines: self = .routines(Routines.State())
        case .settings: self = .preferences(Preferences.State())
        case .sticker: self = .sticker(Sticker.State())
        case .timeline: self = .timeline(Timeline.State())
        case let .toolDetail(id): self = .toolDetail(ToolDetail.State(id: id))
        case .tools: self = .tools(Tools.State())
        case .onboarding, .planImport, .session, .share, .start, .strava, .train:
            return nil
        }
    }
}

extension AppPath.Action {
    /// The route a pushed screen asked for, if this action is one of its navigation delegates.
    var route: Route? {
        switch self {
        case let .compare(.delegate(.navigate(route))),
            let .exerciseDetail(.delegate(.navigate(route))),
            let .notes(.delegate(.navigate(route))),
            let .preferences(.delegate(.navigate(route))),
            let .routineEdit(.delegate(.navigate(route))),
            let .routines(.delegate(.navigate(route))),
            let .timeline(.delegate(.navigate(route))),
            let .tools(.delegate(.navigate(route))):
            return route
        default:
            return nil
        }
    }
}

/// Every place a feature can ask the app to go. Features send `.delegate(.navigate(route))`;
/// `AppFeature` decides whether the route is pushed onto the current tab or presented.
public enum Route: Equatable, Sendable {
    // MARK: Pushed onto the current tab's stack

    case about
    case aiPlan
    case awards
    case compare
    case exerciseDetail(id: String)
    case measures
    case moments
    case noteEdit(id: String?)
    case notes
    case places
    case routineEdit(id: String?)
    case routines
    case settings
    case sticker
    case timeline
    case toolDetail(id: String)
    case tools

    // MARK: Presented modally

    case onboarding
    case planImport
    case session
    case share
    case start
    case strava
    case train
}

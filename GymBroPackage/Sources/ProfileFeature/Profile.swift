import ComposableArchitecture
import Database
import Foundation
import Routing
import SQLiteData

/// The Profile tab: banner, avatar, level, lifetime stats, medals, photos and the year in review.
@Reducer
public struct Profile {
    @ObservableState
    public struct State: Equatable {
        @Presents public var edit: ProfileEdit.State?
        @ObservationStateIgnored
        @Fetch public var summary = ProfileSummary()

        public init() {}
    }

    public enum Action {
        case delegate(Delegate)
        case edit(PresentationAction<ProfileEdit.Action>)
        case editProfileButtonTapped
        case medalsButtonTapped
        case photosButtonTapped
        case settingsButtonTapped
        case shareButtonTapped
        case takePhotoButtonTapped
        case task

        @CasePathable
        public enum Delegate {
            case navigate(Route)
        }
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .delegate, .edit:
                return .none
            case .editProfileButtonTapped:
                state.edit = ProfileEdit.State(profile: state.summary.profile, units: state.summary.units)
                return .none
            case .medalsButtonTapped:
                return .send(.delegate(.navigate(.awards)))
            case .photosButtonTapped, .takePhotoButtonTapped:
                return .send(.delegate(.navigate(.moments)))
            case .settingsButtonTapped:
                return .send(.delegate(.navigate(.settings)))
            case .shareButtonTapped:
                return .send(.delegate(.navigate(.share)))
            case .task:
                return .run { [summary = state.$summary, calendar, now] _ in
                    await withErrorReporting {
                        try await summary.load(ProfileSummary.Request(today: now, calendar: calendar)).task
                    }
                }
            }
        }
        .ifLet(\.$edit, action: \.edit) {
            ProfileEdit()
        }
    }
}

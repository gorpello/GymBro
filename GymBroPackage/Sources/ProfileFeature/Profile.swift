import ComposableArchitecture
import Routing

/// The Profile tab: banner, avatar, level, lifetime stats, medals, photos and the year in review.
@Reducer
public struct Profile {
    @ObservableState
    public struct State: Equatable {
        public var bodyweight: String = "78 kg"
        public var handle: String = "inlitx"
        public var level: Int = 7
        public var lifted: String = "390"
        public var liftedUnit: String = "t"
        /// Most recent medals as award ids (`firstStep`, `streak7`, …).
        public var medals: [MedalRow] = [
            .init(id: "firstStep", name: "First step", isNew: true),
            .init(id: "firstWorkout", name: "First workout", isNew: true),
            .init(id: "firstRoutine", name: "First routine", isNew: true),
            .init(id: "firstRecord", name: "First record", isNew: true),
        ]
        public var medalCount: Int = 13
        public var name: String = "Alex"
        public var photoCount: Int = 3
        public var sets: Int = 640
        public var streakDays: Int = 4
        public var trainedDays: Int = 2
        public var workouts: Int = 64
        public var workoutsToNextLevel: Int = 6
        /// Sessions per month for the "Your year" bars, January first.
        public var yearMonths: [Int] = [0, 0, 0, 0, 2, 6, 9, 12, 14, 8, 0, 0]

        public init() {}
    }

    public enum Action {
        case delegate(Delegate)
        case editProfileButtonTapped
        case medalsButtonTapped
        case photosButtonTapped
        case settingsButtonTapped
        case shareButtonTapped
        case takePhotoButtonTapped

        public enum Delegate {
            case navigate(Route)
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .delegate, .editProfileButtonTapped:
                return .none
            case .medalsButtonTapped:
                return .send(.delegate(.navigate(.awards)))
            case .photosButtonTapped, .takePhotoButtonTapped:
                return .send(.delegate(.navigate(.moments)))
            case .settingsButtonTapped:
                return .send(.delegate(.navigate(.settings)))
            case .shareButtonTapped:
                return .send(.delegate(.navigate(.share)))
            }
        }
    }
}

public struct MedalRow: Equatable, Identifiable, Sendable {
    /// Award id, also the artwork name under `Badges/`.
    public var id: String
    public var name: String
    public var isNew: Bool

    public init(id: String, name: String, isNew: Bool) {
        self.id = id
        self.name = name
        self.isNew = isNew
    }
}

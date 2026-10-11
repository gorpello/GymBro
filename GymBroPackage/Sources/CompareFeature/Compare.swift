import ComposableArchitecture
import Database
import Foundation
import Routing
import SQLiteData

/// Before and after: the same pose on the first and latest progress check-ins, with a
/// drag-to-reveal divider.
@Reducer
public struct Compare: Sendable {
    @ObservableState
    public struct State: Equatable {
        @ObservationStateIgnored
        @Fetch public var comparison = Comparison()
        /// The pose picked; falls back to the first one both days have (see `shownPose`).
        public var pose = "front"
        public var reveal = 0.5

        public init() {}

        /// The pose on screen; `nil` until there are two days to compare.
        public var shownPose: String? {
            comparison.pair?.shownPose(picked: pose)
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case shareButtonTapped
        case task

        @CasePathable
        public enum Delegate {
            case navigate(Route)
        }
    }

    @Dependency(\.calendar) var calendar

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .delegate:
                return .none
            case .shareButtonTapped:
                return .send(.delegate(.navigate(.share)))
            case .task:
                return .run { [comparison = state.$comparison, calendar] _ in
                    await withErrorReporting {
                        try await comparison.load(Comparison.Request(calendar: calendar)).task
                    }
                }
            }
        }
    }
}

/// What the Compare screen reads: a pair once there are two check-ins with photos.
public struct Comparison: Equatable, Sendable {
    public var pair: ComparePair?

    public init(pair: ComparePair? = nil) {
        self.pair = pair
    }

    public struct Request: FetchKeyRequest {
        public var calendar: Calendar

        public init(calendar: Calendar) {
            self.calendar = calendar
        }

        public func fetch(_ db: Database) throws -> Comparison {
            let withPhotos = ProgressEntry.where {
                $0.frontPhoto.isNot(nil) || $0.sidePhoto.isNot(nil) || $0.backPhoto.isNot(nil)
            }
            guard try withPhotos.fetchCount(db) >= 2 else { return Comparison() }
            let first = try withPhotos.order(by: \.date).fetchOne(db)
            let latest = try withPhotos.order { $0.date.desc() }.fetchOne(db)
            guard let before = first, let after = latest else { return Comparison() }
            let days = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: before.date),
                to: calendar.startOfDay(for: after.date)
            )
            return Comparison(pair: ComparePair(before: before, after: after, daysApart: abs(days.day ?? 0)))
        }
    }
}

/// The first and latest progress check-ins with photos (`comparePair` in GymMane).
public struct ComparePair: Equatable, Sendable {
    public var before: ProgressEntry
    public var after: ProgressEntry
    /// Whole days between the two.
    public var daysApart: Int

    public init(before: ProgressEntry, after: ProgressEntry, daysApart: Int) {
        self.before = before
        self.after = after
        self.daysApart = daysApart
    }

    /// Weight on the second day minus the first, when both were logged.
    public var weightChangeKg: Double? {
        guard let first = before.weightKg, let last = after.weightKg else { return nil }
        return last - first
    }

    /// Poses photographed on both days, front first.
    public var poses: [String] {
        ComparePair.allPoses.filter { before.photo($0) != nil && after.photo($0) != nil }
    }

    /// `picked` if both days have it, else the first pose they share.
    public func shownPose(picked: String) -> String? {
        poses.contains(picked) ? picked : poses.first
    }

    static let allPoses = ["front", "side", "back"]
}

extension ProgressEntry {
    /// The photo file for `pose` ("front", "side" or "back").
    func photo(_ pose: String) -> String? {
        switch pose {
        case "front": frontPhoto
        case "side": sidePhoto
        case "back": backPhoto
        default: nil
        }
    }
}

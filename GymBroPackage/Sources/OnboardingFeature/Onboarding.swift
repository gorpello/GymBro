import ComposableArchitecture
import Database
import Foundation
import L10n
import SQLiteData

/// First run: welcome, name, body numbers, weekly goal, units and places. Finishing, or skipping
/// at any point, saves the answers so far and sets up the chosen places.
@Reducer
public struct Onboarding: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var age = 28
        public var heightCm = 175.0
        public var name = ""
        public var places: Set<String> = ["gym"]
        public var sex = "male"
        public var step: Step = .welcome
        public var units = "kg"
        public var weeklyGoal = 4
        public var weightKg = 75.0

        public init() {}
    }

    public enum Step: Int, CaseIterable, Sendable {
        case welcome, name, body, goal, units, places
    }

    public enum Action: BindableAction {
        case backButtonTapped
        case binding(BindingAction<State>)
        case nextButtonTapped
        case placeTapped(String)
        case skipButtonTapped
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.defaultDatabase) var database
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.date.now) var now

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                state.step = Step(rawValue: state.step.rawValue - 1) ?? .welcome
                return .none
            case .binding:
                return .none
            case .nextButtonTapped:
                guard let next = Step(rawValue: state.step.rawValue + 1) else {
                    return finish(state)
                }
                state.step = next
                return .none
            case let .placeTapped(id):
                if state.places.remove(id) == nil { state.places.insert(id) }
                return .none
            case .skipButtonTapped:
                return finish(state)
            }
        }
    }

    /// Saves the answers and the chosen places, then closes.
    private func finish(_ state: State) -> Effect<Action> {
        var profile = UserProfile()
        profile.name = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.sex = Sex(rawValue: state.sex)
        profile.age = state.age
        profile.heightCm = state.heightCm
        profile.weightKg = state.weightKg
        profile.weeklyGoal = state.weeklyGoal
        let units = WeightUnit(rawValue: state.units)
        let places = Place.Preset.all
            .filter { state.places.contains($0.id) }
            .map { (name: L10n.placePresetName($0.id), equipment: $0.equipment) }
        return .run { [profile, units, places, now, calendar, dismiss] _ in
            await withErrorReporting {
                try await database.write { db in
                    for place in places {
                        try Place.create(db, name: place.name, equipment: place.equipment)
                    }
                    try UserProfile.completeOnboarding(db, profile: profile, units: units, now: now, calendar: calendar)
                }
            }
            await dismiss()
        }
    }
}

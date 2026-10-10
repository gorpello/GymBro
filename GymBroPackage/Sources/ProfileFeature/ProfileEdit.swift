import ComposableArchitecture
import Database
import Foundation
import SQLiteData

/// The "Your profile" sheet. Every change is saved straight away, so there is nothing to confirm.
@Reducer
public struct ProfileEdit {
    @ObservableState
    public struct State: Equatable {
        public var profile: UserProfile
        /// How weight is shown and stepped; it is always stored in kilograms.
        public var units: WeightUnit

        public init(profile: UserProfile = UserProfile(), units: WeightUnit = .kg) {
            self.profile = profile
            self.units = units
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case decrementButtonTapped(Field)
        case doneButtonTapped
        case incrementButtonTapped(Field)
    }

    /// A value changed with – and +.
    public enum Field: Sendable {
        case age, height, weight, weeklyGoal
    }

    @Dependency(\.defaultDatabase) var database
    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
            .onChange(of: \.profile.handle) { _, handle in
                Reduce { state, _ in
                    state.profile.handle = UserProfile.sanitizedHandle(handle)
                    return .none
                }
            }
        Reduce { state, action in
            switch action {
            case .binding:
                return save(state.profile)
            case let .decrementButtonTapped(field):
                step(field, by: -1, in: &state)
                return save(state.profile)
            case .doneButtonTapped:
                return .run { _ in await dismiss() }
            case let .incrementButtonTapped(field):
                step(field, by: 1, in: &state)
                return save(state.profile)
            }
        }
    }

    /// Moves `field` one step in `direction` (±1), within the profile's bounds. Weight steps by
    /// half a kilogram, or by a pound when the user weighs in pounds.
    private func step(_ field: Field, by direction: Int, in state: inout State) {
        switch field {
        case .age:
            state.profile.age = (state.profile.age + direction).clamped(to: UserProfile.ageRange)
        case .height:
            state.profile.heightCm = (state.profile.heightCm + Double(direction)).clamped(to: UserProfile.heightRangeCm)
        case .weight:
            let stepKg = state.units == .kg ? 0.5 : state.units.kilograms
            state.profile.weightKg = (state.profile.weightKg + Double(direction) * stepKg)
                .clamped(to: UserProfile.weightRangeKg)
        case .weeklyGoal:
            state.profile.weeklyGoal = (state.profile.weeklyGoal + direction).clamped(to: UserProfile.weeklyGoalRange)
        }
    }

    /// Saves the whole row; the first save inserts it.
    private func save(_ profile: UserProfile) -> Effect<Action> {
        .run { _ in
            await withErrorReporting {
                try await database.write { db in
                    try UserProfile.upsert { UserProfile.Draft(profile) }.execute(db)
                }
            }
        }
    }
}

extension Comparable {
    fileprivate func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

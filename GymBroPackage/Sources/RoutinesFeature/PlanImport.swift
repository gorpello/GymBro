import ComposableArchitecture

/// Paste or open a routine shared from GymMane / GymBro or written by an AI, preview it, add it.
@Reducer
public struct PlanImport {
    @ObservableState
    public struct State: Equatable {
        public var text = ""
        public var usesTheirSchedule = false

        /// Routines found in the pasted text.
        public var found: [ImportedRoutine] = [
            .init(id: "a", exerciseCount: 5, name: "Upper A", weekday: "Mon"),
            .init(id: "b", exerciseCount: 5, name: "Lower A", weekday: "Tue"),
        ]
        /// Exercise names that did not match the library.
        public var missing: Int = 1

        public init() {}
    }

    public enum Action: BindableAction {
        case addButtonTapped
        case binding(BindingAction<State>)
        case chooseFileButtonTapped
        case pasteButtonTapped
    }

    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { _, action in
            switch action {
            case .addButtonTapped:
                return .run { [dismiss] _ in await dismiss() }
            case .binding, .chooseFileButtonTapped, .pasteButtonTapped:
                return .none
            }
        }
    }
}

public struct ImportedRoutine: Equatable, Identifiable, Sendable {
    public var id: String
    public var exerciseCount: Int
    public var name: String
    /// Short weekday name it is planned on, if any.
    public var weekday: String?

    public init(id: String, exerciseCount: Int, name: String, weekday: String?) {
        self.id = id
        self.exerciseCount = exerciseCount
        self.name = name
        self.weekday = weekday
    }
}

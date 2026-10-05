import ComposableArchitecture
import Routing

/// The Exercises tab: searchable, filterable library grouped by muscle.
@Reducer
public struct ExerciseLibrary {
    @ObservableState
    public struct State: Equatable {
        @Presents public var editor: ExerciseEditor.State?
        public var favouritesOnly = false
        public var noKitOnly = false
        public var searchText = ""
        
        public var favouriteCount: Int = 2
        public var libraryCount: Int = 551
        
        // TODO: Remove templates elements
        // swiftlint:disable line_length
        public var sections: [ExerciseSection] = [
            .init(id: "chest", rows: [.init(id: "EIeI8Vf", art: "bench-press", detail: "Barbell · Intermediate", isFavourite: true, name: "Barbell Bench Press"), .init(id: "SpYC0Kp", art: "dumbbell-bench-press", detail: "Dumbbell · Intermediate", isFavourite: false, name: "Dumbbell Bench Press"), .init(id: "3TZduzM", art: "incline-bench-press", detail: "Barbell · Intermediate", isFavourite: false, name: "Barbell Incline Bench Press"), .init(id: "9WTm7dq", art: "chest-dip", detail: "Bodyweight · Intermediate", isFavourite: false, name: "Chest Dip")]),
            .init(id: "back", rows: [.init(id: "pullup", art: "pull-up", detail: "Bodyweight · Intermediate", isFavourite: true, name: "Pull-up"), .init(id: "row", art: "barbell-row", detail: "Barbell · Intermediate", isFavourite: false, name: "Barbell Row")]),
        ]
        // swiftlint:enable line_length
        
        public init() {}
    }
    
    public enum Action: BindableAction {
        case addButtonTapped
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case editor(PresentationAction<ExerciseEditor.Action>)
        case exerciseTapped(id: String)
        case favouriteButtonTapped(id: String)
        case filtersButtonTapped
        
        public enum Delegate {
            case navigate(Route)
        }
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                state.editor = ExerciseEditor.State()
                return .none
            case .binding, .delegate, .editor:
                return .none
            case let .exerciseTapped(id):
                return .send(.delegate(.navigate(.exerciseDetail(id: id))))
            case .favouriteButtonTapped:
                return .none
            case .filtersButtonTapped:
                return .none
            }
        }
        .ifLet(\.$editor, action: \.editor) {
            ExerciseEditor()
        }
    }
}

public struct ExerciseSection: Equatable, Identifiable, Sendable {
    /// Muscle id of the section (`chest`, `back`, …).
    public var id: String
    public var rows: [ExerciseRowState]
    
    public init(id: String, rows: [ExerciseRowState]) {
        self.id = id
        self.rows = rows
    }
}

public struct ExerciseRowState: Equatable, Identifiable, Sendable {
    public var id: String
    /// Illustration name under `Art/`, e.g. `bench-press`.
    public var art: String
    public var detail: String
    public var isFavourite: Bool
    public var name: String
    
    public init(id: String, art: String, detail: String, isFavourite: Bool, name: String) {
        self.id = id
        self.art = art
        self.detail = detail
        self.isFavourite = isFavourite
        self.name = name
    }
}

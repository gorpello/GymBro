import ComposableArchitecture
import Foundation

/// Write or edit a journal note: kind, text, date, exercise and attachments.
@Reducer
public struct NoteEdit {
    @ObservableState
    public struct State: Equatable {
        public let id: String?
        
        public var date: Date = .now
        public var exerciseName: String? = "Barbell Bench Press"
        public var kind: String = "done"
        /// Attached photo and video file names.
        public var media: [String] = []
        public var text: String = "First full 5x5 at 82.5\nlast two were a grind, but clean"
        
        public init(id: String?) {
            self.id = id
        }
    }
    
    public enum Action: BindableAction {
        case attachButtonTapped
        case binding(BindingAction<State>)
        case deleteButtonTapped
        case exerciseButtonTapped
        case saveButtonTapped
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { _, action in
            switch action {
            case .attachButtonTapped, .binding, .exerciseButtonTapped:
                return .none
            case .deleteButtonTapped, .saveButtonTapped:
                return .run { [dismiss] _ in await dismiss() }
            }
        }
    }
}

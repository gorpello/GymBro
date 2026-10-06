import ComposableArchitecture

/// "Routine with AI": copy a request that carries your exercise list, paste the answer back.
/// The app itself never talks to an AI.
@Reducer
public struct AIPlan {

    @ObservableState
    public struct State: Equatable {
        public var answer = ""

        public init() {}
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case chooseFileButtonTapped
        case copyButtonTapped
        case importButtonTapped
        case pasteButtonTapped
        case shareFileButtonTapped
        case showFormatButtonTapped
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { _, action in
            switch action {
            case .binding, .chooseFileButtonTapped, .copyButtonTapped, .importButtonTapped, .pasteButtonTapped,
                .shareFileButtonTapped, .showFormatButtonTapped:
                return .none
            }
        }
    }
}

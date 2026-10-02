import ComposableArchitecture
import Foundation

/// About: what the app promises, what's inside, version, credits and source.
@Reducer
public struct About {
    
    @ObservableState
    public struct State: Equatable {
        public var exerciseCount: Int = 448
        public var version: String = "1.0"
        
        public init() {}
    }
    
    public enum Action {
        case buyCoffeeButtonTapped
        case sourceCodeButtonTapped
    }
    
    @Dependency(\.openURL) var openURL
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .buyCoffeeButtonTapped:
                return .none
                
            case .sourceCodeButtonTapped:
                return .run { [openURL] _ in await openURL(URL(string: "https://github.com/gorpello/GymBro")!) }
            }
        }
    }
}

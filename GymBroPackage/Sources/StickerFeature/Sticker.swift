import ComposableArchitecture
import CoreGraphics

/// Put a workout sticker on a photo: move, pinch and turn it, then save or share.
@Reducer
public struct Sticker {
    @ObservableState
    public struct State: Equatable {
        public var offset: CGSize = .zero
        public var rotation: Double = 0
        public var scale: Double = 1
        public var style: Style = .workout
        
        public var dateTitle: String = "Saturday, Sep 19"
        public var duration: String = "58 min"
        public var exerciseNames: [String] = ["Barbell Bench Press", "Dumbbell Incline Bench Press", "Overhead Press", "Rope Triceps Pushdown"]
        public var hasPhoto: Bool = false
        public var sets: Int = 12
        public var streak: Int = 4
        public var volume: String = "8.4 t"
        public var weekDone: [Bool] = [false, false, true, true, true, true, false]
        
        public init() {}
    }
    
    public enum Style: Hashable, Sendable {
        case workout, streak, date, week
    }
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case cameraButtonTapped
        case galleryButtonTapped
        case saveButtonTapped
        case shareButtonTapped
        case stickerDragged(translation: CGSize)
        case stickerPinched(magnification: Double)
        case stickerRotated(degrees: Double)
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .cameraButtonTapped, .galleryButtonTapped, .saveButtonTapped, .shareButtonTapped:
                return .none
            case let .stickerDragged(translation):
                state.offset.width += translation.width
                state.offset.height += translation.height
                return .none
            case let .stickerPinched(magnification):
                state.scale = min(4, max(0.3, state.scale * magnification))
                return .none
            case let .stickerRotated(degrees):
                state.rotation += degrees
                return .none
            }
        }
    }
}

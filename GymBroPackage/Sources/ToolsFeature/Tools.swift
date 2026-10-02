import ComposableArchitecture
import Routing

/// The six calculators: 1RM, BMI, calories & macros, body fat, plates, warm-up.
@Reducer
public struct Tools {
    @ObservableState
    public struct State: Equatable {
        public var toolIDs = ["rm", "bmi", "cal", "bf", "plate", "warmup"]
        
        public init() {}
    }
    
    public enum Action {
        case delegate(Delegate)
        case toolTapped(id: String)
        
        public enum Delegate {
            case navigate(Route)
        }
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .delegate:
                return .none
            case let .toolTapped(id):
                return .send(.delegate(.navigate(.toolDetail(id: id))))
            }
        }
    }
}

/// One calculator: steppers for its inputs and a result card.
@Reducer
public struct ToolDetail {
    @ObservableState
    public struct State: Equatable {
        public let id: String
        
        public var inputs: [ToolInput] = [
            .init(id: "weight", label: "WEIGHT LIFTED", step: 2.5, unit: "kg", value: 90),
            .init(id: "reps", label: "REPS PERFORMED", step: 1, unit: "", value: 8),
        ]
        /// Lines under the big result (macros, plates per side, ramp sets…).
        public var details: [String] = ["95% · 108 kg", "90% · 102 kg", "80% · 91 kg", "70% · 80 kg"]
        public var result: String = "114"
        public var resultUnit: String = "kg"
        
        public init(id: String) {
            self.id = id
        }
    }
    
    public enum Action {
        case inputChanged(id: String, delta: Double)
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .inputChanged(id, delta):
                guard let index = state.inputs.firstIndex(where: { $0.id == id }) else { return .none }
                state.inputs[index].value = max(0, state.inputs[index].value + delta * state.inputs[index].step)
                return .none
            }
        }
    }
}

public struct ToolInput: Equatable, Identifiable, Sendable {
    public var id: String
    public var label: String
    public var step: Double
    public var unit: String
    public var value: Double
    
    public init(id: String, label: String, step: Double, unit: String, value: Double) {
        self.id = id
        self.label = label
        self.step = step
        self.unit = unit
        self.value = value
    }
}

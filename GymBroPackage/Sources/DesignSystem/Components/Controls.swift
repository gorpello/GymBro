import PhosphorSwift
import SwiftUI

/// Capsule search field (`SearchField`).
public struct SearchField: View {
    let prompt: String
    @Binding var text: String
    
    public init(_ prompt: String, text: Binding<String>) {
        self.prompt = prompt
        self._text = text
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            GymIcon(.magnifyingGlass, size: 16)
                .foregroundStyle(GymColor.textSecondary)
            TextField(prompt, text: $text)
                .font(.gym(14, .medium))
                .foregroundStyle(GymColor.text)
                .tint(GymColor.accent)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    GymIcon(.x, weight: .bold, size: 10)
                        .foregroundStyle(GymColor.textSecondary)
                        .frame(width: 20, height: 20)
                        .background(GymColor.bgRaised2, in: .circle)
                        .frame(width: 40, height: 48)
                }
                .accessibilityLabel("Clear")
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .frame(height: 48)
        .background(GymColor.bgRaised, in: .capsule)
    }
}

/// Segmented capsule (`SegToggle`), e.g. kg | lb or 7D | 30D | Recovery.
public struct SegToggle<Value: Hashable>: View {
    let options: [(value: Value, label: String)]
    @Binding var selection: Value
    let fontSize: CGFloat
    
    public init(_ options: [(value: Value, label: String)], selection: Binding<Value>, fontSize: CGFloat = 12) {
        self.options = options
        self._selection = selection
        self.fontSize = fontSize
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                let selected = option.value == selection
                Button {
                    selection = option.value
                } label: {
                    Text(option.label)
                        .font(.gym(fontSize, .semibold, relativeTo: .footnote))
                        .foregroundStyle(selected ? GymColor.onEmber : GymColor.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background(selected ? GymColor.ember : .clear, in: .capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(GymColor.bgRaised2, in: .capsule)
        .animation(.snappy(duration: 0.2), value: selection)
    }
}

/// – value + (`StepperControl`).
public struct StepperControl: View {
    let value: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    let fontSize: CGFloat
    let buttonSize: CGFloat
    let minWidth: CGFloat
    
    public init(
        _ value: String,
        fontSize: CGFloat = 16,
        buttonSize: CGFloat = 30,
        minWidth: CGFloat = 44,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) {
        self.value = value
        self.fontSize = fontSize
        self.buttonSize = buttonSize
        self.minWidth = minWidth
        self.onDecrement = onDecrement
        self.onIncrement = onIncrement
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            step("–", label: "Decrease", action: onDecrement)
            Text(value)
                .font(.gym(fontSize, .bold, relativeTo: .body))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(GymColor.text)
                .frame(minWidth: minWidth)
            step("+", label: "Increase", action: onIncrement)
        }
    }
    
    private func step(_ glyph: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(.system(size: fontSize + 2, weight: .medium))
                .foregroundStyle(GymColor.text)
                .frame(width: buttonSize, height: buttonSize)
                .background(GymColor.bgRaised2, in: .rect(cornerRadius: 8))
        }
        .buttonStyle(.pressable(scale: 0.9))
        .accessibilityLabel(label)
    }
}

/// Settings-style row: icon, label, and a trailing value / control / chevron (`ToolRow`).
public struct OptionRow<Trailing: View>: View {
    let icon: Ph?
    let title: String
    let detail: String?
    let trailing: Trailing
    
    public init(_ title: String, icon: Ph? = nil, detail: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon
        self.title = title
        self.detail = detail
        self.trailing = trailing()
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            if let icon {
                GymIcon(icon, size: 20)
                    .foregroundStyle(GymColor.textSecondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title.sentenceCased)
                    .font(.gym(14.5, .medium, relativeTo: .body))
                    .foregroundStyle(GymColor.text)
                if let detail {
                    Text(detail)
                        .font(.gym(12, .medium, relativeTo: .footnote))
                        .foregroundStyle(GymColor.textSecondary)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 58)
        .contentShape(.rect)
    }
}

extension OptionRow where Trailing == DisclosureValue {
    /// Row with a grey value and chevron ("Theme   Dark ›").
    public init(_ title: String, icon: Ph? = nil, detail: String? = nil, value: String) {
        self.init(title, icon: icon, detail: detail) { DisclosureValue(value) }
    }
}

/// Grey value + chevron.
public struct DisclosureValue: View {
    let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.gym(13.5, .medium, relativeTo: .subheadline))
                .foregroundStyle(GymColor.textSecondary)
                .lineLimit(1)
            GymIcon(.caretRight, weight: .bold, size: 12)
                .foregroundStyle(GymColor.textTertiary)
        }
    }
}

/// Toggle tinted like `TinySwitch`.
public struct GymToggleStyle: ToggleStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        Toggle(isOn: configuration.$isOn) { configuration.label }
            .toggleStyle(.switch)
            .tint(GymColor.ember)
    }
}

extension ToggleStyle where Self == GymToggleStyle {
    public static var gym: GymToggleStyle { GymToggleStyle() }
}

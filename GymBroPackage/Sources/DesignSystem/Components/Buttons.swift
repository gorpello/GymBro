import PhosphorSwift
import SwiftUI
import UIKit

/// Phosphor icon at a fixed size, tinted by the foreground style.
public struct GymIcon: View {
    let image: Image
    let size: CGFloat

    public init(_ icon: Ph, weight: Ph.IconWeight = .regular, size: CGFloat = 20) {
        self.image = icon.weight(weight).renderingMode(.template)
        self.size = size
    }

    public var body: some View {
        image
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Scale-down press feedback (`Pressable`).
public struct PressableStyle: ButtonStyle {
    let scale: CGFloat

    public init(scale: CGFloat = 0.96) {
        self.scale = scale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(.rect)
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    public static var pressable: PressableStyle { PressableStyle() }
    public static func pressable(scale: CGFloat) -> PressableStyle { PressableStyle(scale: scale) }
}

/// Full-width capsule call to action (`PrimaryButton`): ember fill, 56 pt tall.
public struct PrimaryButtonStyle: ButtonStyle {
    let fill: Color
    let foreground: Color
    let height: CGFloat

    public init(fill: Color = GymColor.ember, foreground: Color = GymColor.onEmber, height: CGFloat = 56) {
        self.fill = fill
        self.foreground = foreground
        self.height = height
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.gym(15.5, .bold, relativeTo: .headline))
            .tracking(0.2)
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, minHeight: height)
            .padding(.horizontal, 16)
            .background(fill, in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    public static func primary(fill: Color, foreground: Color = GymColor.onEmber) -> PrimaryButtonStyle {
        PrimaryButtonStyle(fill: fill, foreground: foreground)
    }
}

/// Secondary capsule on `bgRaised2` (`GhostButton`), 46 pt tall.
public struct GhostButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.gym(13.5, .bold, relativeTo: .subheadline))
            .foregroundStyle(GymColor.text)
            .frame(minHeight: 46)
            .padding(.horizontal, 20)
            .background(GymColor.bgRaised2, in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GhostButtonStyle {
    public static var ghost: GhostButtonStyle { GhostButtonStyle() }
}

/// Circular icon button (`RoundAction`): 36 pt, raised or ember-filled.
public struct RoundButton: View {
    let icon: Ph
    let label: String
    let filled: Bool
    let size: CGFloat
    let action: () -> Void

    public init(_ icon: Ph, label: String, filled: Bool = false, size: CGFloat = 36, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.filled = filled
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            GymIcon(icon, weight: .bold, size: size * 0.44)
                .foregroundStyle(filled ? GymColor.onEmber : GymColor.text)
                .frame(width: size, height: size)
                .background(filled ? GymColor.ember : GymColor.bgRaised, in: .circle)
                .overlay(Circle().strokeBorder(filled ? GymColor.ember : GymColor.border, lineWidth: 1))
        }
        .buttonStyle(.pressable(scale: 0.9))
        .accessibilityLabel(label)
    }
}

/// Small rounded tag / filter chip (`Pill`).
public struct Pill: View {
    let label: String
    let selected: Bool
    let removable: Bool
    let action: () -> Void

    public init(_ label: String, selected: Bool = false, removable: Bool = false, action: @escaping () -> Void = {}) {
        self.label = label
        self.selected = selected
        self.removable = removable
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label.titleCased)
                if removable {
                    GymIcon(.x, weight: .bold, size: 11)
                }
            }
            .font(.gym(13, .semibold, relativeTo: .subheadline))
            .foregroundStyle(selected ? GymColor.onEmber : GymColor.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? GymColor.ember : GymColor.bgRaised2, in: .capsule)
        }
        .buttonStyle(.pressable(scale: 0.94))
    }
}

/// Outline chip with a check or plus (equipment on Places / Onboarding).
public struct ToggleChip: View {
    let label: String
    let isOn: Bool
    let action: () -> Void

    public init(_ label: String, isOn: Bool, action: @escaping () -> Void) {
        self.label = label
        self.isOn = isOn
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                GymIcon(isOn ? .check : .plus, weight: .bold, size: 12)
                Text(label)
            }
            .font(.gym(14, isOn ? .bold : .semibold, relativeTo: .subheadline))
            .foregroundStyle(isOn ? GymColor.text : GymColor.textTertiary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(GymColor.bgRaised2.opacity(isOn ? 1 : 0.6), in: .capsule)
            .overlay(Capsule().strokeBorder(isOn ? GymColor.text : GymColor.border, lineWidth: isOn ? 1.5 : 1))
        }
        .buttonStyle(.pressable(scale: 0.94))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

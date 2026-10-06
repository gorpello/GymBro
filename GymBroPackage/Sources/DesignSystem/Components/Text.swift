import SwiftUI

extension String {
    /// `titleCase` from `ui_kit.dart`: "START WORKOUT" → "Start workout", keeps short tokens and numbers.
    public var titleCased: String {
        guard !isEmpty, self == uppercased() else { return self }
        if count <= 4 && !contains(" ") { return self }
        if rangeOfCharacter(from: .decimalDigits) != nil { return self }
        return prefix(1) + dropFirst().lowercased()
    }

    /// `sentenceCase` from `ui_kit.dart`.
    public var sentenceCased: String {
        guard !isEmpty, self == uppercased(), self != lowercased() else { return self }
        return prefix(1) + dropFirst().lowercased()
    }
}

/// Small spaced caps label ("TODAY", "VOLUME").
public struct Kicker: View {
    let text: String
    let color: Color
    let size: CGFloat
    let spacing: CGFloat

    public init(_ text: String, color: Color = GymColor.textSecondary, size: CGFloat = 12, spacing: CGFloat = 3) {
        self.text = text
        self.color = color
        self.size = size
        self.spacing = spacing
    }

    public var body: some View {
        Text(text.uppercased())
            .font(.gym(size, .semibold, relativeTo: .caption))
            .tracking(spacing * 0.5)
            .foregroundStyle(color)
    }
}

/// Screen-level title in ExtraBold (`ScreenTitle`).
public struct ScreenTitle: View {
    let text: String
    let size: CGFloat

    public init(_ text: String, size: CGFloat = 28) {
        self.text = text
        self.size = size
    }

    public var body: some View {
        Text(text.titleCased)
            .font(.gym(size, .extraBold, relativeTo: .largeTitle))
            .foregroundStyle(GymColor.text)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

/// Section title with an optional trailing chevron ("This week", "Activity  ›").
public struct SectionHeader<Trailing: View>: View {
    let title: String
    let trailing: Trailing

    public init(_ title: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.titleCased)
                .font(.gym(20, .extraBold, relativeTo: .title3))
                .foregroundStyle(GymColor.text)
            Spacer(minLength: 8)
            trailing
        }
    }
}

/// Big number with a small unit ("28.8 t", "60 h").
public struct StatValue: View {
    let value: String
    let unit: String?
    let size: CGFloat

    public init(_ value: String, unit: String? = nil, size: CGFloat = 28) {
        self.value = value
        self.unit = unit
        self.size = size
    }

    public var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 3) {
            Text(value)
                .font(.gym(size, .extraBold, relativeTo: .title))
                .monospacedDigit()
                .contentTransition(.numericText())
            if let unit {
                Text(unit)
                    .font(.gym(size * 0.5, .semibold, relativeTo: .footnote))
                    .foregroundStyle(GymColor.textSecondary)
            }
        }
        .foregroundStyle(GymColor.text)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

/// Kicker above a stat value.
public struct StatBlock: View {
    let label: String
    let value: String
    let unit: String?
    let size: CGFloat

    public init(_ label: String, value: String, unit: String? = nil, size: CGFloat = 26) {
        self.label = label
        self.value = value
        self.unit = unit
        self.size = size
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Kicker(label, size: 11, spacing: 1.5)
            StatValue(value, unit: unit, size: size)
        }
    }
}

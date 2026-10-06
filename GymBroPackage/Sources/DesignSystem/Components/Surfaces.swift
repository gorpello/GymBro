import SwiftUI

extension View {
    /// `SoftCard`: raised surface, hairline border, 20 pt corners.
    public func softCard(
        padding: CGFloat = 20,
        radius: CGFloat = 20,
        fill: Color = GymColor.bgRaised,
        border: Color = GymColor.border
    ) -> some View {
        self
            .padding(padding)
            .background(fill, in: .rect(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(border, lineWidth: 1))
    }

    /// Page background with the chosen pattern, used by every screen.
    public func gymBackground(_ pattern: BackgroundPattern = .dots) -> some View {
        background {
            ZStack {
                GymColor.bg
                BackgroundPatternView(pattern: pattern)
            }
            .ignoresSafeArea()
        }
    }

    /// Pushed screen chrome: Nunito title + subtitle next to the native back button
    /// (GymMane's `ScreenHeader`), on the patterned background.
    public func gymScreen(_ title: String, subtitle: String? = nil) -> some View {
        self
            .scrollContentBackground(.hidden)
            .gymBackground()
            .navigationTitle(title.titleCased)
            .navigationSubtitle(subtitle ?? "")
            .toolbarTitleDisplayMode(.inlineLarge)
    }
}

/// `app_background.dart`: dots, grid or nothing.
public enum BackgroundPattern: String, CaseIterable, Sendable {
    case dots, grid, none
}

struct BackgroundPatternView: View {
    let pattern: BackgroundPattern
    static let gap: CGFloat = 26

    var body: some View {
        Canvas { context, size in
            let color = GymColor.border.opacity(0.5)
            switch pattern {
            case .dots:
                var y = Self.gap
                while y < size.height {
                    var x = Self.gap
                    while x < size.width {
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - 1.1, y: y - 1.1, width: 2.2, height: 2.2)),
                            with: .color(color))
                        x += Self.gap
                    }
                    y += Self.gap
                }
            case .grid:
                var lines = Path()
                var x = Self.gap
                while x < size.width {
                    lines.move(to: CGPoint(x: x, y: 0)); lines.addLine(to: CGPoint(x: x, y: size.height)); x += Self.gap
                }
                var y = Self.gap
                while y < size.height {
                    lines.move(to: CGPoint(x: 0, y: y)); lines.addLine(to: CGPoint(x: size.width, y: y)); y += Self.gap
                }
                context.stroke(lines, with: .color(GymColor.border.opacity(0.35)), lineWidth: 0.6)
            case .none:
                break
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Grouped rows on one raised card with inset dividers (`ToolGroup` / `OptionGroup`).
public struct GroupCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { subviews in
                ForEach(Array(subviews.enumerated()), id: \.offset) { index, subview in
                    if index > 0 {
                        Rectangle().fill(GymColor.border).frame(height: 1).padding(.horizontal, 16)
                    }
                    subview
                }
            }
        }
        .background(GymColor.bgRaised, in: .rect(cornerRadius: 20))
    }
}

/// Title and hint at the top of a sheet (`SheetTitle`).
public struct SheetTitle: View {
    let title: String
    let subtitle: String?

    public init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: 6) {
            Text(title.titleCased)
                .font(.gym(17, .bold, relativeTo: .headline))
                .foregroundStyle(GymColor.text)
            if let subtitle {
                Text(subtitle)
                    .font(.gym(12, .medium, relativeTo: .footnote))
                    .foregroundStyle(GymColor.textSecondary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

/// Centered icon, title and hint for empty lists.
public struct EmptyStateView: View {
    let icon: Ph
    let title: String
    let message: String

    public init(icon: Ph, title: String, message: String) {
        self.icon = icon
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 12) {
            GymIcon(icon, size: 28)
                .foregroundStyle(GymColor.textSecondary)
                .frame(width: 64, height: 64)
                .background(GymColor.bgRaised2, in: .circle)
            Text(title)
                .font(.gym(17, .bold, relativeTo: .headline))
                .foregroundStyle(GymColor.text)
            Text(message)
                .font(.gym(13, .medium, relativeTo: .subheadline))
                .foregroundStyle(GymColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

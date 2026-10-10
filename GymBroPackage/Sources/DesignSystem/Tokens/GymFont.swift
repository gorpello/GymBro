import CoreText
import GymAssets
import SwiftUI

/// Nunito, the only typeface GymMane uses (`AppTheme.d/f/s`).
public enum GymFont {
    /// Registers the bundled Nunito files with the process. Safe to call more than once (each
    /// snapshot test suite does): only the first call registers.
    public static func register() {
        _ = registration
    }

    /// Lazy statics run exactly once, thread-safely; CoreText logs an error on a second
    /// registration of the same file.
    private static let registration: Void = {
        for url in GymAssets.fontURLs {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    static func postScriptName(_ weight: Font.Weight, italic: Bool) -> String {
        if italic {
            return weight == .semibold || weight == .bold ? "NunitoItalic-SemiBoldItalic" : "NunitoItalic-Italic"
        }
        switch weight {
        case .black, .heavy: return "Nunito-Black"
        case .bold: return "Nunito-Bold"
        case .semibold: return "Nunito-SemiBold"
        case .medium: return "Nunito-Medium"
        default: return "Nunito-Regular"
        }
    }
}

extension Font.Weight {
    /// Nunito ExtraBold (w800), used for titles and big numbers.
    public static let extraBold = Font.Weight.heavy
}

extension Font {
    /// Nunito at `size` points, scaling with Dynamic Type relative to `style`.
    public static func gym(
        _ size: CGFloat,
        _ weight: Font.Weight = .bold,
        italic: Bool = false,
        relativeTo style: Font.TextStyle = .body
    ) -> Font {
        let name = weight == .extraBold ? "Nunito-ExtraBold" : GymFont.postScriptName(weight, italic: italic)
        return .custom(name, size: size, relativeTo: style)
    }
}

extension UIFont {
    static func gym(_ size: CGFloat, _ name: String = "Nunito-ExtraBold") -> UIFont {
        UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: .heavy)
    }
}

/// Navigation bar titles in Nunito, like GymMane's `ScreenHeader`.
public enum GymAppearance {
    @MainActor public static func apply() {
        let bar = UINavigationBarAppearance()
        bar.configureWithTransparentBackground()
        bar.titleTextAttributes = [.font: UIFont.gym(17), .foregroundColor: UIColor(GymColor.text)]
        bar.largeTitleTextAttributes = [.font: UIFont.gym(28), .foregroundColor: UIColor(GymColor.text)]
        bar.subtitleTextAttributes = [
            .font: UIFont.gym(12.5, "Nunito-Medium"), .foregroundColor: UIColor(GymColor.textSecondary),
        ]
        bar.largeSubtitleTextAttributes = bar.subtitleTextAttributes
        UINavigationBar.appearance().standardAppearance = bar
        UINavigationBar.appearance().scrollEdgeAppearance = bar
        UINavigationBar.appearance().compactAppearance = bar
    }
}

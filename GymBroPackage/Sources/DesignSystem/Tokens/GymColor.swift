import SwiftUI
import UIKit

/// GymMane's colour tokens (`GymColors` in the Flutter app), resolved for light and dark.
public enum GymColor {
    public static let pageBg = dynamic(dark: 0xFF0A0908, light: 0xFFFFFEFD)
    public static let bg = dynamic(dark: 0xFF0A0A0A, light: 0xFFF7F4F0)
    public static let bgRaised = dynamic(dark: 0xFF1C1C1C, light: 0xFFFFFFFF)
    public static let bgRaised2 = dynamic(dark: 0xFF2B2B2B, light: 0xFFECE8E3)
    public static let border = dynamic(dark: 0xFF3E3E3E, light: 0xFFE0DBD5)
    public static let navBg = dynamic(dark: 0xD90A0A0A, light: 0xF2FFFEFD)
    public static let text = dynamic(dark: 0xFFFFFFFF, light: 0xFF1A1713)
    public static let textSecondary = dynamic(dark: 0xFF9A9A9A, light: 0xFF5F574F)
    public static let textTertiary = dynamic(dark: 0xFF666666, light: 0xFF8A8179)
    public static let ember = dynamic(dark: 0xFFFFFFFF, light: 0xFF1A1713)
    public static let emberDeep = dynamic(dark: 0xFFD0D0D0, light: 0xFF000000)
    public static let onEmber = dynamic(dark: 0xFF0A0A0A, light: 0xFFFFFFFF)
    public static let emberSoft = dynamic(dark: 0x1AFFFFFF, light: 0x121A1713)
    public static let emberShadow = dynamic(dark: 0x80000000, light: 0x1F1A1713)
    public static let accent = dynamic(dark: 0xFFD9A184, light: 0xFF9E4E27)
    public static let accentSoft = dynamic(dark: 0x29D9A184, light: 0x1F9E4E27)
    public static let brass = dynamic(dark: 0xFFB98F72, light: 0xFF8A6B41)
    public static let sage = dynamic(dark: 0xFF8FA377, light: 0xFF3D7A52)
    public static let sageSoft = dynamic(dark: 0x298FA377, light: 0x1F3D7A52)
    public static let mutedFill = dynamic(dark: 0xFF2A2A2A, light: 0xFFE9E4DE)
    public static let heatEmpty = dynamic(dark: 0xFF242424, light: 0xFFE7E2DC)
    public static let info = dynamic(dark: 0xFF7FA8C9, light: 0xFF3268A0)
    public static let warn = dynamic(dark: 0xFFE0B15A, light: 0xFF9A6A12)
    public static let danger = dynamic(dark: 0xFFE5674C, light: 0xFFC0392B)

    /// Resting muscle colour on the body map: `bgRaised2` nudged towards `textSecondary`.
    public static let idleMuscle = blend(bgRaised2, textSecondary, 0.32)
    /// Lighter body silhouette parts (hands, feet).
    public static let bodyLite = blend(bgRaised2, textTertiary, 0.14)

    /// Routine folder hues (`kFolderHues` in `routine_folder.dart`).
    public static let folderHues: [Color] = [
        Color(argb: 0xFFF3C7B1), Color(argb: 0xFFA78BDA), Color(argb: 0xFFA8C99E),
        Color(argb: 0xFF9CC2E8), Color(argb: 0xFFE8CF98), Color(argb: 0xFFE6A4B9),
    ]

    /// Mixes `a` towards `b`, resolving both for the current appearance.
    public static func mix(_ first: Color, _ second: Color, _ value: CGFloat) -> Color {
        blend(first, second, value)
    }

    static func dynamic(dark: UInt32, light: UInt32) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .light ? UIColor(argb: light) : UIColor(argb: dark) })
    }

    static func blend(_ first: Color, _ second: Color, _ value: CGFloat) -> Color {
        Color(
            uiColor: UIColor { traits in
                let ca = UIColor(first).resolvedColor(with: traits).rgba
                let cb = UIColor(second).resolvedColor(with: traits).rgba
                return UIColor(
                    red: ca.r + (cb.r - ca.r) * value,
                    green: ca.g + (cb.g - ca.g) * value,
                    blue: ca.b + (cb.b - ca.b) * value,
                    alpha: ca.a + (cb.a - ca.a) * value
                )
            })
    }
}

/// Heat ramps used by the activity grid and the muscle map (`body_map.dart`).
public enum HeatTone: String, CaseIterable, Sendable {
    case ember, green, blue, mono

    /// Four steps from cold to hot, already resolved for light and dark.
    public var ramp: [Color] {
        let dark: [UInt32]
        let light: [UInt32]
        switch self {
        case .ember:
            dark = [0xFF7A4028, 0xFFB4632C, 0xFFE38B3A, 0xFFFFC168]
            light = [0xFFD9B48A, 0xFFC07A3C, 0xFF9E4A24, 0xFF6E2A16]
        case .green:
            dark = [0xFF1B4B2C, 0xFF2C7A44, 0xFF3FA95C, 0xFF63D67F]
            light = [0xFFBBD9BE, 0xFF7FB88A, 0xFF488C58, 0xFF255E32]
        case .blue:
            dark = [0xFF1E3A5C, 0xFF2C5E96, 0xFF3D86C9, 0xFF6EB4F0]
            light = [0xFFBACFE8, 0xFF7EA5D2, 0xFF3F74AE, 0xFF1F4876]
        case .mono:
            dark = [0xFF3A3A3A, 0xFF5E5E5E, 0xFF8C8C8C, 0xFFD8D8D8]
            light = [0xFFCFC8BC, 0xFF9C958A, 0xFF6B655C, 0xFF3A352F]
        }
        return zip(dark, light).map { GymColor.dynamic(dark: $0, light: $1) }
    }

    /// Colour for a heat level from 0 (untouched) to 4 (full volume).
    public func color(level: Int) -> Color {
        level <= 0 ? GymColor.idleMuscle : ramp[min(level, 4) - 1]
    }
}

extension Color {
    public init(argb: UInt32) {
        self.init(uiColor: UIColor(argb: argb))
    }
}

extension UIColor {
    convenience init(argb: UInt32) {
        self.init(
            red: CGFloat((argb >> 16) & 0xFF) / 255,
            green: CGFloat((argb >> 8) & 0xFF) / 255,
            blue: CGFloat(argb & 0xFF) / 255,
            alpha: CGFloat((argb >> 24) & 0xFF) / 255
        )
    }

    fileprivate var rgba: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}

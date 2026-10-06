import SwiftUI
import Synchronization

/// Parses SVG path data (`d` attribute) into a SwiftUI `Path`.
///
/// Supports every command (M L H V C S Q T A Z, absolute and relative), compact number
/// syntax (`1.5.5`, `-1-2`, `1e-3`) and packed arc flags. Results are cached, since the
/// exercise art and the body map reuse the same strings constantly.
public enum SVGPath {
    public static func path(_ d: String) -> Path {
        if let cached = cache.withLock({ $0[d] }) { return cached }
        var parser = Parser(Array(d.utf8))
        let path = parser.parse()
        cache.withLock { $0[d] = path }
        return path
    }

    private static let cache = Mutex<[String: Path]>([:])
}

private struct Parser {
    let s: [UInt8]
    var i = 0
    var path = Path()
    var current = CGPoint.zero
    var start = CGPoint.zero
    var lastControl: CGPoint?
    var lastQuad: CGPoint?

    init(_ s: [UInt8]) { self.s = s }

    mutating func parse() -> Path {
        var command: UInt8 = 0
        while true {
            skipSeparators()
            guard i < s.count else { break }
            if isCommand(s[i]) {
                command = s[i]
                i += 1
            } else if command == 0 {
                break
            }
            run(command)
            // An implicit command after M/m is L/l.
            if command == UInt8(ascii: "M") { command = UInt8(ascii: "L") }
            if command == UInt8(ascii: "m") { command = UInt8(ascii: "l") }
        }
        return path
    }

    mutating func run(_ c: UInt8) {
        let relative = c >= UInt8(ascii: "a")
        let base = relative ? current : .zero
        switch c | 0x20 {
        case UInt8(ascii: "m"):
            guard let p = point(base) else { return skip() }
            path.move(to: p)
            current = p; start = p
            reset()
        case UInt8(ascii: "l"):
            guard let p = point(base) else { return skip() }
            path.addLine(to: p)
            current = p
            reset()
        case UInt8(ascii: "h"):
            guard let x = number() else { return skip() }
            current = CGPoint(x: (relative ? current.x : 0) + x, y: current.y)
            path.addLine(to: current)
            reset()
        case UInt8(ascii: "v"):
            guard let y = number() else { return skip() }
            current = CGPoint(x: current.x, y: (relative ? current.y : 0) + y)
            path.addLine(to: current)
            reset()
        case UInt8(ascii: "c"):
            guard let c1 = point(base), let c2 = point(base), let p = point(base) else { return skip() }
            path.addCurve(to: p, control1: c1, control2: c2)
            current = p; lastControl = c2; lastQuad = nil
        case UInt8(ascii: "s"):
            guard let c2 = point(base), let p = point(base) else { return skip() }
            let c1 = reflect(lastControl)
            path.addCurve(to: p, control1: c1, control2: c2)
            current = p; lastControl = c2; lastQuad = nil
        case UInt8(ascii: "q"):
            guard let c1 = point(base), let p = point(base) else { return skip() }
            path.addQuadCurve(to: p, control: c1)
            current = p; lastQuad = c1; lastControl = nil
        case UInt8(ascii: "t"):
            guard let p = point(base) else { return skip() }
            let c1 = reflect(lastQuad)
            path.addQuadCurve(to: p, control: c1)
            current = p; lastQuad = c1; lastControl = nil
        case UInt8(ascii: "a"):
            guard
                let rx = number(), let ry = number(), let rotation = number(),
                let large = flag(), let sweep = flag(), let p = point(base)
            else { return skip() }
            arc(to: p, rx: rx, ry: ry, rotation: rotation, large: large, sweep: sweep)
            current = p
            reset()
        case UInt8(ascii: "z"):
            path.closeSubpath()
            current = start
            reset()
        default:
            skip()
        }
    }

    mutating func reset() {
        lastControl = nil
        lastQuad = nil
    }

    /// Stops parsing on malformed input instead of looping forever.
    mutating func skip() { i = s.count }

    func reflect(_ control: CGPoint?) -> CGPoint {
        guard let control else { return current }
        return CGPoint(x: 2 * current.x - control.x, y: 2 * current.y - control.y)
    }

    // MARK: Arcs (SVG 1.1 implementation notes, F.6)

    mutating func arc(to end: CGPoint, rx: Double, ry: Double, rotation: Double, large: Bool, sweep: Bool) {
        var rx = abs(rx), ry = abs(ry)
        let p0 = current
        guard rx > 0, ry > 0, p0 != end else {
            path.addLine(to: end)
            return
        }
        let phi = rotation * .pi / 180
        let cosPhi = cos(phi), sinPhi = sin(phi)
        let dx = (p0.x - end.x) / 2, dy = (p0.y - end.y) / 2
        let x1 = cosPhi * dx + sinPhi * dy
        let y1 = -sinPhi * dx + cosPhi * dy
        let lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
        if lambda > 1 {
            rx *= lambda.squareRoot()
            ry *= lambda.squareRoot()
        }
        let num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let den = rx * rx * y1 * y1 + ry * ry * x1 * x1
        var coef = (max(0, num) / den).squareRoot()
        if large == sweep { coef = -coef }
        let cx1 = coef * rx * y1 / ry
        let cy1 = -coef * ry * x1 / rx
        let cx = cosPhi * cx1 - sinPhi * cy1 + (p0.x + end.x) / 2
        let cy = sinPhi * cx1 + cosPhi * cy1 + (p0.y + end.y) / 2

        func angle(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            let a = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
            return a
        }
        let theta1 = angle(1, 0, (x1 - cx1) / rx, (y1 - cy1) / ry)
        var delta = angle((x1 - cx1) / rx, (y1 - cy1) / ry, (-x1 - cx1) / rx, (-y1 - cy1) / ry)
        if !sweep && delta > 0 { delta -= 2 * .pi }
        if sweep && delta < 0 { delta += 2 * .pi }

        // Approximate with cubic segments of at most 90°.
        let segments = max(1, Int((abs(delta) / (.pi / 2)).rounded(.up)))
        let step = delta / Double(segments)
        let t = 4.0 / 3.0 * tan(step / 4)
        var a1 = theta1
        for _ in 0..<segments {
            let a2 = a1 + step
            let (c1, s1, c2, s2) = (cos(a1), sin(a1), cos(a2), sin(a2))
            func map(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: cx + rx * x * cosPhi - ry * y * sinPhi, y: cy + rx * x * sinPhi + ry * y * cosPhi)
            }
            path.addCurve(
                to: map(c2, s2),
                control1: map(c1 - t * s1, s1 + t * c1),
                control2: map(c2 + t * s2, s2 - t * c2)
            )
            a1 = a2
        }
    }

    // MARK: Lexing

    func isCommand(_ c: UInt8) -> Bool {
        switch c | 0x20 {
        case UInt8(ascii: "m"), UInt8(ascii: "l"), UInt8(ascii: "h"), UInt8(ascii: "v"), UInt8(ascii: "c"),
            UInt8(ascii: "s"), UInt8(ascii: "q"), UInt8(ascii: "t"), UInt8(ascii: "a"), UInt8(ascii: "z"):
            return c != UInt8(ascii: "e") && c != UInt8(ascii: "E")
        default:
            return false
        }
    }

    mutating func skipSeparators() {
        while i < s.count, s[i] == 0x20 || s[i] == 0x2C || s[i] == 0x0A || s[i] == 0x0D || s[i] == 0x09 {
            i += 1
        }
    }

    mutating func point(_ base: CGPoint) -> CGPoint? {
        guard let x = number(), let y = number() else { return nil }
        return CGPoint(x: base.x + x, y: base.y + y)
    }

    mutating func flag() -> Bool? {
        skipSeparators()
        guard i < s.count, s[i] == UInt8(ascii: "0") || s[i] == UInt8(ascii: "1") else { return nil }
        defer { i += 1 }
        return s[i] == UInt8(ascii: "1")
    }

    mutating func number() -> Double? {
        skipSeparators()
        let begin = i
        if i < s.count, s[i] == UInt8(ascii: "-") || s[i] == UInt8(ascii: "+") { i += 1 }
        var sawDot = false, sawDigit = false
        while i < s.count {
            let c = s[i]
            if c >= UInt8(ascii: "0") && c <= UInt8(ascii: "9") {
                sawDigit = true
            } else if c == UInt8(ascii: "."), !sawDot {
                sawDot = true
            } else {
                break
            }
            i += 1
        }
        if sawDigit, i < s.count, s[i] == UInt8(ascii: "e") || s[i] == UInt8(ascii: "E") {
            var j = i + 1
            if j < s.count, s[j] == UInt8(ascii: "-") || s[j] == UInt8(ascii: "+") { j += 1 }
            if j < s.count, s[j] >= UInt8(ascii: "0") && s[j] <= UInt8(ascii: "9") {
                i = j
                while i < s.count, s[i] >= UInt8(ascii: "0") && s[i] <= UInt8(ascii: "9") { i += 1 }
            }
        }
        guard sawDigit else {
            i = begin
            return nil
        }
        return Double(String(decoding: s[begin..<i], as: UTF8.self))
    }
}

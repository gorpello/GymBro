import GymAssets
import SwiftUI

/// Front and back muscle map (`body_map.dart`). Paint each muscle with `color(id)`, optionally
/// outline one, and get taps back as muscle ids.
public struct BodyMapView: View {
    let color: (String) -> Color
    let outline: String?
    let onTap: ((String) -> Void)?
    
    public init(color: @escaping (String) -> Color, outline: String? = nil, onTap: ((String) -> Void)? = nil) {
        self.color = color
        self.outline = outline
        self.onTap = onTap
    }
    
    /// Selection map used by Train step 1: picked muscles in `ember`.
    public init(selected: Set<String>, onTap: ((String) -> Void)? = nil) {
        self.init(color: { selected.contains($0) ? GymColor.ember : GymColor.idleMuscle }, onTap: onTap)
    }
    
    /// Heat map: `levels[id]` from 0 (untouched) to 4 (full volume).
    public init(levels: [String: Int], tone: HeatTone = .ember, outline: String? = nil, onTap: ((String) -> Void)? = nil) {
        self.init(color: { tone.color(level: levels[$0] ?? 0) }, outline: outline, onTap: onTap)
    }
    
    public var body: some View {
        let geometry = GymAssets.body
        Canvas { context, size in
            let scale = size.width / geometry.width
            context.scaleBy(x: scale, y: scale)
            for d in geometry.baseMain {
                context.fill(SVGPath.path(d), with: .color(GymColor.bgRaised2))
            }
            for d in geometry.baseLite {
                context.fill(SVGPath.path(d), with: .color(GymColor.bodyLite))
            }
            for (id, paths) in geometry.fills {
                let c = color(id)
                for d in paths {
                    context.fill(SVGPath.path(d), with: .color(c))
                }
            }
            if let outline {
                for d in geometry.fills[outline] ?? [] {
                    context.stroke(SVGPath.path(d), with: .color(GymColor.text), lineWidth: 2.5)
                }
            }
        }
        .aspectRatio(geometry.width / geometry.height, contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture { canvasTapped(at: $0) }
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
        .accessibilityElement(children: .ignore)
    }
    
    @State private var width: CGFloat = 1
    
    private func canvasTapped(at location: CGPoint) {
        guard let onTap, let id = Self.muscle(at: location, width: width) else { return }
        onTap(id)
    }
    
    /// Muscle under a point, probing the generous hit paths first.
    static func muscle(at point: CGPoint, width: CGFloat) -> String? {
        let geometry = GymAssets.body
        let p = CGPoint(x: point.x * geometry.width / width, y: point.y * geometry.width / width)
        for (id, fills) in geometry.fills {
            let probes = geometry.hits[id].flatMap { $0.isEmpty ? nil : $0 } ?? fills
            if probes.contains(where: { SVGPath.path($0).contains(p) }) { return id }
        }
        return nil
    }
}

#Preview {
    @Previewable @State var selected: Set<String> = ["chest", "triceps"]
    VStack(spacing: 24) {
        BodyMapView(selected: selected) { id in
            if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
        }
        BodyMapView(levels: ["chest": 4, "quads": 3, "back": 2, "biceps": 1])
    }
    .padding()
    .background(GymColor.bg)
}

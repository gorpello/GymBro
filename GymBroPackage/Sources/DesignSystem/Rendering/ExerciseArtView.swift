import GymAssets
import PhosphorSwift
import Synchronization
import SwiftUI

/// Exercise illustration drawn from the Workout Guide / Everkinetic path frames and tinted with
/// the current theme (`exercise_art.dart`). Live art cross-fades frame to frame every 1.56 s.
public struct ExerciseArtView: View {
    let art: String
    let color: Color
    let live: Bool
    
    public init(art: String, color: Color = GymColor.text, live: Bool = false) {
        self.art = art
        self.color = color
        self.live = live
    }
    
    public var body: some View {
        if let frames = ArtCache.frames(art) {
            if live && frames.paths.count > 1 {
                TimelineView(.animation) { context in
                    canvas(frames, time: context.date.timeIntervalSinceReferenceDate)
                }
            } else {
                canvas(frames, time: nil)
            }
        } else {
            GeometryReader { proxy in
                Ph.barbell.regular
                    .frame(width: proxy.size.height * 0.32, height: proxy.size.height * 0.32)
                    .foregroundStyle(GymColor.textTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func canvas(_ frames: ArtFrames, time: TimeInterval?) -> some View {
        Canvas { context, size in
            let b = frames.bounds
            guard b.width > 0, b.height > 0, size.width > 0 else { return }
            let pad = min(size.width, size.height) * 0.07
            let scale = min((size.width - pad * 2) / b.width, (size.height - pad * 2) / b.height)
            guard scale > 0 else { return }
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: -b.midX, y: -b.midY)
            
            let n = frames.paths.count
            guard let time, n > 1 else {
                context.fill(frames.paths[0], with: .color(color), style: FillStyle(eoFill: true))
                return
            }
            // Ping-pong through the frames, holding each one and blending over the last 28%.
            let steps = (n - 1) * 2
            let pos = (time.truncatingRemainder(dividingBy: Self.cycle) / Self.cycle) * Double(steps)
            let step = Int(pos.rounded(.down)) % steps
            let f = pos - pos.rounded(.down)
            let ascending = step < n - 1
            let from = ascending ? step : steps - step
            let to = ascending ? from + 1 : from - 1
            let blend = f < 0.72 ? 0 : easeInOut((f - 0.72) / 0.28)
            draw(&context, frames.paths[from], opacity: 1 - blend)
            if blend > 0 { draw(&context, frames.paths[to], opacity: blend) }
        }
    }
    
    private func draw(_ context: inout GraphicsContext, _ path: Path, opacity: Double) {
        guard opacity > 0.01 else { return }
        context.fill(path, with: .color(color.opacity(opacity)), style: FillStyle(eoFill: true))
    }
    
    private func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
    
    static let cycle: TimeInterval = 1.56
}

struct ArtFrames: Sendable {
    let paths: [Path]
    let bounds: CGRect
}

enum ArtCache {
    private static let cache = Mutex<[String: ArtFrames]>([:])
    
    static func frames(_ art: String) -> ArtFrames? {
        if let hit = cache.withLock({ $0[art] }) { return hit }
        let paths = GymAssets.artFrames(art).map(SVGPath.path)
        guard let first = paths.first else { return nil }
        let frames = ArtFrames(paths: paths, bounds: paths.dropFirst().reduce(first.boundingRect) { $0.union($1.boundingRect) })
        cache.withLock { $0[art] = frames }
        return frames
    }
}

#Preview {
    VStack {
        ExerciseArtView(art: "bench-press", live: true)
            .frame(height: 200)
        ExerciseArtView(art: "pull-up")
            .frame(width: 64, height: 64)
    }
    .padding()
    .background(GymColor.bg)
}

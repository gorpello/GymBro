import Foundation

/// Read-only access to the resources brought over from GymMane.
public enum GymAssets {
    /// Bundle holding art, medals, fonts, audio, images and JSON data.
    public static let bundle = Bundle.module
    
    /// Path frames (SVG `d` strings) of an exercise illustration, e.g. `"bench-press"`.
    /// Three frames for Workout Guide art, two for the Everkinetic drawings.
    public static func artFrames(_ name: String) -> [String] {
        guard
            let url = bundle.url(forResource: name, withExtension: "txt", subdirectory: "Art"),
            let text = try? String(contentsOf: url, encoding: .utf8)
                else { return [] }
        return text.split(whereSeparator: \.isNewline).map(String.init).filter { !$0.isEmpty }
    }
    
    /// Every exercise illustration name in the bundle.
    public static var artNames: [String] {
        (bundle.urls(forResourcesWithExtension: "txt", subdirectory: "Art") ?? [])
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }
    
    /// Medal artwork (WebP) for an award id such as `"firstWorkout"`.
    public static func medalURL(_ id: String, locked: Bool = false) -> URL? {
        bundle.url(forResource: locked ? "\(id)_off" : id, withExtension: "webp", subdirectory: "Badges")
    }
    
    /// The default "rest is over" alarm.
    public static var restOverSoundURL: URL? {
        bundle.url(forResource: "rest_over", withExtension: "wav")
    }
    
    /// Nunito font files, registered by `GymFont.register()`.
    public static var fontURLs: [URL] {
        bundle.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
    }
    
    /// The body map geometry (`body_svg.dart`).
    public static let body: BodyGeometry = decode("body")
    
    /// Raw JSON of the built-in catalogue: exercises, tools, filters (`exercise_catalog.dart`).
    public static var exerciseCatalogURL: URL? { bundle.url(forResource: "exercises", withExtension: "json") }
    
    /// Raw JSON of the ready-made plans (`program_templates.dart`).
    public static var programTemplatesURL: URL? { bundle.url(forResource: "programs", withExtension: "json") }
    
    static func decode<T: Decodable>(_ name: String) -> T {
        guard
            let url = bundle.url(forResource: name, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let value = try? JSONDecoder().decode(T.self, from: data)
                else { fatalError("Missing or invalid \(name).json in GymAssets") }
        return value
    }
}

/// Front and back silhouettes plus one set of paths per muscle, in a 535 × 462 view box.
public struct BodyGeometry: Decodable, Sendable {
    public let width: Double
    public let height: Double
    /// Main silhouette paths.
    public let baseMain: [String]
    /// Lighter silhouette paths (hands and feet).
    public let baseLite: [String]
    /// Paths painted for each muscle id (`chest`, `back`, …).
    public let fills: [String: [String]]
    /// Larger, easier-to-tap paths for each muscle id.
    public let hits: [String: [String]]
}

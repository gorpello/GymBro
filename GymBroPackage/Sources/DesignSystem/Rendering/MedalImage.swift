import GymAssets
import SwiftUI
import UIKit

/// One of the 20 medal artworks (`assets/badges`), lit or locked.
/// The 3D spinning version (`medal.frag`) is still to be ported to Metal.
public struct MedalImage: View {
    let id: String
    let locked: Bool

    public init(_ id: String, locked: Bool = false) {
        self.id = id
        self.locked = locked
    }

    public var body: some View {
        if let url = GymAssets.medalURL(id, locked: locked), let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Circle().fill(GymColor.bgRaised2)
        }
    }
}

#Preview {
    HStack {
        MedalImage("firstWorkout")
        MedalImage("streak30", locked: true)
    }
    .frame(height: 80)
    .padding()
    .background(GymColor.bg)
}

import GymAssets
import SwiftUI

/// Bundled photos and illustrations (`assets/img`).
public enum GymImage {
    public static var bannerDefault: Image { Image("BannerDefault", bundle: GymAssets.bundle) }
    public static var profileDefault: Image { Image("ProfileDefault", bundle: GymAssets.bundle) }
    public static var runner: Image { Image("Runner", bundle: GymAssets.bundle) }
}

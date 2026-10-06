// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "GymBroPackage",
  defaultLocalization: "en",
  platforms: [
    .iOS("27.0"),
  ],
  products: [
    // App
    .library(name: "AppFeature", targets: ["AppFeature"]),

    // Core
    .library(name: "Database", targets: ["Database"]),
    .library(name: "DesignSystem", targets: ["DesignSystem"]),
    .library(name: "GymAssets", targets: ["GymAssets"]),
    .library(name: "L10n", targets: ["L10n"]),
    .library(name: "Routing", targets: ["Routing"]),

    // Features
    .library(name: "AboutFeature", targets: ["AboutFeature"]),
    .library(name: "AIPlanFeature", targets: ["AIPlanFeature"]),
    .library(name: "AwardsFeature", targets: ["AwardsFeature"]),
    .library(name: "CompareFeature", targets: ["CompareFeature"]),
    .library(name: "ExercisesFeature", targets: ["ExercisesFeature"]),
    .library(name: "HomeFeature", targets: ["HomeFeature"]),
    .library(name: "MeasuresFeature", targets: ["MeasuresFeature"]),
    .library(name: "MomentsFeature", targets: ["MomentsFeature"]),
    .library(name: "NotesFeature", targets: ["NotesFeature"]),
    .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
    .library(name: "PlacesFeature", targets: ["PlacesFeature"]),
    .library(name: "ProfileFeature", targets: ["ProfileFeature"]),
    .library(name: "ProgressFeature", targets: ["ProgressFeature"]),
    .library(name: "RoutinesFeature", targets: ["RoutinesFeature"]),
    .library(name: "SessionFeature", targets: ["SessionFeature"]),
    .library(name: "SettingsFeature", targets: ["SettingsFeature"]),
    .library(name: "ShareFeature", targets: ["ShareFeature"]),
    .library(name: "StickerFeature", targets: ["StickerFeature"]),
    .library(name: "TimelineFeature", targets: ["TimelineFeature"]),
    .library(name: "ToolsFeature", targets: ["ToolsFeature"]),
    .library(name: "TrainFeature", targets: ["TrainFeature"]),
  ],
  dependencies: [
    .package(url: "https://github.com/phosphor-icons/swift", from: "2.0.0"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.20.0"),
  ],
  targets: [
    // MARK: - App

    .target(
      name: "AppFeature",
      dependencies: [
        "AboutFeature",
        "AIPlanFeature",
        "AwardsFeature",
        "CompareFeature",
        "Database",
        "DesignSystem",
        "ExercisesFeature",
        "HomeFeature",
        "L10n",
        "MeasuresFeature",
        "MomentsFeature",
        "NotesFeature",
        "OnboardingFeature",
        "PlacesFeature",
        "ProfileFeature",
        "ProgressFeature",
        "RoutinesFeature",
        "Routing",
        "SessionFeature",
        "SettingsFeature",
        "ShareFeature",
        "StickerFeature",
        "TimelineFeature",
        "ToolsFeature",
        "TrainFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),

    // MARK: - Core

    .target(
      name: "Database",
      dependencies: [
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .target(
      name: "DesignSystem",
      dependencies: [
        "GymAssets",
        .product(name: "PhosphorSwift", package: "swift"),
      ]
    ),
    .target(
      name: "GymAssets",
      resources: [
        .copy("Resources/Art"),
        .copy("Resources/Badges"),
        .process("Resources/Audio"),
        .process("Resources/Data"),
        .process("Resources/Fonts"),
        .process("Resources/Images.xcassets"),
      ]
    ),
    .target(
      name: "L10n",
      resources: [
        .process("Resources"),
      ]
    ),
    .target(
      name: "Routing"
    ),

    // MARK: - Features

    .target(
      name: "AboutFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "AIPlanFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "AwardsFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "CompareFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        "Routing",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "ExercisesFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        "Routing",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "HomeFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        "Routing",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "MeasuresFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "MomentsFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "NotesFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        "Routing",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "OnboardingFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "PlacesFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "ProfileFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        "Routing",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "ProgressFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        "Routing",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "RoutinesFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        "Routing",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "SessionFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        "Routing",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "SettingsFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        "Routing",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "ShareFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "StickerFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "TimelineFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        "Routing",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "ToolsFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        "Routing",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "TrainFeature",
      dependencies: [
        "DesignSystem",
        "L10n",
        "Routing",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),

    // MARK: - Tests

    .testTarget(
      name: "AppFeatureTests",
      dependencies: [
        "AppFeature",
        "TrainFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
  ]
)

// SwiftLint runs on every build of every target, so warnings show up inline in Xcode.
// Skipped on CI (Xcode Cloud and GitHub Actions set `CI`): build plugins need a manual
// "Trust & Enable" there, and GitHub Actions already runs SwiftLint as its own job.
if Context.environment["CI"] == nil {
  package.dependencies.append(
    .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.65.0")
  )
  for target in package.targets where target.type == .regular || target.type == .test {
    target.plugins = (target.plugins ?? []) + [
      .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
    ]
  }
}

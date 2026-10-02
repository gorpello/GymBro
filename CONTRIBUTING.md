# Contributing to GymBro

Thanks for helping. Bug reports, ideas, translations and pull requests are all welcome.
For anything big, open an issue first so we can agree on the approach before you spend time on it.

## Getting started

Requirements: Xcode 27 and the iOS 27 SDK.

```bash
git clone https://github.com/gorpello/GymBro.git
cd GymBro
open GymBroWorkspace.xcworkspace
```

Pick the **GymBro** scheme and an iOS 27 simulator, then build and run. To work on one screen,
pick its feature scheme (for example **ProfileFeature**) and use the SwiftUI canvas.

Signing: the project ships with the maintainer's team. To run on your own device, change the team
in the GymBro target's *Signing & Capabilities* tab. Please don't commit that change.

## How the code is organised

- The app target (`GymBro/`) is thin. Everything lives in `GymBroPackage/Sources`.
- **One feature, one module.** A feature owns its reducer, view and previews.
- **Features never import each other.** To move to another screen, send a `Route` (from the
  `Routing` module) through the feature's `delegate` action. `AppFeature` decides how to show it.
- Shared UI goes in `DesignSystem`, bundled media in `GymAssets`, persistence in `Database`.
- State and logic use [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture).
  Keep side effects in effects and dependencies, not in views.
- Every view has a `#Preview` with dummy state.

## Strings and translations

- Never hard-code user-facing text. Add a key to
  `GymBroPackage/Sources/L10n/Resources/Localizable.xcstrings` and a typed accessor in `L10n.swift`.
- English is the source language. Other languages can be left untranslated in your PR.
- The one exception is the legal credit "Based on GymMane by InlitX" on the About screen, which
  must stay as-is.

## Style

- 2-space indentation, 120-column lines. The repo's `.swift-format` and `.editorconfig` encode this.
- Format before you push:

  ```bash
  swift format --in-place --recursive GymBroPackage/Sources GymBroPackage/Tests
  ```

- Match the code around you: naming, comment density and file layout.

## Tests

Reducer tests live in `GymBroPackage/Tests` and use Swift Testing with TCA's `TestStore`.
Add or update a test when you change a reducer's behaviour. Run them from Xcode (⌘U on the
**AppFeature** scheme) or let CI run them on your pull request.

## Commits and pull requests

- Branch from `main`: `feat/session-accessory`, `fix/rest-timer-sound`, `docs/readme`.
- Use [Conventional Commits](https://www.conventionalcommits.org): `feat:`, `fix:`, `docs:`,
  `refactor:`, `test:`, `chore:`. The release notes are generated from them.
- Keep pull requests small and focused, and fill in the template.
- CI must pass: build, tests and format check.

## Licence

By contributing you agree that your work is released under the repository's licence,
[GPL-3.0](LICENSE) with the [additional term](ADDITIONAL_TERMS.md).

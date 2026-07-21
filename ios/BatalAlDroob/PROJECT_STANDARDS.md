# Batal Al-Droob Project Standards

## Scope

- Official project root: `ios/BatalAlDroob/`.
- App target: `BatalAlDroob`.
- Test targets: `BatalAlDroobTests`, `BatalAlDroobUITests`.
- Bundle identifier: `com.batalaldroob.parts`.
- Do not change signing, team, bundle identifier, capabilities, or entitlements without an explicit release task.

## Engineering Rules

- Treat `docs/APPLE_ENGINEERING_STANDARD.md` as the long-form Apple engineering reference for this project.
- When that reference conflicts with this file, the Batal Al-Droob project-specific constraints in this file take precedence unless the user explicitly changes them.
- Preserve the native SwiftUI implementation and do not reintroduce Flutter or Dart runtime dependencies.
- Keep user-facing strings localized in Arabic and English where they are part of shipped UI.
- Use bundled catalog data under `BatalAlDroob/Web/data/` as the offline source of truth unless a reviewed migration replaces it.
- Paid catalog access must use Apple In-App Purchase only, through the non-consumable product `batal.catalog.permanent.unlock`.
- Do not add third-party dependencies unless they are necessary, reviewed, and compatible with App Store privacy requirements.
- Avoid force unwraps, `try!`, global warning suppression, temporary debug UI, placeholder flows, or production `print` logging.

## Build And Validation

- Preferred stable release toolchain: Xcode 26.6 build `17F113` or a newer non-beta Xcode accepted for App Store submission.
- Current local fallback may differ; report the actual `xcodebuild -version` and SDK before claiming validation.
- Required validation for release work:
  - `xcodebuild -list -project BatalAlDroob.xcodeproj`
  - release simulator build
  - release device build with `CODE_SIGNING_ALLOWED=NO` when signing is unavailable
  - unit tests and UI smoke tests when Simulator services are available
  - `scripts/validate_release.py`
  - `git diff --check`

## App Store Rules

- Keep `CFBundleShortVersionString = $(MARKETING_VERSION)` and `CFBundleVersion = $(CURRENT_PROJECT_VERSION)`.
- Do not reuse uploaded build numbers.
- Xcode Cloud production workflows must not use beta Xcode for App Store submissions.
- The current App Store review blocker is metadata/completeness related unless a newer Apple message says otherwise.
- App screenshots and IAP review screenshots must show the current native app in actual use.

## Documentation

- Update `README.md`, `CHANGELOG.md`, and `docs/CURRENT_RELEASE_STATUS.md` when release state changes.
- Record manual requirements separately from verified local results.
- Never state that physical-device, StoreKit Sandbox, App Store Connect, or Apple Developer Portal checks are complete unless they were actually performed.

# Changelog

## 2.1 (149) - 2026-07-29

### Release

- Moved the Batal Al-Droob App Store candidate to release train `2.1` after
  App Store Connect rejected `2.0 (148)` with `ITMS-90186` and `ITMS-90062`
  because version `2.0` is closed for new build submissions.
- Raised the local project build floor to `149` so Xcode Cloud cannot reuse
  the failed build number `148`.
- Kept the bundle identifier, development team, signing style, entitlements,
  and capabilities unchanged.

## 2.0 (137) - 2026-07-26

### Release

- Moved the redesigned Batal Al-Droob candidate to major release train `2.0`.
- Kept the bundle identifier, development team, signing style, entitlements, and capabilities unchanged.
- Preserved build `137` as the current project build for the redesigned app experience.

## 1.2.2 (135) - 2026-07-25

### Release

- Moved the next App Store candidate to release train `1.2.2` after App Store
  Connect rejected `1.2.1 (132)` with `ITMS-90062` and `ITMS-90186`.
- Raised the local project build floor to `135` after build `134` was selected
  for review, so Xcode Cloud cannot reuse any submitted or failed build number.
- Split catalog search and fitment helpers into a focused source file while
  preserving part-number lookup behavior for searches such as `081210401F`.

## 1.2.1 (126+) - 2026-07-23

### Release

- Moved the next App Store candidate to release train `1.2.1` after App Store
  Connect closed `1.2.0` for new build uploads.
- Raised the local project build floor to `126` after Xcode Cloud uploads
  `124` and `125` failed with `ITMS-90062` and `ITMS-90186` on the closed
  `1.2.0` train.
- Added localized TestFlight "What to test" notes under `TestFlight/` so Xcode
  Cloud can attach tester notes during distribution preparation.

## 1.2.0 (120+) - 2026-07-21

### Release

- Moved the next App Store candidate to release train `1.2.0` after App Store
  Connect marked `1.1.0 (111)` as ready for distribution.
- Raised the local project build floor to `120` after Xcode Cloud build `119`
  failed during "Prepare Build for App Store Connect" under the closed `1.1.0`
  train.
- Added Batal-local Xcode Cloud script wrappers under `ios/BatalAlDroob/ci_scripts`
  so workflows rooted at the app folder run the release and archive guards.
- Added a Batal-local `ci_pre_xcodebuild.sh` guard that synchronizes
  `CURRENT_PROJECT_VERSION` to Xcode Cloud's `CI_BUILD_NUMBER` before archive,
  preventing App Store exports where the uploaded build number and archived
  `CFBundleVersion` diverge.
- Submitted iOS App Version `1.2.0` with Xcode Cloud build `122` to App Review
  after confirming the build/archive pipeline succeeded.

## 1.1.0 (111) - 2026-07-21

### Release

- Bumped the unified Xcode build number from 106 to 111 for the corrected Xcode Cloud/App Store candidate.
- Removed the obsolete bundle metadata cleanup run script that printed `xattr: Operation not permitted` during archive.
- Adopted the user-provided Apple engineering reference in `docs/APPLE_ENGINEERING_STANDARD.md`.
- Updated UI smoke coverage for the current Tools > Maintenance navigation path.

## 1.1.0 (106) - 2026-07-19

### Changed

- Split the native SwiftUI application into focused models, services, view models, views, and utilities.
- Improved Arabic/English localization, RTL behavior, Dynamic Type layout, keyboard handling, accessibility labels, and iPhone/iPad tab navigation coverage.
- Added structured logging and safer HTTPS-only external store links.
- Hardened location and compass permission handling, lifecycle cleanup, and localized errors.
- Made StoreKit current entitlements and verified transaction updates the source of truth for protected catalog access.
- Replaced the incompatible consumable catalog product with the non-consumable `batal.catalog.permanent.unlock` identifier and rejected an incorrect StoreKit product type at runtime.
- Added explicit loading, retry, offline/error, and permission-denied behavior to relevant flows.

### Quality

- Added an iOS UI test target and critical Arabic/English smoke tests.
- Expanded unit coverage for resources, StoreKit entitlement semantics, retry behavior, link validation, request formatting, part-number recognition, tire calculation, and localization.
- Added SwiftFormat, SwiftLint, release validation, Xcode Cloud toolchain guard, and post-archive metadata validation.
- Removed empty legacy scene/web-view files; the shipping app remains fully native SwiftUI.

### Privacy

- Localized the location permission explanation.
- Removed the unrelated external weather integration; tracking coordinates are no longer sent to Open-Meteo.
- Kept the location permission limited to on-screen tracking, map position, and compass tools.
- Declared the required reason for app-owned `UserDefaults` access.

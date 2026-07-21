# Changelog

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

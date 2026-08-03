# Changelog

## 2.6 (186) - 2026-08-03

### Release Train

- Moved the next code-carrying release to `2.6` after App Store Connect showed
  `2.5 (180)` as Ready for Distribution and rejected Xcode Cloud build `185`
  during Prepare Build for App Store Connect on that released train.
- Raised every app and test target to project build `186` and aligned the local
  validator plus the repository-level pre- and post-archive Xcode Cloud guards.
- Preserved the verified onboarding, account requirement, catalog search,
  StoreKit, AI safety, and 640-file catalog manifest without changing the Bundle
  ID, development team, signing, entitlements, or capabilities.

## 2.5 (173) - 2026-08-03

### Release Integration

- Merged the verified onboarding, catalog search, StoreKit, AI safety, and
  resource-audit work onto the latest `main` release train without changing the
  Bundle ID, team, signing, entitlements, or capabilities.
- Kept the newer App Store version and build introduced on `main` instead of
  regressing the candidate to `2.4 (172)`.
- Updated release validation and documentation to enforce `2.5 (173)`.
- Re-ran 45 unit tests, 3 UI tests, and 9 backend tests on the merged source;
  all passed, and an unsigned 104 MB Release device build succeeded.
- Confirmed the Git/Xcode Cloud candidate contains no PDF archive because those
  resources remain intentionally ignored pending Background Assets or secure
  on-demand delivery.

## 2.4 (172) - 2026-08-03

### Customer Access

- Made first-run registration or sign-in with a valid email mandatory and removed guest entry from the app surface and persisted access model.
- Moved the large welcome image to first-run onboarding and kept the signed-in dashboard compact.
- Constrained every hero layer to the available content width so Arabic RTL text and imagery no longer overflow the first-run screen.
- Added UI regression coverage proving an empty email cannot dismiss onboarding and no guest control is exposed.

### Catalog Resources

- Verified all 640 local PDF archive files and matched every unique PDF found in the selected iCloud catalog sources; no iCloud source hash was missing locally.
- Filled 28 missing SHA-256 values in the catalog manifest and added a reusable full archive integrity validator.
- Removed the second 10 GB catalog copy from the unit-test target; tests now inspect the app resource bundle directly.
- Documented the Xcode Cloud distribution gap for Git-ignored PDF files instead of claiming that a cloud archive contains resources that were not uploaded.

### Quality

- Expanded release validation to enforce catalog path/index parity, approved generation counts, valid resource hashes, mandatory account controls, and the continued absence of guest access.
- Re-ran the complete suite after the final onboarding layout fix: 45 unit tests and 3 UI tests passed.
- Built an unsigned full-resource Release with Xcode 26.6 / iPhoneOS SDK 26.5 and verified all 640 bundled PDFs by SHA-256.
- Recorded the 13 GB payload as a distribution blocker because it exceeds Apple's 4 GB uncompressed iOS app limit; the PDFs must move to Background Assets or authenticated on-demand storage before upload.

## 2.4 (171) - 2026-07-31

### Release

- Moved the App Store candidate to release train `2.4` because App Store
  Connect rejected creating version `2.3` with the message: "The version number
  has been previously used."
- Raised the project build to `171` and updated local/Xcode Cloud release guards
  so the next archive can be selected for App Review.

## 2.3 (170) - 2026-07-31

### Release

- Moved the next App Store candidate to release train `2.3` because App Store
  Connect version `2.2` is ready for distribution with build `166` and is no
  longer editable for attaching newer builds.
- Raised the project build to `170` and updated Xcode Cloud release guards so
  App Store Connect receives a fresh archive on the new release train.

### Customer Access

- Documented the configured owner email `sharyalhwaid@gmail.com` as the local
  owner access path for full catalog use without StoreKit on the owner's device,
  while keeping normal customer catalog access tied to StoreKit entitlements or
  App Store Connect offer codes.

## 2.2 (166) - 2026-07-31

### StoreKit

- Added Apple's official offer-code redemption flow to locked catalog pages so
  owner/promotional access can unlock `batal.catalog.permanent.unlock` through a
  verified StoreKit transaction instead of an unsafe local email bypass.
- Added regression coverage proving redemption presentation does not unlock
  locally unless StoreKit current entitlements include the full-catalog product.
- Kept the bundle identifier, development team, signing style, entitlements,
  and capabilities unchanged.

### Customer Access

- Updated first-run customer access so new users must register or sign in with
  a valid email before entering the app; entry without an account is no longer
  available.
- Added the same local account controls to Tools without adding backend auth,
  secrets, Sign in with Apple capability, or any paid-access bypass.
- Added regression tests proving local email storage does not unlock StoreKit
  protected catalog content.

## 2.2 (155) - 2026-07-31

### Release

- Moved the Batal Al-Droob App Store candidate to release train `2.2` after
  App Store Connect completed review for `2.1` and Xcode Cloud build `152`
  failed during "Prepare Build for App Store Connect" on the closed `2.1`
  train.
- Raised the local project build floor to `154` so Xcode Cloud cannot reuse
  builds `152` or `153`.
- Preserved the Y60 generation-card image replacement and kept the bundle
  identifier, development team, signing style, entitlements, and capabilities
  unchanged.
- Corrected the full-catalog purchase button to request the active
  `batal.catalog.permanent.unlock` non-consumable product while preserving
  `batal.catalog.full.unlock` as a legacy entitlement for restore continuity.
- Raised the corrected purchase build floor to `155` so App Store Connect can
  receive a fresh binary after build `154` was submitted.

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

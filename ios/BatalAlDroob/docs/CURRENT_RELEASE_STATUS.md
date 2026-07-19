# Batal Al-Droob Current Release Status

Updated: 2026-07-19
Decision: `READY_WITH_EXTERNAL_REQUIREMENTS`

## App And Apple Review State

| Item | Value |
|---|---|
| App | Batal Al-Droob / بطل الدروب |
| Apple ID | `6786117376` |
| Bundle ID | `com.batalaldroob.parts` |
| App Store version | `1.1.0` |
| Current project build | `106` |
| Latest successful Xcode Cloud build | `110` |
| Required next cloud build | `111` or higher |
| Latest cloud source commit | `5a80728` |
| Required toolchain | Xcode 26.6 (`17F113`), iPhoneOS SDK 26.5 |
| Latest detailed App Review issue | Guideline 2.1(b), App Completeness |
| Submission ID | `0fd0e8d0-ea44-4fe4-8fad-2ef8ea35eff6` |

Xcode Cloud build `110` successfully completed Build and Archive after removal
of the unrelated weather integration. It predates the permanent-IAP correction
described below and must not be treated as the final corrected candidate.

The latest Apple issue message says that the app references paid functionality,
but the associated In-App Purchase was not included in the review submission.
Apple requires the IAP, its App Review screenshot, and a new binary to be
submitted together. No newer Batal Al-Droob rejection message was found after
that issue; the newest Batal-specific mail confirms cloud build `110` succeeded.

## Permanent-IAP Correction

- The legacy product `batal.catalog.unlock` (Apple ID `6786440522`) was created
  as a consumable. It is incompatible with the app's permanent and restorable
  catalog entitlement and must not be attached to the corrected build.
- The replacement product is `batal.catalog.permanent.unlock` (Apple ID
  `6792436213`) and is configured as a non-consumable.
- The app now references only the replacement identifier and rejects StoreKit
  products whose runtime type is not non-consumable.
- The replacement product is still `Prepare for Submission`. Price,
  availability, localization, App Review screenshot, and review notes must be
  completed in App Store Connect before submission.

## Current Local Verification

| Gate | Result |
|---|---|
| SwiftFormat | PASS: 0/12 files require formatting |
| SwiftLint strict | PASS: 0 violations |
| Release validator | PASS |
| Release build | PASS with Xcode 26.6 (`17F113`) and iPhoneOS SDK 26.5 |
| Unit tests | PASS: 11/11 |
| UI tests | PASS: 2/2 |
| Total automated tests | PASS: 13/13 |
| Fresh unsigned archive | PASS |
| Actual archive metadata | PASS |

Fresh local archive:
`/tmp/BatalAlDroob-IAP-fix-1.1.0-106-20260719.xcarchive`

Verified app metadata inside that archive:

- `CFBundleIdentifier = com.batalaldroob.parts`
- `CFBundleShortVersionString = 1.1.0`
- `CFBundleVersion = 106`
- `DTXcodeBuild = 17F113`
- `DTSDKName = iphoneos26.5`
- `MinimumOSVersion = 17.0`
- no embedded app extensions or third-party frameworks

## Store Metadata State

- Replacement promoted-IAP artwork is saved at
  `docs/app-store-assets/iap-catalog-unlock-1024.png`.
- The IAP App Review screenshot must show the purchase surface in the current
  native app; promotional artwork does not replace that review screenshot.
- App Store screenshots must show the current native app in use on every
  required device class.

## Remaining Release Gates

1. Commit and push the permanent-IAP correction, then create Xcode Cloud build
   `111` or higher from that exact commit using stable Xcode 26.6.
2. Complete `batal.catalog.permanent.unlock` in App Store Connect and attach it
   to the same App Review submission as the corrected binary.
3. Verify Xcode Cloud Next Build Number and TestFlight Build Uploads before the
   workflow starts; do not reuse any uploaded build number.
4. Confirm App Store privacy labels and current screenshots against the final
   cloud binary.
5. Complete StoreKit Sandbox, permission, accessibility, Instruments, and
   physical-device checks on the exact release candidate.
6. Run an internal TestFlight pass before resubmitting to App Review.

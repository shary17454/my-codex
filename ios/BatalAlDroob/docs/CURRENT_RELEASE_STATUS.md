# Batal Al-Droob Current Release Status

Updated: 2026-07-29
Decision: `PREPARING_2.1_BUILD_149`

## App And Apple Review State

| Item | Value |
|---|---|
| App | Batal Al-Droob / بطل الدروب |
| Apple ID | `6786117376` |
| Bundle ID | `com.batalaldroob.parts` |
| App Store version | `2.1` for the next code-carrying candidate |
| Current project build | `149` local floor; Xcode Cloud synchronizes the archive to `CI_BUILD_NUMBER` |
| Latest App Store-ready version | `1.2.1` |
| Latest failed Xcode Cloud build | `148` from commit `6dd51e94c33bbe697bcd9faa61368f1aa6b48ba2` |
| Latest successful Xcode Cloud build | `148` compiled far enough to attempt App Store Connect preparation, but upload preparation was rejected |
| Latest pushed source commit | `6dd51e94c33bbe697bcd9faa61368f1aa6b48ba2` |
| Latest App Review submission | `2.0` train is now closed for new build uploads |
| Required toolchain | Xcode 26.6 (`17F113`), iPhoneOS SDK 26.5 |
| Latest detailed App Review issue | Guideline 2.1(b), App Completeness |
| Latest historical rejected submission ID | `0fd0e8d0-ea44-4fe4-8fad-2ef8ea35eff6` |
| Current submitted submission ID | `00e306d9-8983-4df8-b284-6cbc1fff2c04` |

App Store Connect now reports `ITMS-90062` and `ITMS-90186` for new uploads on
`2.0`: the `2.0` train is closed for new build submissions and the uploaded
binary reused `CFBundleShortVersionString = 2.0`, which is not higher than the
previously approved version `2.0`. Build `148` failed in App Store Connect
preparation for this reason. The next valid binary must use
`MARKETING_VERSION = 2.1` and build `149` or higher.

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
| SwiftFormat | PASS: 0/14 files require formatting |
| SwiftLint strict | PASS: 0 violations |
| Release validator | PASS |
| Release simulator build | PASS locally with Xcode 26.4.1 (`17E202`) and iPhoneOS Simulator SDK 26.4 |
| Release device build without signing | PASS locally with Xcode 26.4.1 (`17E202`) and iPhoneOS SDK 26.4 |
| Static analysis | PASS locally with Xcode 26.4.1 (`17E202`) |
| Unit tests | PASS: 19/19 |
| UI tests | PASS: 2/2 |
| Total automated tests | PASS: 21/21 |
| Fresh unsigned archive | PASS |
| Actual archive metadata | PASS |

Fresh local unsigned archive for the previous `2.0 (137)` candidate:
`/tmp/BatalAlDroob-2.0-137.xcarchive`

Verified app metadata inside that archive:

- `CFBundleIdentifier = com.batalaldroob.parts`
- `CFBundleShortVersionString = 2.0`
- `CFBundleVersion = 137`
- `DTXcodeBuild = 17E202`
- `DTSDKName = iphoneos26.4`
- `MinimumOSVersion = 17.0`
- no embedded app extensions or third-party frameworks

This local archive is an unsigned engineering validation artifact only. App
Store submission must still use a fresh signed Xcode Cloud archive on Xcode
26.6 (`17F113`) or a newer Apple-approved non-beta Xcode with iPhoneOS SDK
26.5 or newer.

## Store Metadata State

- The detailed manual review gate is documented in
  `docs/APP_STORE_REVIEW_FIX_PLAN.md`.
- Replacement promoted-IAP artwork is saved at
  `docs/app-store-assets/iap-catalog-unlock-1024.png`.
- The IAP App Review screenshot must show the purchase surface in the current
  native app; promotional artwork does not replace that review screenshot.
- App Store screenshots must show the current native app in use on every
  required device class.

## Remaining Release Gates

1. Monitor App Review messages for submission
   `00e306d9-8983-4df8-b284-6cbc1fff2c04`.
2. If Apple rejects or requests metadata changes, fix the exact item and do not
   resubmit the same build without addressing the root cause.
3. Keep the obsolete draft consumable `batal.catalog.unlock` out of future
   submissions; the shipping app uses the approved non-consumable
   `batal.catalog.permanent.unlock`.
4. Before the next code-bearing release, verify Xcode Cloud Next Build Number is
   `149` or higher.

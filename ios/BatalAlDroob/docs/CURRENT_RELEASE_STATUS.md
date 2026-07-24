# Batal Al-Droob Current Release Status

Updated: 2026-07-25
Decision: `PREPARING_1.2.2`

## App And Apple Review State

| Item | Value |
|---|---|
| App | Batal Al-Droob / بطل الدروب |
| Apple ID | `6786117376` |
| Bundle ID | `com.batalaldroob.parts` |
| App Store version | `1.2.2` for the next code-carrying candidate |
| Current project build | `133` local floor; Xcode Cloud synchronizes the archive to `CI_BUILD_NUMBER` |
| Latest App Store-ready version | `1.2.1` |
| Latest failed Xcode Cloud build | `132` from commit `998fc21` |
| Latest successful Xcode Cloud build | `132` compiled and archived, but the upload was rejected by App Store Connect |
| Latest pushed source commit | pending next commit |
| Latest App Review submission | `1.2.1`/`1.2.0` trains are now closed for new uploads |
| Required toolchain | Xcode 26.6 (`17F113`), iPhoneOS SDK 26.5 |
| Latest detailed App Review issue | Guideline 2.1(b), App Completeness |
| Latest historical rejected submission ID | `0fd0e8d0-ea44-4fe4-8fad-2ef8ea35eff6` |
| Current submitted submission ID | `00e306d9-8983-4df8-b284-6cbc1fff2c04` |

App Store Connect now reports `ITMS-90062` and `ITMS-90186` for new uploads on
`1.2.1`: the `1.2.1` train is closed because it matches a previously approved
or closed version. Builds `131` and `132` failed in Build Uploads for this
reason. The next valid binary must use `MARKETING_VERSION = 1.2.2` and a build
number above all prior uploads, starting at `133`.

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

Fresh local archive from the previous `1.1.0 (111)` candidate:
`/tmp/BatalAudit-1.1.0-111.xcarchive`

Verified app metadata inside that archive:

- `CFBundleIdentifier = com.batalaldroob.parts`
- `CFBundleShortVersionString = 1.1.0`
- `CFBundleVersion = 111`
- `DTXcodeBuild = 17F113`
- `DTSDKName = iphoneos26.5`
- `MinimumOSVersion = 17.0`
- no embedded app extensions or third-party frameworks

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
   higher than `122`.

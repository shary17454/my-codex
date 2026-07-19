# Batal Al-Droob Current Release Status

Updated: 2026-07-19
Decision: `READY_WITH_EXTERNAL_REQUIREMENTS`

## Verified Prior Cloud Candidate

| Item | Value |
|---|---|
| App | Batal Al-Droob / بطل الدروب |
| Apple ID | `6786117376` |
| Bundle ID | `com.batalaldroob.parts` |
| App Store version | `1.1.0` |
| Prior source commit | `d6c265c` |
| Prior Xcode Cloud build | `109` |
| Next Cloud build | `110` |
| Xcode | `26.6 (17F113)` |
| iPhoneOS SDK | `26.5` |
| Cloud Build/Archive | PASS |
| TestFlight processing | PASS, Ready to Submit |

Build `109` predates the removal of the external weather feature and is therefore
not the final candidate.

## Current Source Change

- Removed Open-Meteo networking and all weather UI/state/tests.
- Renamed the location model to `LocationTrackingViewModel`.
- Retained user-initiated map, location tracking, and compass behavior.
- Updated Arabic/English permission text.
- Removed precise-location collection from `PrivacyInfo.xcprivacy`.
- Updated documentation and the release checklist to match the final behavior.

## Current Local Verification

| Gate | Result |
|---|---|
| Weather symbols/endpoints in Swift, plist, strings, or project files | PASS: no matches |
| SwiftFormat | PASS: 0/12 files require formatting |
| SwiftLint strict | PASS: 0 violations |
| Release validator | PASS |
| Release build | PASS with Xcode 26.6 (`17F113`) and iPhoneOS SDK 26.5 |
| Unit tests | PASS: 10/10 |
| UI tests | PASS: 2/2 |
| Compiled privacy manifest | PASS: no collected data types and no tracking |

The verified unsigned Release product is at
`/tmp/BatalNoWeatherRelease/Build/Products/Release-iphoneos/BatalAlDroob.app`.

## Store Metadata State

- StoreKit product `batal.catalog.unlock` is currently `Prepare for Submission`.
- Replacement promoted-IAP artwork is saved at
  `docs/app-store-assets/iap-catalog-unlock-1024.png`.
- Current iPhone/iPad screenshots must be replaced with captures of the native app in use.

## Remaining Release Gates

1. Push the weather-removal commit and produce Xcode Cloud build `110` or higher.
2. Upload IAP artwork, complete the product, and attach it to the app submission.
3. Upload current 6.5-inch iPhone and 13-inch iPad screenshots.
4. Confirm App Store privacy labels against the final cloud binary.
5. Complete physical-device StoreKit, permission, accessibility, and Instruments checks.
6. Complete an internal TestFlight pass before App Review.

# Batal Al-Droob iOS

Native SwiftUI iOS/iPadOS app for Nissan Patrol catalog lookup, fitment evidence, saved part requests, maintenance notes, supplier discovery, and a protected catalog unlock through Apple In-App Purchase.

## Project

- Xcode project: `BatalAlDroob.xcodeproj`
- Scheme: `BatalAlDroob`
- Bundle ID: `com.batalaldroob.parts`
- Minimum iOS: 17.0
- App Store version: `1.2.2`
- Project build: `135`

The app uses bundled JSON catalog data under `BatalAlDroob/Web/data/`. The old web app files remain in the repository for source data history, but the app UI is native SwiftUI.

## Requirements

- Xcode 26.6 stable, build `17F113`
- Swift 6
- iOS deployment target 17.0
- No CocoaPods, Swift Package Manager, or third-party dependency install step

For App Store archives, keep signing managed by Xcode/Xcode Cloud and use Xcode 26.6 build 17F113 or a newer non-beta Xcode accepted by Apple.

## Build

Run the following commands from `ios/BatalAlDroob/`.

Debug simulator build:

```sh
/Applications/Xcode-26.6-duplicate.app/Contents/Developer/usr/bin/xcodebuild \
  -project BatalAlDroob.xcodeproj \
  -scheme BatalAlDroob \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/BatalAlDroobDerivedData \
  build
```

Release simulator validation:

```sh
/Applications/Xcode-26.6-duplicate.app/Contents/Developer/usr/bin/xcodebuild \
  -project BatalAlDroob.xcodeproj \
  -scheme BatalAlDroob \
  -configuration Release \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/BatalAlDroobReleaseDerivedData \
  build
```

Release device validation without local signing:

```sh
/Applications/Xcode-26.6-duplicate.app/Contents/Developer/usr/bin/xcodebuild \
  -project BatalAlDroob.xcodeproj \
  -scheme BatalAlDroob \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/BatalAlDroobReleaseDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Run regression tests:

```sh
/Applications/Xcode-26.6-duplicate.app/Contents/Developer/usr/bin/xcodebuild \
  test \
  -project BatalAlDroob.xcodeproj \
  -scheme BatalAlDroob \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /tmp/BatalAlDroobTestDerivedData
```

## Xcode Cloud

The repository-level `ci_scripts/ci_post_clone.sh` guards production builds for this app:

- rejects beta Xcode builds,
- verifies iPhoneOS SDK 26.x or newer,
- verifies `MARKETING_VERSION = 1.2.2`,
- verifies `CURRENT_PROJECT_VERSION >= 135`,
- rejects beta Xcode and SDKs below iPhoneOS 26.5.

After an archive, `ci_scripts/ci_post_xcodebuild.sh` reads the actual app metadata from the new `xcarchive` and rejects mismatched bundle identifiers, versions, build numbers, Xcode builds, SDKs, platforms, deployment targets, or embedded app extensions.

In App Store Connect, set the Batal Al-Droob workflow environment to a production Xcode version. Do not use "Latest Beta" for App Store submission builds.

App Store Connect has closed the `1.2.1` train for new build uploads. Xcode
Cloud uploads `131` and `132` failed with `ITMS-90062` and `ITMS-90186` because
they reused `CFBundleShortVersionString = 1.2.1` after that version was already
approved or closed. For the next candidate, create/open App Store version `1.2.2`
and keep Xcode Cloud > Workflow > Next Build Number at `135` or higher. Do not
reuse any uploaded build number.

## In-App Purchase

Only one StoreKit product is referenced by the app:

- `batal.catalog.permanent.unlock` (non-consumable permanent catalog unlock)

The legacy `batal.catalog.unlock` product was configured as a consumable and is
not compatible with a permanent, restorable entitlement. Do not attach it to a
corrected release. For the first review of the replacement product, add the
In-App Purchase and the matching new app version to the same App Review
submission. Apple requires an App Review screenshot for the product and a new
binary when the product was omitted from an earlier submission.

Part requests are prepared and saved inside the app without a separate purchase product.

If you update the bundled catalog data, keep the files inside `BatalAlDroob/Web/data/` and run the regression tests before archiving.

## Supplier Partnerships

Supplier and outreach research for Nissan Patrol parts providers is tracked in `Partnerships/`. Do not send outreach or mark a supplier as approved without human review and written permission.

## Engineering Reference

- Mandatory Apple engineering constitution: [`docs/APPLE_ENGINEERING_STANDARD.md`](docs/APPLE_ENGINEERING_STANDARD.md)
- Permanent quality and release standard: [`docs/PRODUCTION_READINESS_STANDARD.md`](docs/PRODUCTION_READINESS_STANDARD.md)
- Architecture: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- Flutter/native status: [`docs/FLUTTER_TO_NATIVE_MIGRATION.md`](docs/FLUTTER_TO_NATIVE_MIGRATION.md)
- Release checklist: [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md)
- Latest executed verification: [`docs/FINAL_EXECUTION_REPORT.md`](docs/FINAL_EXECUTION_REPORT.md)
- Arabic status summary: [`docs/FINAL_STATUS_AR.md`](docs/FINAL_STATUS_AR.md)

The latest verification status is `READY_WITH_EXTERNAL_REQUIREMENTS`. The
remaining requirements are deliberately kept visible in the execution report:
a fresh signed Xcode Cloud build `135` or higher on release train `1.2.2`,
completion and attachment of the permanent IAP in App Store Connect, current
screenshots, privacy-label confirmation, and manual device checks.

`docs/APPLE_ENGINEERING_STANDARD.md` is enforced as a release input by
`scripts/validate_release.py`; do not remove or bypass it for app, QA,
accessibility, security, performance, or App Store work.

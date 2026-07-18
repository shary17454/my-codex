# Batal Al-Droob iOS

Native SwiftUI iOS/iPadOS app for Nissan Patrol catalog lookup, fitment evidence, saved part requests, maintenance notes, compass/trip tools, and a protected catalog unlock through Apple In-App Purchase.

## Project

- Xcode project: `BatalAlDroob.xcodeproj`
- Scheme: `BatalAlDroob`
- Bundle ID: `com.batalaldroob.parts`
- Minimum iOS: 17.0
- App Store version: `1.1.0`
- Next build: `105`

The app uses bundled JSON catalog data under `BatalAlDroob/Web/data/`. The old web app files remain in the repository for source data history, but the app UI is native SwiftUI.

## Requirements

- Xcode 26.6 stable, build `17F113`
- Swift 6
- iOS deployment target 17.0
- No CocoaPods, Swift Package Manager, or third-party dependency install step

For App Store archives, keep signing managed by Xcode/Xcode Cloud and use Xcode 26.6 build 17F113 or a newer non-beta Xcode accepted by Apple.

## Build

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
  -project ios/BatalAlDroob/BatalAlDroob.xcodeproj \
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
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath /tmp/BatalAlDroobTestDerivedData
```

## Xcode Cloud

The repository-level `ci_scripts/ci_post_clone.sh` guards production builds for this app:

- rejects beta Xcode builds,
- verifies iPhoneOS SDK 26.x or newer,
- verifies `MARKETING_VERSION = 1.1.0`,
- verifies `CURRENT_PROJECT_VERSION >= 105`,
- rejects beta Xcode and SDKs below iPhoneOS 26.5.

After an archive, `ci_scripts/ci_post_xcodebuild.sh` reads the actual app metadata from the new `xcarchive` and rejects mismatched bundle identifiers, versions, build numbers, Xcode builds, SDKs, platforms, deployment targets, or embedded app extensions.

In App Store Connect, set the Batal Al-Droob workflow environment to a production Xcode version. Do not use "Latest Beta" for App Store submission builds.

Before starting a new App Store build, set Xcode Cloud > Workflow > Next Build Number to `105` or higher. Build `104` has already been used, so do not reuse it.

## In-App Purchase

Only one StoreKit product is referenced by the app:

- `batal.catalog.unlock`

Part requests are prepared and saved inside the app without a separate purchase product.

If you update the bundled catalog data, keep the files inside `BatalAlDroob/Web/data/` and run the regression tests before archiving.

## Supplier Partnerships

Supplier and outreach research for Nissan Patrol parts providers is tracked in `Partnerships/`. Do not send outreach or mark a supplier as approved without human review and written permission.

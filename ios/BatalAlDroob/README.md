# Batal Al-Droob iOS

Native SwiftUI iOS app for Nissan Patrol catalog lookup, fitment evidence, saved part requests, maintenance notes, compass/trip tools, and a protected catalog unlock through Apple In-App Purchase.

## Project

- Xcode project: `BatalAlDroob.xcodeproj`
- Scheme: `BatalAlDroob`
- Bundle ID: `com.batalaldroob.parts`
- Minimum iOS: 17.0
- App Store version: `1.1.0`
- Build: `92`

## Build

Use the production Xcode selected for App Store submission:

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

For App Store archives, keep signing managed by Xcode/Xcode Cloud and use Xcode 26.6 build 17F113 or a newer non-beta Xcode accepted by Apple.

## Xcode Cloud

The repository-level `ci_scripts/ci_post_clone.sh` guards production builds for this app:

- rejects beta Xcode builds,
- verifies iPhoneOS SDK 26.x or newer,
- verifies `MARKETING_VERSION = 1.1.0`,
- verifies `CURRENT_PROJECT_VERSION = 92`.

In App Store Connect, set the Batal Al-Droob workflow environment to a production Xcode version. Do not use "Latest Beta" for App Store submission builds.

## In-App Purchase

Only one StoreKit product is referenced by the app:

- `batal.catalog.unlock`

Part requests are prepared and saved inside the app without a separate purchase product.

## Bundled Data

The app uses bundled JSON catalog data under `BatalAlDroob/Web/data/`. The old web app files remain in the repository for source data history, but the app UI is native SwiftUI.

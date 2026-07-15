# Repository Notes

## Structure

- `ios/BatalAlDroob/` contains the native iOS app for Batal Al-Droob.
- `ios/BatalAlDroob/BatalAlDroob.xcodeproj` is the Xcode project.
- `ios/BatalAlDroob/BatalAlDroob/AppDelegate.swift` currently contains the SwiftUI app entry point, models, services, view models, and views.
- `ios/BatalAlDroob/BatalAlDroob/Web/` contains the bundled catalog web assets and JSON data.
- Large catalog files outside the app are managed through Git LFS.

## Build

Use the installed stable Xcode used by Xcode Cloud:

```sh
/Applications/Xcode-26.6-duplicate.app/Contents/Developer/usr/bin/xcodebuild \
  -project ios/BatalAlDroob/BatalAlDroob.xcodeproj \
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
  -project ios/BatalAlDroob/BatalAlDroob.xcodeproj \
  -scheme BatalAlDroob \
  -configuration Release \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/BatalAlDroobReleaseDerivedData \
  build
```

## Constraints

- Do not change bundle identifier, signing team, certificates, provisioning profiles, or entitlements unless explicitly requested.
- Do not remove bundled catalog data without confirming feature impact.
- Do not add third-party dependencies unless there is a documented need.
- Do not commit generated build outputs, archives, DerivedData, or `.xcresult` bundles.
- Preserve existing UserDefaults keys because they store vehicle profile, wishlist, paid unlocks, maintenance logs, and part requests.

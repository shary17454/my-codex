# Repository Notes

## Structure

- `DesertTrail/` contains the native iOS app for تطبيق الدروب only.
- `DesertTrail/DesertTrail.xcodeproj` is the Xcode project.
- `DesertTrail/DesertTrail/` contains the SwiftUI app, models, services, and views.
- `DesertTrail/DesertTrail/Resources/` contains bundled GPX and image resources.
- `ci_scripts/` contains Xcode Cloud scripts for this app.

## Build

Use the installed stable Xcode used by Xcode Cloud:

```sh
/Applications/Xcode-26.6-duplicate.app/Contents/Developer/usr/bin/xcodebuild \
  -project DesertTrail/DesertTrail.xcodeproj \
  -scheme DesertTrail \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/DesertTrailDerivedData \
  build
```

Release simulator validation:

```sh
/Applications/Xcode-26.6-duplicate.app/Contents/Developer/usr/bin/xcodebuild \
  -project DesertTrail/DesertTrail.xcodeproj \
  -scheme DesertTrail \
  -configuration Release \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/DesertTrailReleaseDerivedData \
  build
```

## Constraints

- Work on تطبيق الدروب only. Do not modify any other app or project path.
- Do not change bundle identifier, signing team, certificates, provisioning profiles, or entitlements unless explicitly requested.
- Do not remove bundled route/map data without confirming feature impact.
- Do not add third-party dependencies unless there is a documented need.
- Do not commit generated build outputs, archives, DerivedData, or `.xcresult` bundles.
- Preserve existing UserDefaults keys because they store trips, hidden places, language, and sharing preferences.

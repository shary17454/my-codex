# Repository Notes

## Current Scope

- Work on `ios/BatalAlDroob/` only for تطبيق بطل الدروب.
- Treat `ios/BatalAlDroob/docs/PRODUCTION_READINESS_STANDARD.md` as the permanent engineering and release-readiness reference for every future change to Batal Al-Droob.
- Preserve verified behavior and prefer native Swift/SwiftUI and Apple platform APIs. Do not claim production readiness without executed build, test, archive, and applicable device/manual evidence.
- App Store Connect app ID: `6786117376`.
- Bundle ID: `com.batalaldroob.parts`.
- Xcode project: `ios/BatalAlDroob/BatalAlDroob.xcodeproj`.
- Scheme: `BatalAlDroob`.
- Shared Xcode Cloud script: `ci_scripts/ci_post_clone.sh`.

## Build

Use the production Xcode selected in Xcode Cloud. For App Store builds, the workflow must use Xcode `26.6` build `17F113` or a newer non-beta Xcode accepted by Apple.

Local validation can use:

```sh
xcodebuild -project ios/BatalAlDroob/BatalAlDroob.xcodeproj \
  -scheme BatalAlDroob \
  -configuration Release \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/BatalAlDroobReleaseDerivedData \
  build
```

Release settings check:

```sh
python3 ios/BatalAlDroob/scripts/validate_release.py
```

## Constraints

- Do not modify other apps in this repository unless the user explicitly asks.
- Do not change Bundle ID, Development Team, signing, certificates, provisioning profiles, entitlements, or capabilities.
- Do not upload to App Store Connect or submit for review unless explicitly requested in the current turn.
- Do not commit generated build outputs, archives, DerivedData, or `.xcresult` bundles.
- Keep `Info.plist` deriving `CFBundleShortVersionString` and `CFBundleVersion` from Xcode build settings.
- Record any verification that requires a physical device, Apple Developer Portal, App Store Connect, credentials, or external production service as an explicit manual/external requirement; never report it as completed without evidence.

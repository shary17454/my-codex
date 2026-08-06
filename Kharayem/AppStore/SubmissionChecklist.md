# Submission Checklist

## Required Apple Account Items

- Apple Developer Team ID.
- Bundle ID matching the App Store Connect app record for `com.codex.Kharayem`.
- iCloud container enabled for that Bundle ID.
- CloudKit schema deployed to production.
- Apple Distribution certificate and App Store provisioning profile.

## Current Prepared Release

- Display name: `خرايم`
- Marketing version: `2.3`
- Build number: `157`
- Bundle ID: `com.codex.Kharayem`
- Release action in Codex task: `PREPARE_ONLY` - do not submit automatically.
- Xcode Cloud environment: use production `Xcode 26.6 (17F113)` or a newer production Xcode explicitly accepted by Apple. Do not use `Latest Beta`.
- App Store Connect must use a new iOS version record matching `2.3`; do not attach this build to the published or closed `2.2` pre-release train.

## Local Commands

Unsigned validation archive:

```sh
xcodebuild -project Kharayem.xcodeproj -scheme Kharayem -configuration Release -sdk iphoneos -destination generic/platform=iOS -archivePath ../build/Kharayem.xcarchive -derivedDataPath ../DerivedData CODE_SIGNING_ALLOWED=NO archive
```

Signed archive after setting `DEVELOPMENT_TEAM`:

```sh
xcodebuild -project Kharayem.xcodeproj -scheme Kharayem -configuration Release -sdk iphoneos -destination generic/platform=iOS -archivePath ../build/Kharayem-Signed.xcarchive -derivedDataPath ../DerivedData -allowProvisioningUpdates archive
```

Upload after a signed archive exists:

```sh
xcodebuild -exportArchive -archivePath ../build/Kharayem-Signed.xcarchive -exportOptionsPlist AppStore/ExportOptions-AppStore.plist -allowProvisioningUpdates
```

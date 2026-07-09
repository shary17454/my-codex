# Submission Checklist

## Required Apple Account Items

- Apple Developer Team ID.
- Bundle ID matching the App Store Connect app record for app `6786065206`.
- iCloud container enabled for that Bundle ID.
- CloudKit schema deployed to production.
- Apple Distribution certificate and App Store provisioning profile.

## Local Commands

Unsigned validation archive:

```sh
xcodebuild -project DesertTrail.xcodeproj -scheme DesertTrail -configuration Release -sdk iphoneos -destination generic/platform=iOS -archivePath ../build/DesertTrail.xcarchive -derivedDataPath ../DerivedData CODE_SIGNING_ALLOWED=NO archive
```

Signed archive after setting `DEVELOPMENT_TEAM`:

```sh
xcodebuild -project DesertTrail.xcodeproj -scheme DesertTrail -configuration Release -sdk iphoneos -destination generic/platform=iOS -archivePath ../build/DesertTrail-Signed.xcarchive -derivedDataPath ../DerivedData -allowProvisioningUpdates archive
```

Upload after a signed archive exists:

```sh
xcodebuild -exportArchive -archivePath ../build/DesertTrail-Signed.xcarchive -exportOptionsPlist AppStore/ExportOptions-AppStore.plist -allowProvisioningUpdates
```

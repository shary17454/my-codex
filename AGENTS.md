# Repository Notes

## Current Scope

- Work on `StudyVaultApp/` only for تطبيق وش الرأي.
- Do not work on `ios/BatalAlDroob/`, `_xcodecloud_main/ios/BatalAlDroob/`, `_xcodecloud_clean/ios/BatalAlDroob/`, `DesertTrail/`, or any other app unless the user explicitly asks for that app in the current turn.
- Xcode project: `StudyVaultApp/StudyVault.xcodeproj`.
- Scheme: `StudyVault`.
- App display name: `وش الرأي`.
- Bundle ID: `com.shary17454.esal`.
- Shared app backend for development lives in `StudyVaultApp/backend/`.

## Build

Local iOS simulator validation:

```sh
xcodebuild -project StudyVaultApp/StudyVault.xcodeproj \
  -scheme StudyVault \
  -configuration Release \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/StudyVaultReleaseDerivedData \
  build
```

Native scope and backend checks:

```sh
StudyVaultApp/scripts/validate_wesh_alray_scope.sh
python3 StudyVaultApp/scripts/validate_wesh_alray_data.py
cd StudyVaultApp/backend && npm run check
```

## Constraints

- Always answer in Arabic unless the user explicitly asks for another language.
- Do not modify Batal Al-Droob files while working on وش الرأي.
- Do not change Bundle ID, Development Team, signing, certificates, provisioning profiles, entitlements, or capabilities unless explicitly requested in the current turn.
- Do not upload to App Store Connect or submit for review unless explicitly requested in the current turn.
- Do not commit generated build outputs, archives, DerivedData, `.xcresult` bundles, `.ipa` files, local backend data, or secrets.
- Keep `Info.plist` deriving `CFBundleShortVersionString` and `CFBundleVersion` from Xcode build settings.
- وش الرأي is a native Swift/SwiftUI app; do not add Flutter or Dart runtime dependencies.

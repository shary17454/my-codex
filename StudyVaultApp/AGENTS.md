# وش الرأي Repository Notes

## Scope

- This directory is the native iOS app for تطبيق وش الرأي only.
- Do not modify Batal Al-Droob, DesertTrail, Flutter demo apps, or any sibling app from this directory.
- Treat Flutter/Dart projects elsewhere in the repository as unrelated references unless the user explicitly names them.

## Project

- Xcode project: `StudyVault.xcodeproj`
- Scheme: `StudyVault`
- App display name: `وش الرأي`
- Bundle ID: `com.shary17454.esal`
- Main source: `StudyVault/`
- Development backend: `backend/`
- App Store assets and metadata: `AppStore/`

## Validation

From the repository root:

```sh
StudyVaultApp/scripts/validate_wesh_alray_scope.sh
xcodebuild -project StudyVaultApp/StudyVault.xcodeproj -scheme StudyVault -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/StudyVaultDerivedData build
xcodebuild -project StudyVaultApp/StudyVault.xcodeproj -scheme StudyVault -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/StudyVaultReleaseDerivedData build
```

Backend checks:

```sh
cd StudyVaultApp/backend
npm run check
```

Smoke test requires a running local backend:

```sh
PORT=8787 npm run dev
BASE_URL=http://localhost:8787 npm run smoke
```

## Constraints

- Do not add Flutter or Dart runtime dependencies.
- Do not change signing, team, capabilities, entitlements, or Bundle ID without explicit instruction.
- Do not commit build artifacts, archives, DerivedData, `.xcresult`, `.ipa`, `backend/data/`, or secrets.
- Store sensitive local tokens in Keychain from the app; do not hardcode them in Swift or JavaScript.
- Use SwiftUI and MVVM-compatible structure for new iOS code.

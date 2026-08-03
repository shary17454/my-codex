# Batal Al-Droob iOS

Native SwiftUI iOS/iPadOS app for Nissan Patrol catalog lookup, fitment evidence, saved part requests, maintenance notes, supplier discovery, and a protected catalog unlock through Apple In-App Purchase.

## Project

- Xcode project: `BatalAlDroob.xcodeproj`
- Scheme: `BatalAlDroob`
- Bundle ID: `com.batalaldroob.parts`
- Minimum iOS: 17.0
- App Store version: `2.6`
- Project build: `189`

The app uses bundled JSON catalog data under `BatalAlDroob/Web/data/`. The old web app files remain in the repository for source data history, but the app UI is native SwiftUI.

The complete local PDF archive is indexed under `BatalAlDroob/Web/catalog/` and audited by `scripts/validate_catalog_archive.py`. The 12.51 GiB archive is intentionally excluded from the IPA and Git. Build 189 uses Apple-hosted managed Background Assets: the app ships the complete 640-file delivery index, downloads protected PDF packs on demand, validates file size and SHA-256, and opens the requested page through PDFKit. Original-PDF downloads require iOS 26 or later; indexed catalog search continues to work on iOS 17 and later. See `CatalogAssetPacks/README.md`, `docs/CATALOG_RESOURCE_AUDIT_2026-08-03.md`, and `docs/CATALOG_ASSET_DELIVERY_REPORT_2026-08-03.md`.

## Requirements

- Xcode 26.6 stable, build `17F113`
- Swift 6
- iOS deployment target 17.0
- iOS 26.0 or later for Apple-hosted original-PDF downloads
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
- verifies `MARKETING_VERSION = 2.6`,
- verifies `CURRENT_PROJECT_VERSION >= 189`,
- rejects beta Xcode and SDKs below iPhoneOS 26.5.

After an archive, `ci_scripts/ci_post_xcodebuild.sh` reads the actual app metadata from the new `xcarchive` and rejects mismatched bundle identifiers, versions, build numbers, Xcode builds, SDKs, platforms, deployment targets, or embedded app extensions.

In App Store Connect, set the Batal Al-Droob workflow environment to a production Xcode version. Do not use "Latest Beta" for App Store submission builds.

App Store Connect shows `2.5 (180)` as Ready for Distribution and build `188`
on release train `2.6` as Ready to Submit. The current source candidate uses
build `189` for managed catalog delivery. Build 189 and its hosted asset packs
must not be described as uploaded until Xcode Cloud and App Store Connect both
confirm them. Do not reuse any uploaded or attempted build number.

## In-App Purchase

The app references these StoreKit products for protected catalog access:

- `batal.catalog.single.unlock` (consumable one-page catalog unlock, intended SAR 4 price tier)
- `batal.catalog.permanent.unlock` (primary non-consumable full catalog unlock, intended SAR 100 price tier)
- `batal.catalog.full.unlock` (legacy non-consumable full catalog entitlement while active in App Store Connect)

The legacy `batal.catalog.unlock` product was configured as a consumable and is
not compatible with a permanent, restorable entitlement. Do not attach it to a
corrected release. For first review of any new replacement product, add the
In-App Purchase and the matching new app version to the same App Review
submission. Apple requires an App Review screenshot for each product and a new
binary when the product was omitted from an earlier submission. The App Store
Connect price configuration remains the source of truth for actual displayed
prices.

Part requests are prepared and saved inside the app without a separate purchase product.

## Customer Access

First-run onboarding and the Tools account section require customers to register or sign in with a valid email before entering the app. Entry without an account is intentionally unavailable. The lightweight local profile is used to personalize local request preparation; it is not backend authentication and does not leave the device. The configured owner email `sharyalhwaid@gmail.com` receives local owner catalog access without StoreKit so the app owner can use the full app on his device. Other customers still use StoreKit current entitlements or App Store Connect offer codes for protected catalog access.

The app also exposes Apple's official offer-code redemption sheet from locked
catalog pages. Promotional customer access should be granted through App Store
Connect offer codes for `batal.catalog.permanent.unlock`, then restored and
validated through StoreKit current entitlements.

If you update catalog data, keep the source PDFs under `BatalAlDroob/Web/catalog/patrol_full_unique/`, regenerate the delivery index and pack manifests, and run the full validators before archiving:

```sh
python3 scripts/generate_catalog_asset_packs.py
python3 scripts/validate_catalog_archive.py --full-hash
python3 scripts/validate_release.py
```

Package one Apple-hosted asset pack from the `BatalAlDroob/Web` root mapping:

```sh
python3 scripts/generate_catalog_asset_packs.py \
  --package batal.catalog.y60.001 \
  --output-directory /tmp/BatalCatalogAssetPacks
```

Generated `.aar` archives are release artifacts and must not be committed.

## AI Assistant

The app includes a Batal Al-Droob assistant tab for catalog questions, fitment guidance, and next-step suggestions. The iOS app never stores an OpenAI API key. When `AIAssistantBaseURL` and `AIAssistantClientToken` are empty or unresolved build placeholders, the assistant runs in safe local fallback mode and uses only on-device catalog context.

Optional backend setup:

```sh
cp .env.example .env.local
# Fill OPENAI_API_KEY and BATAL_AI_CLIENT_TOKEN in .env.local.
cd ai-backend
npm test
npm start
```

Configure the iOS build settings only for an environment that has a real backend. `Info.plist` reads these values through build substitution and the app ignores unresolved placeholders:

- `AIAssistantBaseURL`: HTTPS backend URL, or localhost for development.
- `AIAssistantClientToken`: client token matching `BATAL_AI_CLIENT_TOKEN`.

Data sent to the AI backend is deliberately minimized:

- user question, app language, selected category, and current search text,
- vehicle summary without VIN,
- top protected catalog result summaries,
- short maintenance previews,
- saved request count.

The app does not send VIN, passwords, payment data, StoreKit transactions, API keys, or full locked part numbers. The backend uses OpenAI Responses API with `store: false`, validates input, requires a client token, rate-limits requests, redacts common secrets, and returns structured errors. Production deployment should replace the simple client token with stronger user/session authorization and App Attest or equivalent request integrity checks. See [`docs/AI_BACKEND_SETUP.md`](docs/AI_BACKEND_SETUP.md) for the operational setup.

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

The latest source status is `MANAGED_ASSET_DELIVERY_IMPLEMENTED_PENDING_SIGNED_UPLOAD`.
The remaining requirements are deliberately kept visible in the execution
report: a fresh signed Xcode Cloud build 189, upload and processing of all
Apple-hosted asset packs, StoreKit attachment, current screenshots,
privacy-label confirmation, and physical-device download checks.

`docs/APPLE_ENGINEERING_STANDARD.md` is enforced as a release input by
`scripts/validate_release.py`; do not remove or bypass it for app, QA,
accessibility, security, performance, or App Store work.

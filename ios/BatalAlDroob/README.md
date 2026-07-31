# Batal Al-Droob iOS

Native SwiftUI iOS/iPadOS app for Nissan Patrol catalog lookup, fitment evidence, saved part requests, maintenance notes, supplier discovery, and a protected catalog unlock through Apple In-App Purchase.

## Project

- Xcode project: `BatalAlDroob.xcodeproj`
- Scheme: `BatalAlDroob`
- Bundle ID: `com.batalaldroob.parts`
- Minimum iOS: 17.0
- App Store version: `2.2`
- Project build: `166`

The app uses bundled JSON catalog data under `BatalAlDroob/Web/data/`. The old web app files remain in the repository for source data history, but the app UI is native SwiftUI.

## Requirements

- Xcode 26.6 stable, build `17F113`
- Swift 6
- iOS deployment target 17.0
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
- verifies `MARKETING_VERSION = 2.2`,
- verifies `CURRENT_PROJECT_VERSION >= 155`,
- rejects beta Xcode and SDKs below iPhoneOS 26.5.

After an archive, `ci_scripts/ci_post_xcodebuild.sh` reads the actual app metadata from the new `xcarchive` and rejects mismatched bundle identifiers, versions, build numbers, Xcode builds, SDKs, platforms, deployment targets, or embedded app extensions.

In App Store Connect, set the Batal Al-Droob workflow environment to a production Xcode version. Do not use "Latest Beta" for App Store submission builds.

App Store Connect has completed review for the `2.1` train, so new
code-carrying uploads must use a higher marketing version. Xcode Cloud build
`152` failed during "Prepare Build for App Store Connect" after the Y60 image
replacement because it still targeted `2.1`. For the next candidate,
create/open App Store version `2.2` and keep Xcode Cloud > Workflow > Next
Build Number at `155` or higher. Do not reuse any uploaded build number.

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

First-run onboarding and the Tools account section let new customers either continue as a guest or save an optional name and email locally on the device. This lightweight profile is used only to personalize local request preparation; it is not authentication, does not leave the device, and never unlocks paid catalog content. StoreKit current entitlements remain the only source of truth for catalog purchases, restores, and owner/promotional access through App Store Connect offer codes.

The app also exposes Apple's official offer-code redemption sheet from locked
catalog pages. Owner or promotional access must be granted through App Store
Connect offer codes for `batal.catalog.permanent.unlock`, then restored and
validated through StoreKit current entitlements. Do not implement email-only or
local-only owner bypasses in App Store builds.

If you update the bundled catalog data, keep the files inside `BatalAlDroob/Web/data/` and run the regression tests before archiving.

## AI Assistant

The app includes a Batal Al-Droob assistant tab for catalog questions, fitment guidance, and next-step suggestions. The iOS app never stores an OpenAI API key. When `AIAssistantBaseURL` and `AIAssistantClientToken` are empty, the assistant runs in safe local fallback mode and uses only on-device catalog context.

Optional backend setup:

```sh
cp .env.example .env.local
# Fill OPENAI_API_KEY and BATAL_AI_CLIENT_TOKEN in .env.local.
cd ai-backend
npm test
npm start
```

Configure the iOS `Info.plist` keys only for an environment that has a real backend:

- `AIAssistantBaseURL`: HTTPS backend URL, or localhost for development.
- `AIAssistantClientToken`: client token matching `BATAL_AI_CLIENT_TOKEN`.

Data sent to the AI backend is deliberately minimized:

- user question, app language, selected category, and current search text,
- vehicle summary without VIN,
- top protected catalog result summaries,
- short maintenance previews,
- saved request count.

The app does not send VIN, passwords, payment data, StoreKit transactions, API keys, or full locked part numbers. The backend uses OpenAI Responses API with `store: false`, validates input, requires a client token, rate-limits requests, redacts common secrets, and returns structured errors. Production deployment should replace the simple client token with stronger user/session authorization and App Attest or equivalent request integrity checks.

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

The latest verification status is `READY_WITH_EXTERNAL_REQUIREMENTS`. The
remaining requirements are deliberately kept visible in the execution report:
a fresh signed Xcode Cloud build `155` or higher on release train `2.2`,
completion and attachment of the permanent IAP in App Store Connect, current
screenshots, privacy-label confirmation, and manual device checks.

`docs/APPLE_ENGINEERING_STANDARD.md` is enforced as a release input by
`scripts/validate_release.py`; do not remove or bypass it for app, QA,
accessibility, security, performance, or App Store work.

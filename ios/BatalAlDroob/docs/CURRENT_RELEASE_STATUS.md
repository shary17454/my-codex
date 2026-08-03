# Batal Al-Droob Current Release Status

Updated: 2026-08-03
Decision: `2_6_LOCAL_CANDIDATE_VERIFIED_RESOURCE_DELIVERY_BLOCKED`

## Identity

| Item | Value |
|---|---|
| App | Batal Al-Droob / بطل الدروب |
| Apple ID | `6786117376` |
| Bundle ID | `com.batalaldroob.parts` |
| Marketing version | `2.6` |
| Project build | `186` |
| Current App Store release | `2.5 (180)` - Ready for Distribution |
| Deployment target | iOS / iPadOS 17.0 |
| Verified toolchain | Xcode 26.6 (`17F113`), iPhoneOS SDK 26.5 |

No Bundle ID, Development Team, signing setting, entitlement, or capability was changed in this work.

## Verified Product State

- First launch requires a valid email through Register or Sign In. There is no guest entry point or guest access mode.
- The welcome experience is a dedicated first-run screen. Its image, text, fields, and buttons were visually verified on iPhone 17 Pro in Arabic RTL.
- The signed-in dashboard is compact and shows Y60 `1988-1997`, Y61 `1997-2025`, and Y62 `2010-2025`.
- Natural Arabic and dialect search coverage includes steering terms such as `ذراع دركسون` and guards against ranking a nut for `ديكور القير العنابي`.
- StoreKit remains the source of truth for customer paid access. The configured owner email is a local owner-access rule, not backend identity verification.
- The AI backend client and server implementation exist, but the Release app currently has empty `AIAssistantBaseURL` and `AIAssistantClientToken` values. The app therefore uses its local catalog assistant and does not send requests to a hosted AI service.

## Catalog Resources

| Metric | Result |
|---|---:|
| Manifest entries | 640 |
| Physical PDFs in official source | 640 |
| Physical PDFs in complete archive | 640 |
| Unique SHA-256 values | 612 |
| Total size | 12.51 GiB |
| Y60 files | 297 |
| Y61 files | 143 |
| Y62 files | 140 |
| General / unknown files | 60 |

Every manifest path, file size, and SHA-256 was verified in the official source, the complete archival copy, and the final unsigned Release app bundle.

## Current Verification

| Gate | Result |
|---|---|
| Release validator | PASS |
| Catalog archive validator | PASS, 640/640 |
| Full catalog SHA-256 verification | PASS |
| Privacy and Info property lists | PASS |
| SwiftFormat on changed Swift files | PASS, 0/4 |
| Backend tests | PASS, 9/9 |
| Unit tests | PASS, 45/45 |
| UI tests | PASS, 3/3 |
| Total iOS tests | PASS, 48/48 |
| RTL visual review | PASS for first-run and home screens |
| Release device build without signing | PASS with Xcode 26.6 / SDK 26.5 |
| Current candidate metadata | PASS: `2.6 (186)`, correct Bundle ID and minimum iOS 17.0 |
| Current Git candidate payload | 104 MB and 0 PDFs because the archive is Git-ignored |
| Prior full-resource archival build | PASS: `2.4 (172)`, 640 PDFs and full SHA-256 |
| SwiftLint strict | FAIL: 83 style/structure violations |

The current `2.6 (186)` candidate produced an unsigned local xcarchive with
Xcode 26.6. Its app metadata passed the same pre- and post-archive guards used
by Xcode Cloud, and all 45 unit tests plus 3 UI tests passed. The archive is
approximately 109 MB and contains no catalog PDFs because those files are
Git-ignored pending an App Store-safe delivery architecture.

App Store Connect already lists `2.5 (180)` as Ready for Distribution. Xcode
Cloud build `185` archived successfully but failed during Prepare Build for App
Store Connect because it targeted that already released version train. The next
code-carrying candidate therefore uses `2.6` and does not reuse build `185`.

## Distribution Blockers

1. The locally complete app bundle is approximately 13 GB. Apple documents a 4 GB maximum uncompressed iOS/iPadOS app size, so this payload cannot be submitted as one embedded bundle.
2. The PDF directory is intentionally Git-ignored. Xcode Cloud cannot package files that are not present in its source checkout.
3. Move catalog PDFs to Apple-hosted Background Assets or an authenticated remote catalog service, retain the manifest/search indexes in the app, and download files on demand with integrity verification.
4. Configure and deploy the AI backend before claiming hosted AI. Keep the provider key only on the server and inject only the backend URL and a revocable client credential at build time.
5. Resolve the 83 SwiftLint strict violations through scoped file splitting and line cleanup; do not weaken the lint policy to hide them.
6. Re-run StoreKit Sandbox, VoiceOver, and performance tests on a physical device before submission.
7. Re-check App Store Connect metadata, IAP review attachment, screenshots, privacy answers, and the selected build immediately before review submission.

## Distribution Claim Boundary

Passing the local `2.6 (186)` archive proves source and metadata correctness,
not an App Store upload. A signed Xcode Cloud result and App Store Connect
processing state must be checked separately. The complete 640-PDF archive must
not be claimed as present in an App Store build until an approved on-demand
resource architecture is implemented and its downloaded files are verified.

# Batal Al-Droob Current Release Status

Updated: 2026-08-03
Decision: `2_6_BUILD_189_MANAGED_ASSETS_LOCAL_VERIFIED_UPLOAD_PENDING`

## Identity

| Item | Value |
|---|---|
| App | Batal Al-Droob / بطل الدروب |
| Apple ID | `6786117376` |
| Bundle ID | `com.batalaldroob.parts` |
| Marketing version | `2.6` |
| Project build | `189` |
| Current App Store release | `2.5 (180)` - Ready for Distribution |
| Last confirmed App Store Connect build | `2.6 (188)` - Ready to Submit |
| Deployment target | iOS / iPadOS 17.0 |
| Verified toolchain | Xcode 26.6 (`17F113`), iPhoneOS SDK 26.5 |

The app Bundle ID, Development Team, and signing mode were not changed. Build
189 adds the required shared App Group entitlement and Background Assets
extension for Apple-hosted catalog delivery. These capability changes are
scoped to the app and its extension and still require signed Apple Developer
registration before an App Store claim can be made.

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

Every source manifest path, file size, and SHA-256 was verified in the official
source. The complete archival copy retains all 640 PDFs. The Release app bundle
contains the 640-document delivery index and no embedded PDF; the originals are
partitioned into 40 Apple-hosted managed asset packs.

## Current Verification

| Gate | Result |
|---|---|
| Release validator | PASS |
| Catalog archive validator | PASS, 640/640 |
| Full catalog SHA-256 verification | PASS |
| Privacy and Info property lists | PASS |
| Managed asset manifests | PASS, 40 packs / 640 documents |
| Packager output | PASS, 40/40 AAR with Xcode 26.6 and `ba-package 1.2` |
| AAR checksum inventory | PASS, 40/40 SHA-256 values recorded |
| Backend tests | PASS, 9/9 |
| Unit tests | PASS, 48/48 |
| UI tests | PASS, 4/4 |
| Total completed iOS tests | PASS, 52/52 |
| Managed catalog library UI test | PASS: opens the library and verifies the 640-document index |
| RTL visual review | PASS for first-run and home screens |
| Release device build without signing | PASS with Xcode 26.6 / SDK 26.5 |
| Current candidate metadata | PASS: `2.6 (189)`, correct app Bundle ID and minimum iOS 17.0 |
| Current Release app payload | Approximately 105 MB, 0 PDFs, delivery manifest and extension present |
| Prior full-resource archival build | PASS: `2.4 (172)`, 640 PDFs and full SHA-256 |
| SwiftLint strict | Prior audit reported 83 style/structure violations; not waived |

The current `2.6 (189)` candidate builds for a generic iOS device without
signing. Its app metadata passes the same pre- and post-build guards used by
Xcode Cloud. The completed suite contains 48 unit tests and 4 UI tests. The
managed-library test opens the dedicated screen and verifies the 640-document
index, generation picker, and first indexed document. All tests passed serially
on iPhone 17 Pro / iOS 26.5.

App Store Connect already lists `2.5 (180)` as Ready for Distribution. Xcode
Cloud build `188` was processed and is Ready to Submit. It does not contain the
new managed catalog delivery implementation. Build 189 is the next
code-carrying candidate and must not be described as uploaded until a fresh
signed Xcode Cloud build is processed in App Store Connect.

## Distribution Blockers

1. Register and sign the extension Bundle ID and shared App Group in the Apple Developer account, then produce a signed Xcode Cloud build 189.
2. Upload all 40 generated AAR files to the Batal Al-Droob App Store Connect record and wait until every pack is processed without failure.
3. Validate real downloads for Y60, Y61, Y62, and general catalogs through TestFlight on iOS 26 or later. Search remains supported on iOS 17-25, but managed original-PDF download requires iOS 26.
4. Submit the 40 packs in four review batches because Apple currently accepts at most ten asset packs per review submission. Do not submit the app or packs for review without the owner's explicit instruction.
5. Configure and deploy the AI backend before claiming hosted AI. Keep the provider key only on the server and inject only the backend URL and a revocable client credential at build time.
6. Resolve the existing SwiftLint strict violations through scoped file splitting and line cleanup; do not weaken the lint policy to hide them.
7. Re-run StoreKit Sandbox, VoiceOver, and performance tests on a physical device before submission.
8. Re-check App Store Connect metadata, IAP review attachment, screenshots, privacy answers, and the selected build immediately before review submission.

## Distribution Claim Boundary

Passing the local `2.6 (189)` build proves source, metadata, index, packaging,
and local integrity correctness; it does not prove an App Store upload. The
managed delivery architecture is implemented and all 40 AAR files exist
locally, but the complete 640-PDF catalog must not be claimed as available to
customers until Apple processes the packs and a TestFlight device successfully
downloads and verifies representative files.

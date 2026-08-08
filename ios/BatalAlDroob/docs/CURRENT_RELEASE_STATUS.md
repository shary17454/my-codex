# Batal Al-Droob Current Release Status

Updated: 2026-08-08
Decision: `2_8_BUILD_214_ARCHIVED_AND_UPLOADED_AWAITING_SUBMISSION`

## Identity

| Item | Value |
|---|---|
| App | Batal Al-Droob / بطل الدروب |
| Apple ID | `6786117376` |
| Bundle ID | `com.batalaldroob.parts` |
| Marketing version | `2.8` |
| Project build | `214` |
| Current App Store release | `2.5 (180)` - Ready for Distribution |
| Last confirmed App Store Connect build | `2.6 (188)` - Ready to Submit |
| Deployment target | iOS / iPadOS 17.0 |
| Verified toolchain | Local: Xcode 26.4.1 (`17E202`). Archive: Xcode Cloud, Xcode 26.6 |
| Xcode Cloud `2ed56cc` | Build **success**, Archive **success** — uploaded |
| Release plan | Skip `2.7` (approved but unreleased); submit `2.8` |

## What Changed In 214

Build 214 carries no new product surface. It is a correctness, performance, and
localization pass over `2.7 (191)`, on the `2.8` train because `2.7` was approved and
is closed to further uploads (`ITMS-90186` / `ITMS-90062` on build `213`); see `CHANGELOG.md` for the itemised list. Bundle
ID, development team, signing mode, entitlements, App Group, capabilities, catalog
data, and the managed asset-pack delivery are unchanged.

The one behavioural change a reviewer would notice: the eight non-Arabic interface
languages declared in `CFBundleLocalizations` are now actually translated across the
static interface, including the first-run screen, instead of falling back to English
for all but ~28 strings.

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
| Backend tests | PASS, 9/9 (prior run) |
| Unit tests | **PASS, 70/70** on `BatalTest265` / iOS 26.5, 2026-08-08 |
| UI tests | **PASS, 5/5** on the same device; one needed a re-run, see below |
| Managed catalog library UI test | PASS: opens the library and verifies the 640-document index |
| RTL visual review | PASS for first-run and home screens |
| Release device build without signing | PASS with Xcode 26.6 / SDK 26.5 |
| Current candidate metadata | PASS: `2.6 (189)`, correct app Bundle ID and minimum iOS 17.0 |
| Current Release app payload | Approximately 105 MB, 0 PDFs, delivery manifest and extension present |
| Prior full-resource archival build | PASS: `2.4 (172)`, 640 PDFs and full SHA-256 |
| SwiftLint strict | PASS, 0 violations (the previously reported 83 no longer reproduce) |

`2.8 (214)` archives locally and on Xcode Cloud, and the archive metadata guard
passes against both. The unit suite is 70 tests (48 catalog/resource + 22 phase-1 and
localization, of which 13 are new in this build) and all 70 passed on a dedicated
simulator. The UI suite is 5 tests and all 5 passed, but honestly: the full-suite run was 4/5,
and `testManagedCatalogLibraryLoadsAllIndexedDocuments` failed on a
`waitForExistence(timeout: 10)` for the library navigation bar. It passed on a
re-run in 32s, and `testCriticalNavigationAndLocalRequestFlow` had failed the same
way earlier and then passed twice. Both are navigation waits timing out while the
host was at load 400-700, not product defects — a single UI test took 87s on that
machine. The library wait is now 20s for the same reason the project already
widened the catalog-tab wait.

Release train `2.7` was approved and is therefore closed to new uploads: build `213`
was archived, uploaded, and then rejected in processing with `ITMS-90186` (train
closed) and `ITMS-90062` (version must exceed the approved `2.7`). `2.8 (214)` is the
live candidate; its Xcode Cloud archive succeeded and the build reached App Store
Connect. Release copy for both languages is in
`docs/APP_STORE_RELEASE_NOTES_2_8.md`.

## Distribution Blockers

1. Register and sign the extension Bundle ID and shared App Group in the Apple Developer account, then produce a signed Xcode Cloud build 189.
2. Upload all 40 generated AAR files to the Batal Al-Droob App Store Connect record and wait until every pack is processed without failure.
3. Validate real downloads for Y60, Y61, Y62, and general catalogs through TestFlight on iOS 26 or later. Search remains supported on iOS 17-25, but managed original-PDF download requires iOS 26.
4. Submit the 40 packs in four review batches because Apple currently accepts at most ten asset packs per review submission. Do not submit the app or packs for review without the owner's explicit instruction.
5. Configure and deploy the AI backend before claiming hosted AI. Keep the provider key only on the server and inject only the backend URL and a revocable client credential at build time.
6. Translate the remaining interpolated interface strings (counters such as
   "1,204 linked records"). They cannot be table keys because the key would have to be
   the already-formatted result, so they still fall back to English; closing this needs
   format-string entries rather than more table rows.
7. Re-run StoreKit Sandbox, VoiceOver, and performance tests on a physical device before submission.
8. Re-check App Store Connect metadata, IAP review attachment, screenshots, privacy answers, and the selected build immediately before review submission.

## Distribution Claim Boundary

Passing the local `2.6 (189)` build proves source, metadata, index, packaging,
and local integrity correctness; it does not prove an App Store upload. The
managed delivery architecture is implemented and all 40 AAR files exist
locally, but the complete 640-PDF catalog must not be claimed as available to
customers until Apple processes the packs and a TestFlight device successfully
downloads and verifies representative files.

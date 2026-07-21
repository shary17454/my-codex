# App Store Review Fix Plan

Updated: 2026-07-21

This file is the local release gate for review issues that cannot be fully
validated from source code alone. Do not submit Batal Al-Droob until every
manual item below is checked against the exact uploaded build in App Store
Connect.

## Current App

| Item | Value |
|---|---|
| App | Batal Al-Droob / بطل الدروب |
| Apple ID | `6786117376` |
| Bundle ID | `com.batalaldroob.parts` |
| Release train | `1.1.0` |
| Project build | `111` |
| IAP product | `batal.catalog.permanent.unlock` |
| IAP type | Non-consumable |

## Apple Review Issues To Clear

| Guideline / Code | Source | Required action |
|---|---|---|
| Guideline 2.1(b) App Completeness | Latest documented Batal-specific review issue | Submit the binary and the non-consumable IAP in the same review submission. |
| Guideline 2.3.3 Accurate Metadata | App Review message shown in chat | Replace 6.5-inch iPhone and 13-inch iPad screenshots with screenshots from the current native app in use. |
| Guideline 2.3.2 Accurate Metadata | App Review message shown in chat | Replace or remove promoted-IAP artwork that is merely an in-app screenshot. Use a unique, accurate promotional image if promoting the IAP. |
| ITMS-90111 / ITMS-90478 / ITMS-90186 / ITMS-90062 | Earlier App Store Connect messages | Keep Xcode Cloud on a production Xcode and keep all bundle versions unified. |

## Mandatory App Store Connect Checklist

- [ ] Xcode Cloud workflow uses Xcode 26.6 (`17F113`) or a newer non-beta
      production Xcode accepted by Apple for App Store submission.
- [ ] Xcode Cloud Next Build Number is higher than all prior uploads.
- [ ] Uploaded build is created from the current source commit.
- [ ] App Store version is exactly `1.1.0`.
- [ ] Selected build number is `111` or higher and has not been reused.
- [ ] In-App Purchase `batal.catalog.permanent.unlock` is complete.
- [ ] IAP type is Non-consumable.
- [ ] IAP price, availability, localization, and review notes are complete.
- [ ] IAP App Review screenshot shows the current native purchase surface.
- [ ] Promoted-IAP image is not a direct screenshot of the app.
- [ ] iPhone 6.5-inch screenshots show current native app functionality.
- [ ] 13-inch iPad screenshots show current native app functionality.
- [ ] Screenshots show catalog search, part detail, store handoff, request
      preparation, maintenance, and tools rather than splash/login-only screens.
- [ ] Privacy labels match the local-only data handling described in the app.
- [ ] Review notes explain that paid access uses Apple IAP only and requests do
      not require payment.

## Review Notes Template

Arabic and English UI are both available from the in-app language menu. The app
is a native SwiftUI Nissan Patrol catalog helper. It lets users search a bundled
offline catalog, inspect fitment evidence, prepare part requests locally, keep a
local maintenance log, and open verified external store links. It does not copy
store prices or inventory.

Paid access is handled only through Apple In-App Purchase using the
non-consumable product `batal.catalog.permanent.unlock`. The product unlocks
alternate part numbers and advanced catalog evidence. Part request preparation,
catalog search, maintenance, and tools remain usable without payment. No
external payment method is used.

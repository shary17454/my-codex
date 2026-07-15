# Release Checklist - Batal Al-Droob iOS

## Version

- Marketing version: `1.1.0`
- Build number: `84`
- Bundle ID: `com.batalaldroob.parts`
- Minimum iOS: `17.0`
- Xcode validated: `26.6 (17F113)`

## What’s New

### Arabic

- تحسين حالات الواجهات الفارغة في البحث، الأدلة، الطلبات، الصيانة، وقائمة الرغبات.
- تحسين رسائل التتبع والطقس وحالة تحميل الطقس.
- إضافة Privacy Manifest للتوافق مع متطلبات Apple.
- تحسين حقول الإدخال للسنوات، VIN، أرقام القطع، والعداد.
- رفع رقم الإصدار والبناء وتجهيز نسخة إصدار جديدة.

### English

- Improved empty states across search, evidence, requests, maintenance, and wishlist.
- Improved tracking and weather loading/error messaging.
- Added Privacy Manifest for Apple compliance.
- Improved input behavior for years, VIN, part numbers, and odometer fields.
- Bumped version and build for a new release candidate.

## Build

- [x] Debug simulator build passed after changes.
- [x] Release simulator build passed after changes.
- [ ] Device build verified.
- [ ] App Store archive verified with signing on the release machine or Xcode Cloud.

## Tests

- [x] Existing test command checked.
- [ ] Unit tests: not available in current scheme.
- [ ] UI tests: not available in current scheme.
- [ ] Manual smoke test on iPhone.
- [ ] Manual smoke test on iPad if iPad remains supported.

## Critical Manual QA

- [ ] Launch app.
- [ ] Switch Arabic / English and verify RTL / LTR.
- [ ] Search by part number.
- [ ] Search by category.
- [ ] Open part details.
- [ ] Wishlist add/remove.
- [ ] Maintenance add/save.
- [ ] Part request form validation.
- [ ] Sandbox purchase for catalog unlock.
- [ ] Sandbox purchase for each part request product:
  - `batal.parts.request.basic`
  - `batal.parts.request.urgent`
  - `batal.parts.request.rare`
- [ ] Restore/previous entitlement behavior if required by product rules.
- [ ] Location permission prompt.
- [ ] Tracking on device.
- [ ] Compass on device.
- [ ] Weather with network available.
- [ ] Weather with network unavailable.

## Privacy / Security

- [x] `PrivacyInfo.xcprivacy` added.
- [x] UserDefaults required reason declared.
- [ ] App Store Privacy Labels manually reviewed.
- [ ] Confirm Open-Meteo weather request treatment in privacy labels.
- [ ] Confirm no payment card data is collected by the app.
- [ ] Confirm no analytics/crash SDK privacy declarations are needed.

## Store Metadata

- [ ] Screenshots reviewed.
- [ ] Arabic release notes entered if submitting.
- [ ] English release notes entered if submitting.
- [ ] Support URL functional.
- [ ] Review notes updated if sending Build 84.
- [ ] In-App Purchases approved/available.

## Release Action

Current requested action: `PREPARE_ONLY`.

- Do not upload to TestFlight from this task.
- Do not submit for review from this task.
- Build 83 is already waiting for Apple review from the previous action.
- If Build 84 should replace Build 83, first remove the current version from review in App Store Connect, then select Build 84 after Xcode Cloud archives it.

## Rollback

- Keep Build 83 in review unless Build 84 is explicitly selected to replace it.
- If Build 84 is rejected or fails manual QA, keep the current App Store Connect submission unchanged.

# App Review Notes

App name: Batal Al-Droob / بطل الدروب

This app is an informational reference catalog for Nissan Patrol Y60 parts. It contains an offline bundled catalog database extracted from parts PDFs and audited into structured records.

No login is required.
The app uses Apple In-App Purchase for protected catalog lookups and paid part request services.
Configured product identifiers:
- `batal.catalog.unlock`: consumable catalog/part-number lookup unlock.
- `batal.parts.request.basic`: consumable basic part request, 10 SAR.
- `batal.parts.request.urgent`: consumable urgent part request, 20 SAR.
- `batal.parts.request.rare`: consumable rare/NOS part request, 50 SAR.
The payment flow is used to unlock protected part-number details, indexed catalog evidence, fitment data, and paid part request drafts.
No user-generated content is submitted in this version.
No account credentials are needed for review.
The app does not use non-exempt encryption; `ITSAppUsesNonExemptEncryption` is set to `false`.

Main test flow:
1. Open the app.
2. Search for a part number such as `63850-05J91`.
3. Open a result.
4. Review the locked catalog/part-number details.
5. Start the Apple In-App Purchase unlock flow for `batal.catalog.unlock`.
6. After unlock, review the revealed part numbers, fitment years, indexed catalog evidence, audit status, and confidence score. Original PDF files are not bundled in this App Store build.
7. Open the paid part request screen and verify the three request tiers.
8. Switch language between Arabic and English using the top button.

Distribution note:
- The app download should be free.
- Paid functionality is handled through Apple In-App Purchase, not through a paid app price.
- Part request tiers in the app are: basic 10 SAR, urgent 20 SAR, rare/NOS 50 SAR.
Latest review preparation update:
- A new iPad-responsive layout pass was added for App Review after the earlier design feedback on build 42.
- The current submission candidate uses version `1.0.1`.
- Tablet screens now use a wider adaptive layout instead of the previous narrow phone-style presentation.

## App Review fixes in build 54

- Guideline 4: The iPad interface now uses the full available canvas with responsive multi-column layouts, larger controls, and consistent spacing instead of rendering the phone storefront in a narrow fixed-width frame.
- Guideline 2.1(a): The WebKit file input that exposed the camera path was removed. Image selection now uses Apple's native PHPicker and is limited to the photo library. We tested opening and cancelling the picker on an iPad Air 11-inch simulator running iPadOS 26.5 without a crash.
- Guideline 1.5: The Support URL has been replaced with a public support page containing Arabic and English support information.

## App Review fixes in build 56

- Version/Build updated to `1.0.1+56`.
- App Store metadata URLs (Privacy Policy / Support) now point to `https://batal-al-droob-support.sharyalhwaid.chatgpt.site` in both Arabic and English metadata.
- Camera startup now prefers back camera in capture flows and handles missing camera/access-denied errors more gracefully with stable fallback and readable user messages.
- Camera initialization path now consistently returns actionable errors on failure to aid debugging before retrying.

## App Review fixes in build 60

- Version/Build updated to `1.0.1+60` for the Batal Al-Droob target only.
- Guideline 1.5: Review notes now explicitly provide the public support context and confirm the app has no login requirement. Support and Privacy URLs should remain set to `https://batal-al-droob-support.sharyalhwaid.chatgpt.site` in App Store Connect.
- Guideline 2.1: Review notes now include a complete reviewer test flow covering search, result details, locked catalog details, Apple In-App Purchase unlock, request tiers, and language switching.
- Build 59 was not selected for this submission because it was produced from `DesertTrail` / `Al Darb` changes in the shared repository, not from the Batal Al-Droob target.

## App Review fixes in build 65

- Version/Build updated to `1.0.1+65` for the Batal Al-Droob target only.
- Build 64 was not selected because it was generated from `DesertTrail` / `Al Beed` changes in the shared repository and failed in Xcode Cloud with no reported project build errors.
- This submission returns the Xcode Cloud latest commit to the correct Batal Al-Droob App Store target (`com.batalaldroob.parts`).

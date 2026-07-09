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

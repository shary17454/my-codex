# App Store Submission Checklist - Batal Al-Droob

## Apple Developer
- [ ] Apple Developer Program approved.
- [ ] App Store Connect access available.
- [ ] Agreements, Tax, and Banking completed before enabling In-App Purchases.
- [ ] Paid Applications Agreement accepted by the Account Holder.
- [ ] Bank account added and verified in App Store Connect.
- [ ] Tax forms completed in App Store Connect.

## App Record
- [ ] Create new app in App Store Connect.
- [ ] Name: Batal Al-Droob / بطل الدروب.
- [ ] Bundle ID: com.batalaldroob.parts.
- [ ] SKU: batal-droob-y60.
- [ ] Primary language selected.
- [ ] Category selected: Reference or Utilities.

## Required URLs
- [x] Bundle `privacy.html` inside the app.
- [x] Bundle `support.html` inside the app.
- [x] Bundle `terms.html` inside the app.
- [ ] Host privacy/support/terms on HTTPS public URLs for App Store metadata.
- [ ] Add both URLs in App Store Connect.

## Media
- [ ] Upload app icon.
- [ ] Upload iPhone screenshots.
- [ ] Optional: iPad screenshots if iPad support is enabled.

## Build
- [x] Open Xcode project.
- [x] Select Team.
- [x] Confirm Bundle ID: `com.batalaldroob.parts`.
- [x] Archive build.
- [x] Upload to App Store Connect.
- [x] Select Build 12 for App Store version 1.0.
- [ ] Test in TestFlight.
- [ ] Submit for review.

## Current App Store Connect blockers
- [ ] App Information: set Content Rights declaration.
- [ ] App Information: complete Age Rating questions.
- [ ] Pricing and Availability: select Free app price because monetization is through In-App Purchases.
- [ ] In-App Purchases: create `batal.catalog.unlock` as a consumable catalog lookup unlock.
- [ ] In-App Purchases: create `batal.parts.request.basic` as a consumable paid request at 10 SAR.
- [ ] In-App Purchases: create `batal.parts.request.urgent` as a consumable paid request at 20 SAR.
- [ ] In-App Purchases: create `batal.parts.request.rare` as a consumable paid request at 50 SAR.
- [ ] In-App Purchases: submit the four products with app version 1.0 review.

## Review Notes
- [ ] Add review notes from `app-store/review_notes.md`.
- [ ] Mention no login is required.

# Batal Al-Droob Release Checklist

Use this list for every App Store candidate. A checked item must have current evidence for the exact commit and archive being submitted.

## Source And Toolchain

- [ ] The intended commit is pushed and selected by the Batal Al-Droob Xcode Cloud workflow.
- [ ] Xcode Cloud uses Xcode 26.6 (`17F113`) or a newer Apple-approved non-beta release.
- [ ] The iPhoneOS SDK is 26.5 or newer and `SDKROOT` is not pinned to a beta/old SDK.
- [x] `python3 ios/BatalAlDroob/scripts/validate_release.py` passes locally for the permanent-IAP source.
- [x] `swiftformat ... --lint` passes for the changed Swift files: 0/4 require formatting.
- [ ] `swiftlint lint --strict --no-cache` passes. Current known debt: 83 violations; do not mark complete until fixed and rerun.
- [ ] Xcode static analysis passes.

## Version And Build

- [x] Every target uses candidate `MARKETING_VERSION = 2.6`; App Store release `2.5 (180)` is closed to new code-carrying uploads.
- [ ] Xcode Cloud Next Build Number is greater than every prior upload.
- [x] The repository and archive guards require Xcode Cloud build `186` or higher and verify the actual archive against `CI_BUILD_NUMBER`.
- [x] All local app and test targets use one matching marketing version and project build: `2.6 (186)`.
- [ ] The version train is open; no build is attached to a closed or released train.

## Build And Tests

- [x] Dependency resolution succeeds.
- [x] Debug build succeeds as part of the verified test action.
- [x] Release archive succeeds locally with Xcode 26.6 (`17F113`) and iPhoneOS SDK 26.5.
- [x] Unit tests pass on iPhone 17 Pro / iOS 26.5: 45/45.
- [x] iPhone UI tests pass: 3/3, including required first-run account access, navigation, search, and RTL/language switching.
- [ ] Relevant tests pass on a physical iPhone.
- [ ] Confirm the removed map, location tracking, and compass surfaces do not appear in the submitted build.
- [ ] StoreKit purchase, cancel, pending, failure, current entitlement, and restore are checked in Sandbox.
- [ ] VoiceOver, Accessibility Inspector, large Dynamic Type, Light/Dark, Reduce Motion, rotation, iPad Split View, and Stage Manager are manually checked.
- [ ] Instruments Leaks, Time Profiler, and Energy checks are completed for critical flows.

## Archive

- [x] A fresh unsigned local archive for `2.6 (186)` succeeds with Xcode 26.6.
- [x] Local archive metadata confirms bundle `com.batalaldroob.parts`, version `2.6 (186)`, Xcode 26.6, iPhoneOS SDK 26.5, and iOS 17.0 minimum.
- [ ] A new signed Xcode Cloud `2.6 (186+)` archive is verified before selecting an App Store build.
- [ ] A fresh signed Xcode Cloud archive is created from the intended commit.
- [x] `ci_post_xcodebuild.sh` passes against the local `2.6 (186)` xcarchive using simulated Xcode Cloud inputs.
- [x] Local archive metadata confirms bundle, version/build, production Xcode, accepted SDK, and iOS 17.0 minimum.
- [ ] Every embedded bundle, if introduced later, matches the app version/build.
- [x] The local archive contains `PrivacyInfo.xcprivacy`.

## Privacy, Services, And Store Metadata

- [ ] App Store privacy labels are human-confirmed against the final app, which no longer requests location access.
- [ ] No Open-Meteo endpoint or other external weather integration remains in source or the submitted binary.
- [ ] No location usage description is present unless location features are deliberately reintroduced later.
- [ ] StoreKit products `batal.catalog.single.unlock`, `batal.catalog.permanent.unlock`, and any still-active `batal.catalog.full.unlock` legacy entitlement are complete, cleared for sale where appropriate, and attached to the same first-review submission as the binary.
- [ ] Product types match the app: single unlock is Consumable; full and legacy unlocks are Non-consumable.
- [ ] The legacy consumable `batal.catalog.unlock` is not attached to the corrected permanent-unlock submission.
- [ ] The IAP review screenshot demonstrates the purchase surface.
- [ ] Promoted-IAP artwork represents the product and is not an ordinary app screenshot.
- [ ] 6.5-inch iPhone and 13-inch iPad screenshots show the current native app in use and its core functionality.
- [ ] Review notes accurately explain the mandatory local email registration/sign-in, owner-local access limitation, and Apple In-App Purchase customer flow.
- [ ] Agreements, tax, banking, export compliance, content rights, and age rating are complete.

## Submission

- [ ] No unresolved App Review item remains in the selected submission.
- [ ] Only the newly validated build is selected.
- [ ] Build `186` or higher is selected for iOS App Version `2.6`.
- [ ] Release notes match implemented behavior.
- [ ] App Review submission is sent only after explicit approval and every preceding external gate is complete.

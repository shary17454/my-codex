# Batal Al-Droob Release Checklist

Use this list for every App Store candidate. A checked item must have current evidence for the exact commit and archive being submitted.

## Source And Toolchain

- [ ] The intended commit is pushed and selected by the Batal Al-Droob Xcode Cloud workflow.
- [ ] Xcode Cloud uses Xcode 26.6 (`17F113`) or a newer Apple-approved non-beta release.
- [ ] The iPhoneOS SDK is 26.5 or newer and `SDKROOT` is not pinned to a beta/old SDK.
- [x] `python3 ios/BatalAlDroob/scripts/validate_release.py` passes locally for the permanent-IAP source.
- [x] `swiftformat ... --lint` passes locally: 0/12 files require formatting.
- [x] `swiftlint lint --strict --no-cache` passes locally: 0 violations.
- [ ] Xcode static analysis passes.

## Version And Build

- [ ] `MARKETING_VERSION` exactly matches the open App Store version; after App Store Connect completed review for `2.1`, this must be `2.2` or higher for the next code-carrying candidate.
- [ ] Xcode Cloud Next Build Number is greater than every prior upload.
- [ ] `ci_pre_xcodebuild.sh` runs before archive and synchronizes `CURRENT_PROJECT_VERSION` to the actual `CI_BUILD_NUMBER`.
- [ ] All targets have one matching marketing version and build number.
- [ ] The version train is open; no build is attached to a closed or released train.

## Build And Tests

- [ ] Dependency resolution succeeds.
- [ ] Debug build succeeds.
- [x] Release build succeeds locally with Xcode 26.4.1 and iPhoneOS SDK 26.4 as an engineering validation fallback.
- [x] Unit tests pass on a current iPhone simulator: 19/19.
- [x] iPhone UI smoke tests pass: 2/2, including the redesigned tools surface.
- [ ] Relevant tests pass on a physical iPhone.
- [ ] Confirm the removed map, location tracking, and compass surfaces do not appear in the submitted build.
- [ ] StoreKit purchase, cancel, pending, failure, current entitlement, and restore are checked in Sandbox.
- [ ] VoiceOver, Accessibility Inspector, large Dynamic Type, Light/Dark, Reduce Motion, rotation, iPad Split View, and Stage Manager are manually checked.
- [ ] Instruments Leaks, Time Profiler, and Energy checks are completed for critical flows.

## Archive

- [ ] A fresh unsigned local archive for build `155` succeeds with the selected production Xcode as an engineering validation fallback.
- [ ] Local archive metadata confirms bundle `com.batalaldroob.parts`, version `2.2 (155+)`, accepted Xcode build, accepted SDK, and iOS 17.0 minimum.
- [ ] New signed Xcode Cloud `2.2 (155+)` archive metadata is verified before selecting a new App Store build.
- [ ] A fresh signed Xcode Cloud archive is created from the intended commit.
- [x] `ci_post_xcodebuild.sh` passes against Xcode Cloud build `122`.
- [ ] Archive metadata confirms bundle `com.batalaldroob.parts`, expected version/build, production Xcode, accepted SDK, and iOS 17.0 minimum.
- [ ] Every embedded bundle, if introduced later, matches the app version/build.
- [ ] The archive contains `PrivacyInfo.xcprivacy`.

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
- [ ] Review notes accurately explain that no sign-in is required and purchases use Apple In-App Purchase only.
- [ ] Agreements, tax, banking, export compliance, content rights, and age rating are complete.

## Submission

- [ ] No unresolved App Review item remains in the selected submission.
- [ ] Only the newly validated build is selected.
- [ ] Build `155` or higher is selected for iOS App Version `2.2`.
- [ ] Release notes match implemented behavior.
- [x] Submitted after explicit approval: App Review submission `00e306d9-8983-4df8-b284-6cbc1fff2c04` is `Waiting for Review`.

# Batal Al-Droob Release Checklist

Use this list for every App Store candidate. A checked item must have current evidence for the exact commit and archive being submitted.

## Source And Toolchain

- [ ] The intended commit is pushed and selected by the Batal Al-Droob Xcode Cloud workflow.
- [ ] Xcode Cloud uses Xcode 26.6 (`17F113`) or a newer Apple-approved non-beta release.
- [ ] The iPhoneOS SDK is 26.5 or newer and `SDKROOT` is not pinned to a beta/old SDK.
- [ ] `python3 ios/BatalAlDroob/scripts/validate_release.py` passes.
- [ ] `swiftformat --lint --cache ignore ...` passes.
- [ ] `swiftlint lint --strict --no-cache --config ios/BatalAlDroob/.swiftlint.yml` passes.
- [ ] Xcode static analysis passes.

## Version And Build

- [ ] `MARKETING_VERSION` exactly matches the open App Store version.
- [ ] Xcode Cloud Next Build Number is greater than every prior upload.
- [ ] All targets have one matching marketing version and build number.
- [ ] The version train is open; no build is attached to a closed or released train.

## Build And Tests

- [ ] Dependency resolution succeeds.
- [ ] Debug build succeeds.
- [ ] Release build succeeds.
- [ ] Unit tests pass on a current iPhone simulator.
- [ ] UI smoke tests pass on supported iPhone and iPad layouts.
- [ ] Relevant tests pass on a physical iPhone.
- [ ] Location permission denied/granted behavior is manually checked.
- [ ] Compass and weather are manually checked on a physical device.
- [ ] StoreKit purchase, cancel, pending, failure, current entitlement, and restore are checked in Sandbox.
- [ ] VoiceOver, Accessibility Inspector, large Dynamic Type, Light/Dark, Reduce Motion, rotation, iPad Split View, and Stage Manager are manually checked.
- [ ] Instruments Leaks, Time Profiler, and Energy checks are completed for critical flows.

## Archive

- [ ] A fresh signed Xcode Cloud archive is created from the intended commit.
- [ ] `ci_post_xcodebuild.sh` passes against that archive.
- [ ] Archive metadata confirms bundle `com.batalaldroob.parts`, expected version/build, production Xcode, accepted SDK, and iOS 17.0 minimum.
- [ ] Every embedded bundle, if introduced later, matches the app version/build.
- [ ] The archive contains `PrivacyInfo.xcprivacy`.

## Privacy, Services, And Store Metadata

- [ ] App Store privacy labels are human-confirmed against actual collection, including precise location sent to Open-Meteo for weather.
- [ ] Production/commercial Open-Meteo terms are confirmed, or the service is replaced with an authorized provider.
- [ ] Location usage descriptions are accurate in Arabic and English.
- [ ] The StoreKit product `batal.catalog.unlock` is complete, cleared for sale where appropriate, and attached to the same first-review submission as the binary.
- [ ] The IAP review screenshot demonstrates the purchase surface.
- [ ] Promoted-IAP artwork represents the product and is not an ordinary app screenshot.
- [ ] 6.5-inch iPhone and 13-inch iPad screenshots show the current native app in use and its core functionality.
- [ ] Review notes accurately explain that no sign-in is required and purchases use Apple In-App Purchase only.
- [ ] Agreements, tax, banking, export compliance, content rights, and age rating are complete.

## Submission

- [ ] No unresolved App Review item remains in the selected submission.
- [ ] Only the newly validated build is selected.
- [ ] Release notes match implemented behavior.
- [ ] Submit only after explicit approval for the current release action.

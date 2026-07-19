# Batal Al-Droob Production Readiness Standard

This document is the permanent engineering reference for Batal Al-Droob. It applies to every implementation, review, migration, build, and release task in `ios/BatalAlDroob/`.

## Scope And Principles

- Work only on Batal Al-Droob unless the user explicitly changes scope.
- Prioritize correctness, stability, security, data integrity, maintainability, performance, user experience, then delivery speed.
- Preserve existing verified behavior, branding, workflows, public contracts, user data, bundle identity, signing, entitlements, and capabilities unless a change is explicitly authorized and necessary.
- Prefer native Swift, SwiftUI, Swift Concurrency, Foundation, StoreKit, MapKit, Core Location, WidgetKit, App Intents, and other Apple APIs over new third-party dependencies.
- Do not introduce placeholders, production mocks, unfinished controls, silent error handling, unsafe force unwraps, or warning suppressions.
- Never state that a check passed unless the corresponding command or manual verification actually passed.

## Discovery Gate

Before editing:

1. Inspect Git status and preserve unrelated user changes.
2. Read repository instructions, README files, release scripts, project settings, plist files, privacy manifests, localization, assets, tests, and CI configuration.
3. Inventory all app and test targets, schemes, dependencies, services, data stores, permissions, capabilities, and critical user flows.
4. Confirm whether any Flutter or Dart source/runtime remains. Remove it only after native feature parity is proven and removal is explicitly safe.
5. Establish a reproducible pre-change baseline with dependency resolution, Debug/Release builds, tests, and warnings recorded.

## Native Architecture Standard

- Use SwiftUI for application UI and a maintainable separation of views, observable state/view models, models, services, and platform adapters.
- Apply dependency injection at service boundaries so business logic can be tested without production services.
- Keep UI updates MainActor-safe; model asynchronous work with structured concurrency, cancellation, and Sendable-safe state.
- Avoid broad rewrites. Refactor incrementally and keep each change reviewable and reversible.
- Use `Logger` for structured diagnostics and never log credentials, tokens, purchase data, or personal information.

## Functional And UI Standard

- Every visible button, navigation link, sheet, alert, menu, toolbar item, gesture, and context action must have a real and verified behavior.
- Data-driven screens must handle initial, loading, loaded, empty, error, offline, retry, refreshing, and permission-denied states where applicable.
- Support Arabic RTL and English LTR, Dynamic Type, VoiceOver, sufficient contrast, Reduce Motion, Light/Dark Mode, and appropriate touch targets.
- Verify supported iPhone/iPad sizes, orientations, safe areas, keyboard behavior, Split View, and Stage Manager where the target supports them.
- Preserve user input on recoverable failures and prevent duplicate navigation, requests, submissions, and purchases.

## Services, Data, And Security Standard

- Validate network URLs, methods, status codes, decoding, timeouts, cancellation, offline behavior, caching, and bounded retries.
- Use HTTPS and narrow ATS exceptions. Keep sensitive values out of source control and store secrets/tokens in Keychain when applicable.
- Validate inputs and deep links; do not expose stack traces, secrets, or personally identifiable information.
- Preserve storage keys and schemas. Any migration must be backward-compatible, non-destructive, and covered by tests.
- External SDKs and APIs must use native iOS integrations, explicit configuration validation, test/sandbox modes, and documented manual requirements.
- StoreKit product identifiers, product types, entitlement semantics, restore behavior, and App Store Connect configuration must agree before release.

## Permissions, Capabilities, And Privacy

- Request only permissions used by real features and only at the point of need.
- Every requested permission needs accurate Arabic/English usage text.
- Keep `Info.plist`, entitlements, capabilities, signing, privacy manifest, and App Store privacy disclosures consistent with actual behavior.
- Do not change Bundle ID, Development Team, signing, certificates, profiles, entitlements, or capabilities without explicit authorization.
- Review Required Reason APIs and third-party privacy manifests without inventing declarations.

## Quality Gates

After each meaningful change, run the narrowest relevant test, then the broader suite. A release candidate must have evidence for all applicable gates:

1. Dependency resolution succeeds from the locked project state.
2. Debug and Release builds succeed with no new warnings.
3. Unit tests pass; changed critical logic has regression coverage.
4. UI/integration smoke tests cover launch and critical navigation when available.
5. Static analysis and existing lint/format checks pass.
6. A new Archive is generated from the intended commit and production Xcode, never reused.
7. Archive metadata is inspected for version, build, SDK, Xcode build, deployment target, bundle identifiers, and embedded targets.
8. A simulator smoke test passes. Device-only features remain explicitly unverified until tested on a physical device.
9. `git diff --check`, conflict-marker checks, secret scans, and final diff review pass.

Do not claim verification of Instruments, memory leaks, battery, camera, location, notifications, StoreKit production transactions, signing portals, or physical-device behavior unless those checks were actually performed in the proper environment.

## Release Gate

- Use only an Apple-approved non-beta Xcode/SDK for App Store archives.
- Keep marketing version and build number consistent across every embedded bundle and higher than any closed or previously used train/build.
- Xcode Cloud must fail early on a beta/unsupported toolchain or inconsistent release metadata.
- Do not upload or submit unless the user explicitly asks in the current turn.
- Before submission, verify screenshots represent the current UI, promoted IAP artwork represents the product rather than an app screenshot, privacy labels are human-confirmed, required IAPs are attached, and review notes accurately describe access and purchase behavior.

## Required Final Report

Every substantial production-readiness task must report:

- discovered architecture and baseline;
- defects and root causes;
- files and behavior changed;
- permissions, capabilities, entitlements, privacy, signing, and external services reviewed;
- exact commands and PASS/FAIL/BLOCKED results;
- critical flows verified and not verified;
- version/build/archive metadata;
- manual actions and external requirements;
- Git branch, commits, push status, and uncommitted changes;
- one honest status: `READY`, `READY_WITH_EXTERNAL_REQUIREMENTS`, or `NOT_READY`.

Production readiness means demonstrated evidence, not an assertion. Any missing credential, portal setting, physical-device test, App Store review action, or external service verification must remain visible as a blocker or manual requirement.

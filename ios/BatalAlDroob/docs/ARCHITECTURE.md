# Batal Al-Droob Architecture

## Product Boundary

Batal Al-Droob is a native iOS/iPadOS SwiftUI application for Nissan Patrol catalog lookup, fitment evidence, local request preparation, maintenance records, vehicle tools, location/compass assistance, and a StoreKit catalog unlock. The app target has no Flutter, Dart, CocoaPods, Swift Package Manager, or third-party runtime dependency.

## Targets

| Target | Purpose |
|---|---|
| `BatalAlDroob` | Native SwiftUI application |
| `BatalAlDroobTests` | Unit and bundled-resource regression tests |
| `BatalAlDroobUITests` | Arabic/English launch, navigation, persistence, and iPhone/iPad smoke tests |

There are no widgets, app clips, watch targets, share extensions, notification extensions, or embedded app extensions in the current project.

## Application Structure

- `AppDelegate.swift`: application entry point, dependency construction, lifecycle privacy shield.
- `AIModels.swift`: AI request/response DTOs with Sendable models for app/backend communication.
- `AIService.swift`: remote AI client plus local catalog fallback.
- `AIAssistantView.swift`: assistant tab UI, loading/error states, and suggestion presentation.
- `Models.swift`: catalog, store, vehicle, maintenance, request, and API data models.
- `Services.swift`: bundled-resource loading and StoreKit purchase service protocols/implementations.
- `CatalogViewModel.swift`: catalog/search/filter state, local persistence, request workflows, StoreKit state, and privacy-filtered AI context building.
- The app intentionally has no map, compass, or location-tracking module. Parts lookup, fitment,
  maintenance, and supplier handoff are the supported product scope.
- `Views.swift`: root tabs, dashboard, catalog, shared-fitment, and common state views.
- `PartDetailViews.swift`: part details and store-link presentation.
- `WorkflowViews.swift`: request and maintenance workflows.
- `MoreViews.swift`: vehicle profile, location/compass, tools, policies, and secondary flows.
- `Utilities.swift`: formatting, validation, persistence helpers, logging categories, and shared UI helpers.

Dependencies are injected at the application boundary through service protocols. UI-observable state is main-actor isolated, asynchronous work uses structured concurrency, and StoreKit transaction updates have a bounded lifecycle.

## Data And Persistence

- Catalog and support data are read-only bundled JSON under `BatalAlDroob/Web/data/`.
- Language, vehicle profile, maintenance entries, saved requests, wishlist, optional local customer profile, and entitlement cache use `UserDefaults` with stable keys.
- StoreKit current entitlements are the authority for paid access; cached values do not independently grant an entitlement.
- The optional customer name/email profile is device-local only, used for request personalization, and never treated as authentication or an owner unlock.
- No Core Data, SwiftData, SQLite, Realm, CloudKit, Firebase, or Supabase database is present.

## External Boundaries

### StoreKit

Product identifiers: `batal.catalog.single.unlock` for a one-page consumable catalog unlock, `batal.catalog.permanent.unlock` for the current full-catalog non-consumable entitlement, and `batal.catalog.full.unlock` as a legacy full-catalog non-consumable entitlement while active in App Store Connect. Product lookup, purchase, current-entitlement refresh, transaction updates, and restore are implemented with StoreKit 2. App Store Connect product state remains an external release requirement and the portal price tier is the source of truth for actual charged prices.

Locked catalog pages include Apple's official offer-code redemption sheet. Owner
access and promotional access must arrive as verified StoreKit transactions for
the approved non-consumable product, so the same entitlement path unlocks the
catalog whether the user purchased normally, restored a prior purchase, or
redeemed a free App Store Connect offer code.

### Location and compass

Location updates begin only after the user taps the tracking control and grants when-in-use permission. Updates stop when the user stops tracking or leaves the screen. The application has no developer-operated location backend and does not send coordinates to Open-Meteo or another weather provider.

### External Stores

Store links are opened only when the URL uses HTTPS and has a valid host. The app redirects users; it does not mirror vendor prices or inventory.

### AI Assistant

The AI boundary is optional and backend-mediated. The iOS app reads `AIAssistantBaseURL` and `AIAssistantClientToken` from `Info.plist`; when either value is absent, the assistant uses `LocalCatalogAssistantService` and sends no data off device. When enabled, `BatalRemoteAIService` posts only a minimized `AIAssistantRequest` to `/api/ai/chat`.

The backend in `ai-backend/` is a minimal Node service for controlled OpenAI access. It stores no API key in the mobile app, reads secrets from `.env.local`, requires a client token, validates payloads, applies in-memory rate limiting, redacts common secrets, sets `store: false` on Responses API requests, and returns structured errors. It is intentionally small so it can be replaced by a production service with stronger identity, App Attest, central rate limits, and observability.

The app must not send VIN, StoreKit transaction data, passwords, payment data, API keys, or full locked part numbers to the AI backend. AI answers must be treated as advisory: fitment and pricing remain subject to catalog evidence, unlock state, and App Store configuration.

## Permissions And Capabilities

Runtime permissions are limited to current feature needs:

- location while in use for on-screen map, tracking, and compass tools,
- camera for on-device OCR of part labels or stamped part numbers.

No background location, microphone, contacts, tracking, notifications, Bluetooth, HealthKit, or other permission is requested. Photo/camera recognition is local through Vision; it does not upload images to the AI backend.

No custom entitlement file or optional Apple capability is enabled. Signing remains automatic with the existing bundle identifier and development team.

## Release Architecture

Xcode Cloud executes repository-level guards:

- `ci_scripts/ci_post_clone.sh` verifies stable Xcode/SDK and consistent project version/build values.
- `ci_scripts/ci_post_xcodebuild.sh` reads the newly generated archive and verifies bundle/version/build/toolchain/SDK/deployment metadata for the app and any future embedded bundles.

The app must never be uploaded from an old archive or a beta Xcode build.

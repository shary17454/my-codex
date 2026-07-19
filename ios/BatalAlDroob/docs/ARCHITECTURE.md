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
- `Models.swift`: catalog, store, vehicle, maintenance, request, and API data models.
- `Services.swift`: bundled-resource loading and StoreKit purchase service protocols/implementations.
- `CatalogViewModel.swift`: catalog/search/filter state, local persistence, request workflows, StoreKit state.
- `LocationTrackingViewModel.swift`: Core Location and heading lifecycle.
- `Views.swift`: root tabs, dashboard, catalog, shared-fitment, and common state views.
- `PartDetailViews.swift`: part details and store-link presentation.
- `WorkflowViews.swift`: request and maintenance workflows.
- `MoreViews.swift`: vehicle profile, location/compass, tools, policies, and secondary flows.
- `Utilities.swift`: formatting, validation, persistence helpers, logging categories, and shared UI helpers.

Dependencies are injected at the application boundary through service protocols. UI-observable state is main-actor isolated, asynchronous work uses structured concurrency, and StoreKit transaction updates have a bounded lifecycle.

## Data And Persistence

- Catalog and support data are read-only bundled JSON under `BatalAlDroob/Web/data/`.
- Language, vehicle profile, maintenance entries, saved requests, wishlist, and entitlement cache use `UserDefaults` with stable keys.
- StoreKit current entitlements are the authority for paid access; cached values do not independently grant an entitlement.
- No Core Data, SwiftData, SQLite, Realm, CloudKit, Firebase, or Supabase database is present.

## External Boundaries

### StoreKit

Product identifier: `batal.catalog.permanent.unlock`. It must be configured as a non-consumable because the entitlement is permanent and restorable. Product lookup, purchase, current-entitlement refresh, transaction updates, and restore are implemented with StoreKit 2. App Store Connect product state remains an external release requirement.

### Location and compass

Location updates begin only after the user taps the tracking control and grants when-in-use permission. Updates stop when the user stops tracking or leaves the screen. The application has no developer-operated location backend and does not send coordinates to Open-Meteo or another weather provider.

### External Stores

Store links are opened only when the URL uses HTTPS and has a valid host. The app redirects users; it does not mirror vendor prices or inventory.

## Permissions And Capabilities

The only runtime permission requested is location while in use. It supports the on-screen map, tracking, and compass tools. No background location, camera, microphone, photos, contacts, tracking, notifications, Bluetooth, HealthKit, or other permission is requested.

No custom entitlement file or optional Apple capability is enabled. Signing remains automatic with the existing bundle identifier and development team.

## Release Architecture

Xcode Cloud executes repository-level guards:

- `ci_scripts/ci_post_clone.sh` verifies stable Xcode/SDK and consistent project version/build values.
- `ci_scripts/ci_post_xcodebuild.sh` reads the newly generated archive and verifies bundle/version/build/toolchain/SDK/deployment metadata for the app and any future embedded bundles.

The app must never be uploaded from an old archive or a beta Xcode build.

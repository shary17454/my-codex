# الموسوعه الهندسية لتطوير تطبيقات ابل

Permanent engineering standard for this project.

Version: 1.1  
Effective date: 2026-07-21  
Owner: Project engineering leadership  
Applies to: iOS, iPadOS, macOS, watchOS, tvOS, visionOS, shared Apple-platform libraries, backend-adjacent client services, test automation, release operations, and all Codex-assisted development in this repository.

Version history:

- **1.0**: Initial engineering constitution, Apple application standards, Codex rules, release practices, and core checklists.
- **1.1**: Enterprise expansion covering product engineering, design system governance, motion design, component library standards, advanced Swift and AI engineering, enterprise security, performance, testing, App Store operations, decision trees, anti-patterns, reference implementations, future compatibility, and the expanded Codex Constitution.

---

## 0. Authority, Scope, and Enforcement

This manual is the engineering constitution for this project. It defines how premium Apple applications in this repository must be conceived, designed, implemented, tested, secured, optimized, reviewed, released, and maintained.

When project-specific instructions conflict with this manual, the stricter production-quality rule wins unless a human maintainer explicitly instructs otherwise in writing. Temporary exceptions must be documented with the reason, owner, expiration condition, and follow-up task.

### 0.1 Mandatory Language

The words below have precise meanings:

- **Must**: Required for production work.
- **Should**: Strong default. Deviations require a documented reason.
- **May**: Allowed when it improves the product without violating stricter rules.
- **Never**: Prohibited unless an explicit project owner exception exists.

### 0.2 Definition of Done

No feature, screen, bug fix, refactor, release, or Codex task is done until all applicable items are true:

- The user-facing behavior is complete, coherent, and verified.
- All interactive controls work or are intentionally disabled with clear state.
- Empty, loading, success, error, offline, unauthorized, and edge states are handled.
- UI follows Apple Human Interface Guidelines and the local design system.
- Accessibility, localization, Dynamic Type, dark mode, and RTL impact are considered and tested where applicable.
- The architecture follows this manual and does not introduce avoidable coupling.
- Tests cover the meaningful behavior and likely regressions.
- Security, privacy, performance, and data handling implications are reviewed.
- Logs and analytics are useful without exposing private data.
- The implementation can be maintained by another senior engineer.
- Documentation, comments, and decision records are updated when needed.

### 0.3 Engineering North Star

Build applications that feel native, fast, trustworthy, accessible, private, resilient, and inevitable. A premium Apple app should not merely run on Apple platforms; it should belong there.

---

## 1. Product Philosophy

### 1.1 Product Principles

Every product decision must satisfy these principles:

- **Human value first**: Solve a real user problem with less cognitive load than the alternatives.
- **Native excellence**: Prefer platform conventions, system controls, system services, and Apple interaction models.
- **Clarity over cleverness**: Users should understand what they can do, what happened, and what happens next.
- **Trust by design**: Privacy, security, reliability, and honest communication are product features.
- **Performance is UX**: Latency, stutter, battery drain, memory pressure, and launch delay are user-facing defects.
- **Accessibility is baseline**: Accessibility is not an enhancement; it is part of correctness.
- **Maintainability protects velocity**: Code quality is a product investment, not a cosmetic preference.

### 1.2 Product Vision Template

Every substantial initiative must be anchored by a concise product vision:

```text
For [target user],
who needs [job/problem],
the product provides [capability],
unlike [current alternative],
because [distinct advantage],
measured by [user outcome and business metric].
```

### 1.3 Product Lifecycle

Product work moves through the following lifecycle:

1. **Discovery**: Validate the user problem, audience, constraints, and success criteria.
2. **Definition**: Produce requirements, user stories, non-goals, risks, and acceptance criteria.
3. **Design**: Create flows, information architecture, states, accessibility behavior, and visual treatment.
4. **Architecture**: Choose module boundaries, data flow, dependency strategy, persistence, security model, and test approach.
5. **Implementation**: Build incrementally behind clear interfaces.
6. **Verification**: Test functional behavior, UI, accessibility, performance, security, privacy, and release readiness.
7. **Release**: Ship through controlled channels with observability and rollback strategy.
8. **Learning**: Review metrics, feedback, crashes, support issues, and technical debt.
9. **Iteration**: Refine, refactor, optimize, and retire obsolete paths.

### 1.4 Product Management Requirements

Each feature must include:

- Problem statement.
- Target audience.
- Primary user journey.
- Acceptance criteria.
- Non-goals.
- Data and privacy classification.
- Offline expectations.
- Accessibility expectations.
- Localization expectations.
- Rollout and rollback plan for risky changes.
- Success metrics and guardrails.

### 1.5 Product Decision Tree

```text
Is the user problem validated?
  No -> Run discovery before implementation.
  Yes -> Is the feature aligned with product vision?
    No -> Reject or reframe.
    Yes -> Can it be implemented with native platform conventions?
      No -> Document why custom behavior is necessary.
      Yes -> Use native conventions.
    Does it require sensitive data?
      Yes -> Minimize data, request permission just-in-time, document retention.
      No -> Continue.
    Can it fail or be offline?
      Yes -> Design failure and offline states before coding.
      No -> Continue.
    Is success measurable?
      No -> Define qualitative or quantitative signals.
      Yes -> Implement with analytics discipline.
```

---

## 2. User Experience Standards

### 2.1 UX Principles

The application must be:

- **Understandable**: The next useful action is obvious.
- **Predictable**: Controls behave according to platform expectations.
- **Forgiving**: Destructive actions require clear confirmation or undo.
- **Efficient**: Frequent workflows minimize taps, typing, waiting, and context switching.
- **Stateful**: The app remembers appropriate user context without surprising them.
- **Transparent**: Progress, failure, permissions, sync, and data freshness are visible when relevant.

### 2.2 Required User States

Every screen with remote, persistent, or computed data must define:

- Initial state.
- Loading state.
- Loaded state.
- Empty state.
- Error state.
- Offline state.
- Permission-denied state when applicable.
- Partial-data state when applicable.
- Refreshing state when applicable.

### 2.3 Flow Quality Checklist

- Can a new user complete the primary task without instructions?
- Can a returning user complete it quickly?
- Does every screen have one dominant purpose?
- Are destructive actions reversible or confirmed?
- Are system permissions requested at the moment of clear user intent?
- Does the app avoid blocking the entire screen for local work that can happen inline?
- Does the app preserve user input across transient failures?
- Are errors written in plain human language with recovery actions?
- Are empty states useful, not decorative filler?

### 2.4 UX Anti-Patterns

Never ship:

- Dead-end screens.
- Buttons that do nothing.
- Spinners without timeout or recovery.
- Empty states that blame the user.
- Alerts for routine information that could be inline.
- Permission prompts before the value is clear.
- Navigation that changes structure unpredictably.
- Hidden critical actions without an accessible alternative.
- Custom gestures with no visible affordance.
- Marketing copy inside operational app workflows.

---

## 3. Apple Human Interface Standards

### 3.1 Platform Fidelity

The app must respect Apple platform conventions:

- Use system navigation structures unless a product-specific reason justifies custom navigation.
- Use SF Symbols for common iconography.
- Use system colors and semantic materials where appropriate.
- Support Dynamic Type.
- Support VoiceOver.
- Support dark mode.
- Support Reduce Motion and other accessibility settings.
- Use platform-appropriate input conventions: touch on iOS, pointer and keyboard on iPadOS/macOS, remote on tvOS, Digital Crown on watchOS, spatial input on visionOS.

### 3.2 HIG Decision Rules

- If Apple provides a native control that matches the job, use it.
- If the design deviates from platform convention, document the user benefit.
- If a custom control is built, it must support accessibility, focus, keyboard navigation where applicable, state restoration where applicable, and testing.
- If an interaction cannot be explained by visual hierarchy and platform convention, redesign it.

### 3.3 Layout

Layouts must be stable, adaptive, and readable:

- Use safe areas.
- Avoid hard-coded device-specific dimensions.
- Use semantic spacing tokens.
- Preserve readable line length.
- Avoid overlapping content at all Dynamic Type sizes.
- Respect split view, Stage Manager, rotation, and multitasking where applicable.
- Use adaptive presentations rather than assuming one screen size.

### 3.4 Navigation

Navigation must reflect task structure:

- Use tab navigation for peer top-level areas.
- Use stack navigation for drill-down hierarchy.
- Use sheets for focused tasks that can be dismissed.
- Use full-screen covers sparingly for immersive or required flows.
- Use inspectors or sidebars on larger surfaces when they improve scanning and comparison.
- Preserve user position when returning from details.

### 3.5 Buttons

Buttons must:

- Clearly express their action with label, icon, or both.
- Use destructive roles for destructive actions.
- Have disabled states when action is unavailable.
- Show progress for long-running actions.
- Prevent duplicate submissions.
- Meet minimum hit target expectations.
- Expose accessibility labels and hints when the visible label is insufficient.

Anti-patterns:

- Multiple primary buttons competing in one view.
- Icon-only buttons without accessibility labels.
- Buttons implemented as arbitrary tap gestures on text unless semantically correct.
- Controls with visual affordance but no action.

### 3.6 Cards

Cards may be used for repeated items or framed content groups. They must not become the default layout for every section.

Card standards:

- Use concise content hierarchy.
- Entire card tap targets must not conflict with internal controls.
- Avoid nested cards.
- Use consistent corner radius and elevation/material.
- Support selected, focused, disabled, loading, and error states where relevant.

### 3.7 Forms

Forms must:

- Use native input controls.
- Validate as close to the field as possible.
- Preserve user input after errors.
- Support keyboard type, content type, autocorrection, capitalization, secure text entry, and submit behavior.
- Clearly mark required fields.
- Avoid excessive up-front fields.
- Support password managers where credentials are involved.

### 3.8 Lists

Lists must:

- Support loading, empty, refresh, error, and pagination states.
- Preserve scroll position when practical.
- Use stable identifiers.
- Avoid expensive per-row computation.
- Provide swipe actions only for common, safe actions.
- Confirm destructive swipe actions or provide undo.

### 3.9 Search

Search must:

- Be responsive and cancellable.
- Debounce remote queries.
- Display recent searches or suggestions only when useful.
- Handle no-results states.
- Respect privacy for search history.
- Distinguish local filtering from remote search when user expectations differ.

### 3.10 Motion Design

Motion must clarify state changes:

- Use system transitions when possible.
- Keep animations short and purposeful.
- Respect Reduce Motion.
- Avoid animation that blocks user interaction unnecessarily.
- Avoid layout shifts that make content hard to track.

---

## 4. Design System

### 4.1 Design Tokens

The design system must define:

- Color tokens.
- Typography tokens.
- Spacing tokens.
- Corner radius tokens.
- Stroke and separator tokens.
- Shadow or material tokens where appropriate.
- Icon sizing rules.
- Component states.

Tokens must be semantic, not merely visual.

Good:

```swift
Color.accentColor
Color("SurfaceBackground")
Color("CriticalText")
```

Bad:

```swift
Color("BlueButton")
Color(red: 0.1, green: 0.2, blue: 0.8)
```

### 4.2 Typography

Typography must:

- Use system text styles where possible.
- Support Dynamic Type.
- Maintain readable hierarchy.
- Avoid fixed font sizes for body content.
- Avoid negative letter spacing.
- Avoid truncating essential information without a way to inspect it.

Recommended SwiftUI pattern:

```swift
Text(viewModel.title)
    .font(.headline)
    .foregroundStyle(.primary)
    .lineLimit(2)
    .accessibilityAddTraits(.isHeader)
```

### 4.3 Color

Color must:

- Meet contrast requirements.
- Work in light and dark mode.
- Use semantic meaning consistently.
- Avoid relying on color alone to communicate state.
- Avoid broad single-hue visual systems that reduce information clarity.

### 4.4 Components

Reusable components must:

- Encapsulate behavior and visual states.
- Accept semantic data, not unrelated formatting flags.
- Expose accessibility behavior.
- Be previewed in common states.
- Be tested when they contain logic.

Component state checklist:

- Default.
- Highlighted or pressed.
- Focused.
- Selected.
- Disabled.
- Loading.
- Error.
- Empty.
- Offline if applicable.

### 4.5 Design Review Checklist

- Does the screen look native to its platform?
- Is the hierarchy obvious in five seconds?
- Does the primary action stand out?
- Are labels concrete and action-oriented?
- Does the layout survive long text?
- Does it support Dynamic Type?
- Does it support dark mode?
- Does it support RTL?
- Are touch targets large enough?
- Does it avoid unnecessary decoration?

---

## 5. Accessibility, Localization, and Inclusion

### 5.1 Accessibility Standards

Accessibility is required for production. The app must support:

- VoiceOver labels, values, hints, traits, and actions.
- Dynamic Type.
- Sufficient color contrast.
- Reduce Motion.
- Increase Contrast where applicable.
- Differentiate Without Color.
- Button Shapes where applicable.
- Voice Control where applicable.
- Switch Control where applicable.
- Keyboard navigation on iPadOS/macOS.

### 5.2 Accessibility Implementation

Good:

```swift
Button {
    viewModel.retry()
} label: {
    Label("Retry", systemImage: "arrow.clockwise")
}
.accessibilityHint("Attempts to load the latest data again.")
```

Avoid:

```swift
Image(systemName: "arrow.clockwise")
    .onTapGesture { viewModel.retry() }
```

### 5.3 Dynamic Type Rules

- Body content must use scalable text styles.
- Fixed-height containers containing text are prohibited unless tested at large accessibility sizes.
- Controls must grow or wrap rather than clip.
- Important labels must not be hidden only because text grows.

### 5.4 Localization

All user-facing strings must be localizable unless explicitly internal-only.

Rules:

- Use string catalogs or localization files.
- Avoid string concatenation for sentences.
- Support pluralization.
- Support locale-aware dates, times, numbers, currencies, measurements, and calendars.
- Avoid embedding layout assumptions into strings.
- Provide translator comments for ambiguous strings.

Good:

```swift
Text("profile.tasks.remaining \(remainingCount)")
```

Bad:

```swift
Text("You have " + count.description + " tasks left")
```

### 5.5 RTL Support

The app must support right-to-left languages unless the product explicitly does not localize beyond LTR languages.

RTL rules:

- Prefer leading/trailing over left/right.
- Use system mirroring.
- Review directional icons.
- Avoid embedding arrows in text.
- Test navigation, forms, charts, and custom layouts in RTL.

---

## 6. Swift Engineering Standards

### 6.1 Swift Principles

Swift code must be:

- Clear.
- Type-safe.
- Value-oriented where appropriate.
- Concurrency-safe.
- Testable.
- Minimal in global state.
- Explicit about failure.
- Explicit about ownership and isolation.

### 6.2 Naming

Names must describe intent, not implementation trivia.

Rules:

- Types: `UpperCamelCase`.
- Functions, variables, properties: `lowerCamelCase`.
- Boolean names read as predicates: `isLoading`, `hasPermission`, `canSubmit`.
- Avoid abbreviations unless standard: `URL`, `ID`, `HTML`.
- Avoid vague names: `manager`, `helper`, `data`, `thing`.
- Protocols describe capability: `UserSessionProviding`, `ImageCaching`, `OrderRepository`.

### 6.3 File Organization

Recommended feature-first layout:

```text
App/
  AppEntry.swift
  AppEnvironment.swift
Features/
  Profile/
    ProfileView.swift
    ProfileViewModel.swift
    ProfileModels.swift
    ProfileRepository.swift
    ProfileService.swift
    ProfileTests.swift
Core/
  Networking/
  Persistence/
  Security/
  Analytics/
  DesignSystem/
Shared/
  Extensions/
  Utilities/
```

Rules:

- Keep files focused.
- Avoid massive shared utility files.
- Keep feature-private types near the feature.
- Promote shared code only after real reuse or stable ownership is clear.

### 6.4 API Design

Public and module-facing APIs must:

- Make invalid states hard to represent.
- Use domain-specific types.
- Prefer throwing functions for recoverable failures.
- Prefer `Result` only when failure is stored or passed as data.
- Avoid Boolean parameter traps.
- Avoid optional return values when absence has multiple meanings.

Bad:

```swift
func update(user: User, force: Bool, notify: Bool)
```

Better:

```swift
struct UserUpdateOptions: Sendable {
    var conflictPolicy: ConflictPolicy
    var notificationPolicy: NotificationPolicy
}

func update(_ user: User, options: UserUpdateOptions) async throws
```

### 6.5 Error Handling

Errors must be modeled and recoverable:

```swift
enum ProfileError: Error, Equatable {
    case unauthorized
    case offline
    case notFound
    case server(message: String?)
}
```

Rules:

- Never silently swallow errors.
- Never show raw technical errors to users.
- Log diagnostic details privately and safely.
- Map errors to user-facing recovery states.
- Preserve the original error context where useful.

### 6.6 Optionals

Rules:

- Avoid force unwraps in production code.
- Use `guard` for required preconditions.
- Use optional chaining only when absence is acceptable.
- Model domain absence explicitly when it matters.

### 6.7 Value Semantics

Prefer structs for immutable domain data:

```swift
struct AccountSummary: Identifiable, Equatable, Sendable {
    let id: Account.ID
    let displayName: String
    let balance: Decimal
}
```

Use classes for identity, shared mutable state, reference semantics, Objective-C interoperability, or framework requirements.

---

## 7. SwiftUI Standards

### 7.1 SwiftUI Principles

SwiftUI views must be:

- Declarative.
- Small enough to reason about.
- State-driven.
- Previewable.
- Accessible.
- Free of heavy business logic.

### 7.2 View Composition

Rules:

- Keep view body readable.
- Extract subviews when a section has independent meaning.
- Avoid extracting every small line into meaningless components.
- Avoid business logic in views.
- Use view models or domain models for formatting that is not purely presentational.

### 7.3 State Ownership

Use the narrowest correct state owner:

- `@State`: Local view state.
- `@Binding`: Parent-owned mutable state.
- `@Environment`: Cross-cutting dependencies or values.
- `@Observable`: Observable models using modern Observation.
- `@StateObject`/`@ObservedObject`: Existing ObservableObject patterns where needed.

Decision tree:

```text
Is the state local and disposable?
  Yes -> @State
Is the state owned by a parent?
  Yes -> @Binding
Is the state shared app-wide or injected?
  Yes -> @Environment or dependency container
Does the state drive a feature and survive view re-rendering?
  Yes -> @State with @Observable model or @StateObject depending on architecture
```

### 7.4 Observation

Use the modern Observation framework for new SwiftUI state models when deployment targets allow it.

```swift
@MainActor
@Observable
final class ProfileViewModel {
    private let repository: ProfileRepository

    var state: LoadableState<Profile> = .idle

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await repository.profile())
        } catch {
            state = .failed(ProfileErrorMapper.map(error))
        }
    }
}
```

Rules:

- UI-facing observable models must usually be `@MainActor`.
- Do not expose mutable state unnecessarily.
- Keep async work cancellable.
- Avoid retaining tasks without a lifecycle strategy.

### 7.5 Previews

Every reusable view and substantial screen should provide previews:

- Loaded.
- Loading.
- Empty.
- Error.
- Dark mode.
- Dynamic Type.
- RTL where practical.

```swift
#Preview("Error") {
    ProfileView(viewModel: .preview(state: .failed(.offline)))
}
```

### 7.6 SwiftUI Anti-Patterns

Never ship:

- Network calls directly in a `View` body.
- Heavy computation in computed view properties.
- Gesture-only controls where `Button` is appropriate.
- Layouts that depend on a single device size.
- Hard-coded text colors that break dark mode.
- Unbounded `Task` creation from frequent view updates.
- `AnyView` as a default abstraction tool.

---

## 8. UIKit, AppKit, and Interoperability

### 8.1 UIKit/AppKit Role

Use UIKit or AppKit when:

- A required control is not mature in SwiftUI.
- Existing code and risk make incremental migration appropriate.
- Fine-grained text, collection, focus, or window behavior is required.
- Platform-specific integration requires it.

### 8.2 Interop Rules

- Keep bridging code isolated.
- Wrap UIKit/AppKit components in small representable types.
- Keep coordinators focused.
- Avoid leaking UIKit/AppKit lifecycle assumptions into SwiftUI features.
- Test memory ownership and delegate cycles.

### 8.3 UIKit/AppKit Quality

- Use Auto Layout or modern layout APIs correctly.
- Avoid frame math unless justified and tested.
- Keep view controllers slim.
- Use diffable data sources where appropriate.
- Handle trait collection changes.
- Support accessibility and dynamic type.

---

## 9. Architecture

### 9.1 Architectural Goals

Architecture must support:

- Independent feature development.
- Testability.
- Clear dependency direction.
- Offline resilience.
- Security and privacy boundaries.
- Performance.
- Gradual refactoring.
- Platform evolution.

### 9.2 Recommended Layering

```text
Presentation
  SwiftUI views, UIKit/AppKit views, view models, navigation state
Domain
  Entities, use cases, policies, validation, business rules
Data
  Repositories, services, persistence, cache, network clients
Infrastructure
  HTTP, database, keychain, analytics, logging, system adapters
```

Dependency direction:

```text
Presentation -> Domain -> Data -> Infrastructure
```

Higher-level layers may depend on abstractions. Lower-level layers must not depend on feature UI.

### 9.3 MVVM

MVVM is acceptable when kept disciplined:

- Views render state and forward intent.
- View models coordinate presentation state and use cases.
- Domain logic does not live in views.
- View models do not become service containers.
- Repositories hide data source details.

### 9.4 Dependency Injection

Dependencies must be explicit.

Preferred:

```swift
struct AppEnvironment {
    let profileRepository: ProfileRepository
    let analytics: AnalyticsClient
    let clock: any Clock<Duration>
}
```

Avoid:

```swift
ProfileService.shared.fetch()
```

Rules:

- Use initializer injection for required dependencies.
- Use environment injection for app-wide SwiftUI dependencies.
- Avoid hidden singletons.
- Provide test doubles.
- Keep dependency containers small and structured.

### 9.5 Repository Pattern

Repositories own data access decisions:

```swift
protocol ProfileRepository: Sendable {
    func profile() async throws -> Profile
    func refreshProfile() async throws -> Profile
    func updateProfile(_ draft: ProfileDraft) async throws -> Profile
}
```

Rules:

- Repositories expose domain models or DTO-to-domain mapping boundaries.
- Network details do not leak to views.
- Persistence details do not leak to view models.
- Caching policy is explicit.

### 9.6 Services

Services should be narrow and capability-based:

- `HTTPClient`
- `ImagePipeline`
- `KeychainStore`
- `AnalyticsClient`
- `FeatureFlagClient`

Avoid broad `AppService`, `DataManager`, or `UtilityManager` abstractions.

### 9.7 Modularization

Modularize when it reduces coupling or build cost.

Module candidates:

- Design system.
- Networking.
- Persistence.
- Security.
- Analytics.
- Feature modules with independent ownership.
- Test support.

Rules:

- Modules must have clear public APIs.
- Avoid circular dependencies.
- Keep internal implementation hidden.
- Do not over-modularize early.

### 9.8 Architectural Decision Records

Significant decisions must be documented:

```text
# ADR: Use SwiftData for local user-created content
Status: Accepted
Date: 2026-07-21
Context:
Decision:
Consequences:
Alternatives considered:
Review trigger:
```

---

## 10. Swift Concurrency

### 10.1 Core Rules

- Use `async`/`await` for asynchronous work.
- Use structured concurrency by default.
- Use actors for isolated mutable state.
- Use `Sendable` for values crossing concurrency boundaries.
- Mark UI-facing models `@MainActor`.
- Avoid detached tasks unless isolation and cancellation are explicitly designed.

### 10.2 Task Lifecycle

Rules:

- Tasks started by a view must be cancellable with the view lifecycle.
- Long-running tasks must report progress or state.
- Repeated user actions must cancel or coalesce previous work when appropriate.
- Do not retain `Task` handles without cancellation in `deinit`, lifecycle hooks, or owner transitions.

### 10.3 Actors

Use actors for shared mutable state:

```swift
actor TokenRefreshCoordinator {
    private var refreshTask: Task<AuthToken, Error>?

    func validToken(using provider: AuthTokenProvider) async throws -> AuthToken {
        if let refreshTask {
            return try await refreshTask.value
        }

        let task = Task { try await provider.refreshToken() }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }
}
```

### 10.4 Sendable

Rules:

- Domain values crossing tasks should conform to `Sendable`.
- Avoid unchecked `Sendable` unless reviewed and documented.
- Reference types marked `Sendable` must be immutable or internally synchronized.

### 10.5 Concurrency Anti-Patterns

Never:

- Update UI from a non-main actor.
- Use `DispatchQueue.main.async` to hide isolation design problems.
- Spawn unbounded tasks in loops.
- Ignore cancellation.
- Share mutable non-Sendable state across actors.
- Block async contexts with semaphores or synchronous waits.

---

## 11. Networking

### 11.1 Networking Principles

Networking must be reliable, secure, observable, and testable.

Rules:

- Use `URLSession` or a reviewed network client abstraction.
- Use HTTPS.
- Validate status codes.
- Decode with explicit models.
- Support cancellation.
- Use timeouts.
- Retry only idempotent or explicitly safe operations.
- Avoid logging sensitive payloads.

### 11.2 HTTP Client Contract

```swift
protocol HTTPClient: Sendable {
    func send<Request: APIRequest>(_ request: Request) async throws -> Request.Response
}

protocol APIRequest {
    associatedtype Response: Decodable & Sendable
    var method: HTTPMethod { get }
    var path: String { get }
    var query: [URLQueryItem] { get }
    var body: Data? { get }
}
```

### 11.3 Error Mapping

Network errors must map to domain errors:

- No connection -> offline state.
- Timeout -> retryable temporary state.
- 401/403 -> authentication or authorization state.
- 404 -> not found where relevant.
- 409 -> conflict resolution.
- 429 -> rate limit and retry guidance.
- 5xx -> service unavailable.

### 11.4 Offline Support

Offline behavior must be designed explicitly:

- Read-only cached mode.
- Draft mode with later sync.
- Full offline-first mode.
- No offline support, with clear user messaging.

Offline checklist:

- What data is available offline?
- How fresh is cached data?
- Can users create or edit offline?
- How are conflicts detected?
- How are conflicts resolved?
- What is shown when sync fails?
- Are queued operations encrypted if sensitive?

### 11.5 Caching

Caching policy must define:

- Source of truth.
- Time-to-live.
- Invalidation triggers.
- Storage location.
- Privacy classification.
- Eviction strategy.
- Offline behavior.

Never cache sensitive data without documented need, protection class, and retention policy.

---

## 12. Persistence and Data

### 12.1 Persistence Decision Tree

```text
Is the data small, user preference-like, and non-sensitive?
  Yes -> UserDefaults or AppStorage
Is it secret or credential-like?
  Yes -> Keychain
Is it structured app data with relationships?
  Yes -> SwiftData or Core Data
Is it large binary data?
  Yes -> File storage with metadata database
Is it cacheable remote data?
  Yes -> Cache layer with explicit invalidation and privacy policy
```

### 12.2 SwiftData

Use SwiftData for modern local persistence when deployment targets and data complexity fit.

Rules:

- Keep models focused.
- Plan migrations before shipping schema changes.
- Avoid storing secrets.
- Keep persistence operations off the critical UI path.
- Test model migrations.
- Avoid coupling SwiftData models directly to all domain logic when portability matters.

### 12.3 Core Data

Use Core Data when:

- Existing app data already uses it.
- Advanced migration, large datasets, or mature operational behavior is required.
- Deployment constraints make SwiftData unsuitable.

Rules:

- Use background contexts for heavy work.
- Save intentionally.
- Handle merge policies.
- Test migrations.
- Avoid passing managed objects across concurrency boundaries incorrectly.

### 12.4 Database Quality

- Define indexes for common queries.
- Avoid unbounded fetches.
- Batch work when practical.
- Keep migrations reversible during development.
- Add data repair scripts for known corruption modes.
- Test with realistic data volume.

---

## 13. Security

### 13.1 Security Principles

Security is a product invariant. The app must:

- Minimize collected data.
- Protect secrets.
- Use least privilege.
- Fail safely.
- Avoid exposing sensitive data in logs, analytics, screenshots, backups, or crash reports.
- Use platform security APIs.

### 13.2 Keychain

Store credentials, tokens, private keys, and high-value secrets in Keychain.

Rules:

- Use appropriate accessibility class.
- Prefer access control requiring user presence for high-risk secrets.
- Do not store secrets in `UserDefaults`, plist files, source code, logs, or analytics.
- Handle Keychain errors explicitly.
- Document migration and deletion behavior.

### 13.3 Biometrics

Biometrics must:

- Be optional unless required by security policy.
- Use LocalAuthentication.
- Provide passcode fallback where appropriate.
- Explain why authentication is requested.
- Handle unavailable, changed, failed, and canceled states.

### 13.4 Encryption

Rules:

- Use CryptoKit or vetted platform APIs.
- Never invent cryptography.
- Use authenticated encryption.
- Protect keys separately from encrypted data.
- Rotate keys when policy requires it.
- Document threat model and recovery behavior.

### 13.5 App Transport Security

- ATS must remain enabled.
- Exceptions require documented justification, limited domains, and review.
- Certificate pinning must be used only when operational rotation risk is understood.

### 13.6 Secure Coding Checklist

- No hard-coded secrets.
- No sensitive data in logs.
- No sensitive data in screenshots unless protected.
- No unvalidated URL opening.
- No unsafe file path handling.
- No insecure random number generation.
- No broad pasteboard use for sensitive data.
- No unnecessary background access.
- No permission request without clear user benefit.

---

## 14. Privacy

### 14.1 Privacy Principles

Privacy must be designed, not patched.

Rules:

- Collect the minimum data needed.
- Explain data use in plain language.
- Request permission just in time.
- Respect denial.
- Provide deletion or reset where appropriate.
- Avoid third-party SDKs unless reviewed.
- Keep privacy nutrition labels accurate.
- Keep tracking behavior compliant with App Tracking Transparency.

### 14.2 Data Classification

Every stored or transmitted data type must be classified:

- Public.
- Internal.
- User personal data.
- Sensitive personal data.
- Credential or secret.
- Regulated data.

Classification determines storage, logging, retention, analytics, backup, and access rules.

### 14.3 Permission Prompts

Permission prompts must be:

- Triggered by user intent.
- Preceded by contextual explanation only when useful.
- Specific about value.
- Resilient to denial.

Never block the whole product behind unrelated permissions.

---

## 15. Apple Intelligence and AI Features

### 15.1 AI Product Rules

AI features must:

- Provide clear user value.
- Be transparent about generated or inferred output.
- Allow review before irreversible action.
- Avoid fabricating facts into authoritative workflows.
- Protect private data.
- Respect platform and App Store policies.
- Provide graceful fallback when AI is unavailable.

### 15.2 Apple Intelligence Integration

When using Apple Intelligence APIs or system-provided intelligence features:

- Prefer on-device and system-mediated capabilities when they satisfy the use case.
- Follow Apple availability checks.
- Respect user settings and permissions.
- Keep generated content editable where appropriate.
- Do not imply capabilities unavailable on the device.
- Provide non-AI alternatives for critical workflows.

### 15.3 AI Safety Checklist

- What data is sent, stored, or inferred?
- Can the user inspect and correct output?
- What happens when the model is wrong?
- Are harmful, private, or regulated outputs possible?
- Are prompts or logs exposing secrets?
- Is behavior tested with adversarial, multilingual, and accessibility cases?

---

## 16. Performance Engineering

### 16.1 Performance Budgets

Each app should define measurable budgets:

- Cold launch time.
- Warm launch time.
- Time to first meaningful content.
- Scroll frame stability.
- Memory ceiling for common workflows.
- Network payload size.
- Battery impact for background work.
- Database query latency.
- Build time for developer workflows.

### 16.2 Launch Performance

Rules:

- Defer non-critical work.
- Avoid synchronous disk or network work on launch.
- Initialize heavy services lazily.
- Keep dependency containers cheap.
- Measure launch with Instruments and Xcode metrics.

### 16.3 Memory

Rules:

- Avoid retain cycles.
- Use weak delegates.
- Cancel tasks when owners deallocate.
- Downsample large images.
- Avoid caching without bounds.
- Test memory warnings.
- Use Instruments for leaks and allocations.

### 16.4 CPU

Rules:

- Move expensive work off the main actor.
- Avoid repeated formatting in list rows.
- Cache derived values when valid.
- Batch database and network work.
- Use algorithms appropriate for realistic data size.

### 16.5 GPU and Rendering

Rules:

- Avoid excessive blur, shadows, transparency, and overdraw.
- Avoid unnecessary offscreen rendering.
- Keep animations lightweight.
- Profile scroll and animation hitches.
- Use image sizes appropriate to display scale.

### 16.6 Battery

Rules:

- Avoid unnecessary background work.
- Batch network calls.
- Respect Low Power Mode.
- Use background tasks responsibly.
- Stop sensors, location, timers, and streams when not needed.

### 16.7 Image Optimization

- Use asset catalogs.
- Provide correct scale variants.
- Prefer vector SF Symbols for standard icons.
- Downsample large remote images.
- Cache decoded images carefully.
- Avoid loading full-resolution images into list cells.

---

## 17. Build and Xcode Standards

### 17.1 Xcode Project Hygiene

Rules:

- Keep targets purposeful.
- Keep build settings consistent and documented.
- Avoid unnecessary script phases.
- Ensure generated files are deterministic.
- Keep schemes shared when needed by CI.
- Treat warnings as problems.

### 17.2 Build Optimization

- Modularize high-churn areas carefully.
- Reduce broad imports.
- Avoid unnecessary type-checker complexity in SwiftUI bodies.
- Break very complex expressions.
- Track clean and incremental build times.
- Keep package dependencies minimal and justified.

### 17.3 Dependency Management

Rules:

- Prefer Swift Package Manager.
- Pin versions or use reviewed version ranges.
- Audit licenses.
- Audit privacy and security implications.
- Avoid dependencies for trivial utilities.
- Remove unused dependencies promptly.

---

## 18. Testing and QA

### 18.1 Testing Pyramid

```text
Many: Unit tests for pure logic, mapping, policies, reducers, services
Some: Integration tests for repositories, persistence, networking boundaries
Fewer: UI tests for critical user journeys
Selective: Snapshot tests for visual regression of stable components
Manual: Exploratory, accessibility, performance, device-specific checks
```

### 18.2 Unit Testing

Unit tests must:

- Be deterministic.
- Avoid real network.
- Avoid real time when a clock can be injected.
- Use clear names.
- Test success, failure, edge, and cancellation behavior.

Example:

```swift
func testLoadProfile_whenRepositorySucceeds_setsLoadedState() async throws {
    let repository = ProfileRepositoryStub(result: .success(.fixture()))
    let viewModel = await ProfileViewModel(repository: repository)

    await viewModel.load()

    await XCTAssertEqual(viewModel.state, .loaded(.fixture()))
}
```

### 18.3 UI Testing

UI tests must cover:

- First launch.
- Authentication if applicable.
- Primary happy path.
- Critical failure path.
- Deep links if applicable.
- Accessibility identifiers for stable automation.

Rules:

- Do not depend on arbitrary sleeps.
- Use launch arguments to configure test states.
- Keep UI tests focused and resilient.

### 18.4 Snapshot Testing

Use snapshot tests for stable, visual, high-risk components:

- Design system components.
- Complex cells.
- Empty/error states.
- Localization and Dynamic Type regressions.

Snapshot tests must run in deterministic environments.

### 18.5 Regression Testing

Every bug fix must include:

- A test that fails before the fix when practical.
- A clear description of the root cause.
- Verification of adjacent states.

### 18.6 Manual QA Matrix

Before significant releases, verify:

- Supported OS versions.
- Supported device classes.
- Light and dark mode.
- Dynamic Type including accessibility sizes.
- VoiceOver primary journey.
- RTL layout if localized.
- Offline and poor network.
- Fresh install and upgrade.
- Permission denied and later granted.
- Low storage if persistence-heavy.
- Background/foreground transitions.

---

## 19. Logging, Monitoring, and Analytics

### 19.1 Logging

Logs must help diagnose production issues without exposing private data.

Rules:

- Use structured logging.
- Use log levels intentionally.
- Redact sensitive data.
- Include correlation identifiers where safe.
- Avoid noisy logs in hot paths.

### 19.2 Monitoring

Monitor:

- Crashes.
- Hangs.
- Launch time.
- Memory terminations.
- Network failures.
- Critical business workflow failures.
- Sync failures.
- App Store review-impacting errors.

### 19.3 Analytics

Analytics must be ethical and minimal:

- Track product decisions, not user surveillance.
- Avoid collecting raw personal content.
- Document event names and properties.
- Version analytics schemas.
- Validate analytics in QA.
- Respect consent and platform rules.

Good event:

```text
profile_update_submitted
properties:
  source: settings
  changed_fields_count: 3
  result: success
```

Bad event:

```text
profile_update_submitted
properties:
  new_email: user@example.com
  full_name: Jane Example
```

---

## 20. App Store Readiness

### 20.1 Review Guidelines Discipline

Every release must comply with current Apple App Review Guidelines. Areas requiring special attention:

- Privacy disclosures.
- Account deletion where accounts are created.
- Payments and in-app purchases.
- User-generated content moderation.
- Health, financial, children, regulated, or sensitive categories.
- Background modes.
- Push notifications.
- Sign in with Apple requirements.
- Accurate metadata and screenshots.
- No hidden features or misleading behavior.

### 20.2 Metadata Standards

App Store metadata must:

- Accurately represent app functionality.
- Avoid unsupported claims.
- Avoid mentioning unavailable features.
- Match screenshots to current UI.
- Include privacy details that match implementation.

### 20.3 Release Checklist

- Version and build numbers updated.
- Release notes written.
- App icons and assets verified.
- Privacy manifest reviewed.
- Permission purpose strings reviewed.
- App Review notes prepared.
- TestFlight build validated.
- Crash-free smoke testing completed.
- Analytics and monitoring verified.
- Rollback or mitigation plan documented.

---

## 21. Code Review Standards

### 21.1 Review Philosophy

Code review protects users, maintainers, and product quality. Reviews must focus on correctness, clarity, risk, and long-term cost.

### 21.2 Reviewer Checklist

- Does the change solve the stated problem?
- Are edge cases handled?
- Are user states complete?
- Is the architecture consistent?
- Are dependencies appropriate?
- Is concurrency safe?
- Are errors handled?
- Are security and privacy preserved?
- Is performance acceptable?
- Are tests meaningful?
- Is the UI accessible and localized?
- Is documentation updated where needed?

### 21.3 Author Checklist

- Self-review completed.
- Tests run locally.
- Screenshots or recordings attached for UI changes where useful.
- Risk areas called out.
- Migration impact documented.
- Follow-up tasks created for accepted debt.

### 21.4 Review Anti-Patterns

Avoid:

- Approving incomplete UX because "we will fix it later."
- Debating style not covered by standards.
- Ignoring tests for urgent fixes.
- Accepting hidden singleton dependencies.
- Accepting privacy-invasive analytics.
- Accepting unbounded caches or background work.

---

## 22. Continuous Refactoring and Maintainability

### 22.1 Refactoring Mandate

Engineers and Codex must continuously improve the code while preserving behavior. Refactoring is required when code becomes hard to understand, test, secure, or extend.

### 22.2 Refactoring Rules

- Refactor near the change.
- Keep behavior-preserving refactors separate from risky feature changes when practical.
- Add tests before refactoring risky code.
- Remove dead code.
- Reduce duplication when it creates maintenance risk.
- Improve naming when meaning is unclear.
- Simplify before abstracting.

### 22.3 Technical Debt

Debt may be accepted only when:

- The user value or delivery need is real.
- The risk is understood.
- The debt is documented.
- An owner and review trigger exist.

Debt must not include broken controls, incomplete screens, insecure storage, missing privacy compliance, or known crash paths.

---

## 23. Codex Development Rules

These rules are mandatory for all Codex work in this repository.

### 23.1 Codex Prime Directive

Codex must always improve the product. Every change should leave the codebase, UX, performance, security, accessibility, tests, or documentation better than before.

### 23.2 Mandatory Codex Behavior

Codex must:

- Follow `PROJECT_STANDARDS.md` for all future work unless explicitly instructed otherwise.
- Read relevant existing code before editing.
- Preserve user changes and never revert work it did not make unless explicitly asked.
- Implement complete behavior, not placeholders.
- Verify work with tests, builds, static checks, or targeted inspection.
- Report verification performed and any gaps.
- Refactor continuously when touching poor local code.
- Optimize continuously when performance risks are visible.
- Improve architecture continuously when boundaries are weak.
- Improve security continuously when sensitive data or trust boundaries are involved.
- Improve accessibility continuously when UI is touched.
- Improve maintainability continuously through clearer names, smaller units, and better tests.

### 23.3 Codex Prohibitions

Codex must never leave:

- Incomplete implementations.
- Broken buttons.
- Unfinished screens.
- Inconsistent UI.
- Placeholder behavior presented as finished.
- Dead navigation paths.
- Unhandled loading/error/empty states.
- Avoidable compiler warnings.
- Known failing tests without disclosure.
- Sensitive data in logs or source.
- Unreviewed destructive operations.
- Unnecessary broad refactors unrelated to the task.

### 23.4 Codex UX Responsibility

When Codex sees poor UX in the area being modified, it must redesign or improve it within scope. If the UX problem is broader than the current task, Codex must document the issue and recommend the next concrete fix.

### 23.5 Codex Completion Checklist

Before final response, Codex must check:

- Did I satisfy the user's latest request?
- Did I inspect relevant files?
- Did I preserve unrelated user changes?
- Did I implement all visible states?
- Did I avoid placeholders?
- Did I update tests or explain why not?
- Did I run appropriate verification?
- Did I disclose limitations?
- Did I follow this manual?

---

## 24. Engineering Decision Rules

### 24.1 Native First

Prefer platform-native APIs and controls unless a custom solution provides clear user value and can meet accessibility, performance, localization, and maintainability requirements.

### 24.2 Simple First

Prefer the simplest architecture that satisfies current requirements and likely near-term evolution. Avoid speculative frameworks.

### 24.3 Explicit Boundaries

Data, domain, presentation, security, analytics, and persistence boundaries must be explicit enough to test and evolve independently.

### 24.4 State Machines for Complex UI

When UI has multiple modes, asynchronous operations, or failure states, model state explicitly:

```swift
enum LoadableState<Value: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(DisplayError)
}
```

### 24.5 Future Compatibility

Future compatibility requires:

- Avoiding deprecated APIs for new work.
- Checking availability for new APIs.
- Isolating platform-specific code.
- Keeping migrations tested.
- Avoiding assumptions about device size, input mode, locale, or network quality.
- Tracking Apple platform changes during major OS beta cycles.

---

## 25. Enterprise Engineering Practices

### 25.1 Governance

Production work must have:

- Clear ownership.
- Review path.
- Release accountability.
- Security and privacy review for sensitive changes.
- Documentation for operationally important behavior.

### 25.2 Risk Management

High-risk changes require:

- Design review.
- Architecture review.
- Test plan.
- Rollout strategy.
- Monitoring plan.
- Rollback or mitigation plan.

High-risk categories:

- Authentication.
- Payments.
- Data loss.
- Data migration.
- Encryption.
- User privacy.
- Sync.
- Background execution.
- Push notifications.
- App Store policy-sensitive areas.

### 25.3 Incident Response

For production incidents:

1. Triage severity.
2. Protect users and data.
3. Mitigate quickly.
4. Communicate clearly.
5. Preserve evidence.
6. Fix root cause.
7. Add regression tests.
8. Document learnings.

### 25.4 Documentation

Documentation must exist for:

- Architecture decisions.
- Non-obvious workflows.
- Release process.
- Data models and migrations.
- Security-sensitive code.
- Public or module-facing APIs.
- Operational runbooks.

---

## 26. Implementation Playbooks

### 26.1 New Feature Playbook

1. Define user problem and success criteria.
2. Sketch primary journey and states.
3. Classify data and permissions.
4. Choose architecture and module placement.
5. Define domain models.
6. Define repository/service contracts.
7. Implement UI with all states.
8. Add tests.
9. Verify accessibility, localization, performance, and security.
10. Update documentation.

### 26.2 Bug Fix Playbook

1. Reproduce or reason from evidence.
2. Identify root cause.
3. Add regression coverage when practical.
4. Fix narrowly.
5. Verify adjacent states.
6. Document behavior if externally visible.

### 26.3 UI Screen Playbook

Required deliverables:

- Screen purpose.
- Navigation entry and exit.
- State model.
- Layout behavior across devices.
- Component inventory.
- Accessibility behavior.
- Localization and RTL behavior.
- Loading, empty, error, offline states.
- Analytics events if needed.
- Tests or previews.

### 26.4 Data Migration Playbook

1. Inventory existing schema and data.
2. Define target schema.
3. Write migration.
4. Test with realistic old data.
5. Test failure and recovery.
6. Test performance.
7. Ensure backup or rollback path where practical.
8. Document migration version and behavior.

---

## 27. Automatic Quality Checklists

### 27.1 Pull Request Gate

- Builds successfully.
- Tests pass.
- No new warnings.
- No broken UI controls.
- No incomplete screens.
- No placeholder code.
- No sensitive logging.
- No unreviewed dependency.
- No missing permission purpose string.
- No accessibility regression in touched UI.
- No localization regression in user-facing strings.

### 27.2 Product Audit

- Primary journey works end to end.
- First-run experience is clear.
- App recovers from network failure.
- App handles empty user data.
- App handles large user data.
- App handles denied permissions.
- Critical tasks are not hidden.
- Support and feedback paths are clear if required.
- App Store metadata matches reality.

### 27.3 Security Audit

- Secrets stored only in Keychain or secure system storage.
- Sensitive local files use appropriate protection.
- Network uses HTTPS.
- Authentication state transitions are tested.
- Session expiration is handled.
- Logs are redacted.
- Analytics avoids personal content.
- Dependencies are reviewed.

### 27.4 Performance Audit

- Launch measured.
- Main thread checked.
- Scrolling tested with realistic data.
- Memory tested through primary journeys.
- Images downsampled.
- Caches bounded.
- Background work justified.
- Battery-sensitive operations minimized.

### 27.5 Accessibility Audit

- VoiceOver labels are useful.
- Reading order is logical.
- Dynamic Type does not break layout.
- Color contrast is sufficient.
- Color is not sole state indicator.
- Reduce Motion respected.
- Keyboard/focus supported where relevant.
- Custom controls expose semantic actions.

---

## 28. Anti-Pattern Catalog

### 28.1 Product Anti-Patterns

- Shipping features without a defined user problem.
- Treating settings as a substitute for good defaults.
- Hiding unfinished work behind vague copy.
- Measuring vanity metrics instead of user outcomes.

### 28.2 Design Anti-Patterns

- Non-native navigation for ordinary workflows.
- Oversized decorative layouts in operational apps.
- Inconsistent button styles.
- Text that truncates critical meaning.
- Modal stacks without clear escape.

### 28.3 Swift Anti-Patterns

- Force unwraps as routine.
- Global mutable state.
- Massive view models.
- Services named `Manager`.
- Boolean flags controlling complex behavior.
- Stringly typed domain logic.
- Ignored thrown errors.

### 28.4 SwiftUI Anti-Patterns

- Business logic in view bodies.
- Network work in views.
- Unstable identity in lists.
- Layout magic numbers.
- Gesture-only buttons.
- Unbounded tasks.

### 28.5 Architecture Anti-Patterns

- UI importing persistence internals.
- Repositories returning raw transport DTOs everywhere.
- Single module containing all features indefinitely.
- Circular dependencies.
- Abstractions with one unclear method and no stable reason.

### 28.6 Security and Privacy Anti-Patterns

- Tokens in `UserDefaults`.
- Personal data in analytics.
- Broad permission requests on first launch.
- Custom cryptography.
- Debug endpoints in production builds.

---

## 29. Reference Implementation Patterns

### 29.1 Feature State

```swift
enum FeatureState<Value: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case empty(EmptyState)
    case failed(DisplayError)
}

struct EmptyState: Equatable, Sendable {
    let title: String
    let message: String
    let actionTitle: String?
}

struct DisplayError: Error, Equatable, Sendable {
    let title: String
    let message: String
    let recoveryTitle: String?
}
```

### 29.2 View Intent

```swift
enum ProfileIntent: Sendable {
    case appeared
    case refreshRequested
    case editTapped
    case retryTapped
}
```

### 29.3 View Model

```swift
@MainActor
@Observable
final class ProfileViewModel {
    private let repository: ProfileRepository
    private var loadTask: Task<Void, Never>?

    var state: FeatureState<Profile> = .idle

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func handle(_ intent: ProfileIntent) {
        switch intent {
        case .appeared, .retryTapped, .refreshRequested:
            loadTask?.cancel()
            loadTask = Task { await load() }
        case .editTapped:
            break
        }
    }

    private func load() async {
        state = .loading
        do {
            let profile = try await repository.profile()
            state = .loaded(profile)
        } catch is CancellationError {
            return
        } catch {
            state = .failed(ErrorPresenter.profile(error))
        }
    }
}
```

### 29.4 SwiftUI Screen

```swift
struct ProfileView: View {
    @State private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Profile")
            .task { viewModel.handle(.appeared) }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let profile):
            ProfileContent(profile: profile)
        case .empty(let emptyState):
            EmptyStateView(state: emptyState)
        case .failed(let error):
            ErrorStateView(error: error) {
                viewModel.handle(.retryTapped)
            }
        }
    }
}
```

---

## 30. Release Operations

### 30.1 Branching and Change Management

The project should use a predictable workflow:

- Small branches.
- Clear commits.
- Pull request review.
- CI verification.
- Release branch only when useful.
- Tags for shipped versions.

### 30.2 Versioning

- Marketing version follows product release semantics.
- Build number always increases.
- Release notes are user-readable.
- Internal notes include technical risk and migration notes.

### 30.3 Rollout

Use staged rollout for meaningful risk. Monitor:

- Crash rate.
- Hangs.
- Performance regressions.
- Login failures.
- Purchase failures.
- Sync failures.
- User support signals.

Pause rollout when guardrails fail.

---

## 31. Maintenance and Evolution

### 31.1 OS Adoption

During Apple beta cycles:

- Test on new OS versions.
- Review deprecations.
- Evaluate new APIs.
- Validate UI changes.
- Update compatibility strategy.
- Avoid adopting new APIs without availability checks.

### 31.2 Dependency Review

At least once per release cycle:

- Review outdated dependencies.
- Remove unused dependencies.
- Check security advisories.
- Check license changes.
- Check privacy impact.

### 31.3 Documentation Review

This manual must be reviewed when:

- Apple releases major platform guidance affecting the project.
- Architecture changes materially.
- Security or privacy policy changes.
- Release process changes.
- Postmortems reveal a standards gap.

---

## 32. Source References

The following official sources should be checked for current platform details when work touches their areas:

- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- Apple Accessibility: https://developer.apple.com/accessibility/
- Apple App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple SwiftUI Documentation: https://developer.apple.com/documentation/swiftui
- Apple Observation Documentation: https://developer.apple.com/documentation/observation
- Swift Language Guide - Concurrency: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/
- Swift API Design Guidelines: https://www.swift.org/documentation/api-design-guidelines/
- Apple Security Documentation: https://support.apple.com/guide/security/welcome/web
- Apple Developer Documentation: https://developer.apple.com/documentation/
- Apple Design updates and Liquid Glass guidance: https://developer.apple.com/design/
- Apple Foundation Models documentation: https://developer.apple.com/documentation/foundationmodels
- Apple Intelligence developer resources: https://developer.apple.com/apple-intelligence/
- Apple Privacy Manifest files: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
- Apple Required Reason APIs: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api
- OWASP Mobile Application Security: https://owasp.org/www-project-mobile-app-security/

These links are references, not substitutes for engineering judgment. If Apple updates guidance, this manual must be interpreted in favor of the current official Apple recommendation.

---

## 33. Standing Orders

The following orders are permanent for this project:

- Always improve the product.
- Never leave incomplete implementations.
- Never leave broken buttons.
- Never leave unfinished screens.
- Never leave inconsistent UI.
- Always redesign poor UX in touched areas.
- Continuously refactor.
- Continuously optimize.
- Continuously test.
- Continuously validate.
- Continuously improve architecture.
- Continuously improve performance.
- Continuously improve security.
- Continuously improve accessibility.
- Continuously improve maintainability.
- Prefer native Apple patterns.
- Protect user privacy.
- Preserve trust.
- Ship complete, polished, verified work.

---

## 34. Enterprise Product Engineering

This chapter expands Chapter 1 into an enterprise product engineering operating model. Product engineering is the discipline of converting validated human needs into reliable, measurable, maintainable Apple-platform software. It is not separate from engineering quality; product clarity determines architectural clarity, testing strategy, privacy posture, performance budgets, and release risk.

### 34.1 Product Strategy

Every product strategy must connect four layers:

| Layer | Purpose | Required Output |
|---|---|---|
| Vision | Defines the long-term product destination | A durable statement of user value and market position |
| Mission | Defines what the product does every day | A practical operating statement for teams |
| North Star | Defines the primary user outcome | One metric or qualitative target that reflects real value |
| Roadmap | Sequences bets and commitments | Time-bounded initiatives with success criteria |

Strategy must not be a list of features. It must explain what user behavior should change, why that change matters, and how the product will earn trust over time.

### 34.2 Vision, Mission, and North Star

Use this hierarchy:

```text
Vision -> What world are we trying to create?
Mission -> What do we reliably help users do?
North Star -> What user outcome proves we are succeeding?
Strategy -> Which bets move the North Star responsibly?
Roadmap -> What sequence of work executes the strategy?
Backlog -> What concrete tasks implement the roadmap?
```

Good North Star metrics are user-outcome metrics, not vanity metrics. Examples:

- "Weekly completed workflows without support contact" is stronger than "weekly active users."
- "Median time to complete primary task" is stronger than "screen views."
- "Percentage of successful offline-to-online syncs" is stronger than "sync attempts."

### 34.3 Product Lifecycle Governance

Every initiative must pass these gates:

| Gate | Primary Question | Evidence |
|---|---|---|
| Discovery | Is the problem real? | Research notes, support data, analytics, interviews |
| Definition | Do we know what success means? | Requirements, non-goals, acceptance criteria |
| Design | Is the user experience coherent? | Flow diagrams, states, accessibility plan |
| Architecture | Can this be built safely? | ADR, module plan, data/privacy classification |
| Implementation | Is the work production-ready? | Tests, code review, QA evidence |
| Release | Can we detect and mitigate regressions? | Monitoring, rollout, rollback plan |
| Learning | Did it work? | Metrics review, qualitative feedback, incident review |

No gate is a ceremony. Each gate exists to reduce a real category of risk.

### 34.4 MVP Standards

An MVP is the smallest complete product learning unit. It is not permission to ship broken UX.

An acceptable MVP:

- Solves one validated problem end to end.
- Includes complete loading, empty, error, offline, and permission states when applicable.
- Has production-grade privacy and security.
- Has enough instrumentation to learn.
- Has tests for critical behavior.
- Has a known path to evolve or remove.

An unacceptable MVP:

- Contains broken buttons, placeholder screens, or dead flows.
- Relies on manual database fixes.
- Ignores accessibility.
- Collects unnecessary data "just in case."
- Cannot be evaluated after release.

### 34.5 Feature Prioritization

Prioritize features with a structured model:

| Dimension | Question | Weight Guidance |
|---|---|---|
| User value | Does this solve a real pain or unlock meaningful value? | Highest |
| Strategic fit | Does it advance the product vision? | High |
| Confidence | Do we have evidence? | High |
| Risk | Could this harm trust, privacy, performance, or release stability? | High |
| Effort | What is the implementation and maintenance cost? | Medium |
| Reversibility | Can we undo it if wrong? | Medium |

Decision rule:

```text
High value + high confidence + manageable risk -> prioritize.
High value + low confidence -> prototype or research first.
Low value + high effort -> reject.
High risk + unclear mitigation -> delay until mitigated.
```

### 34.6 User Stories and Acceptance Criteria

User stories must describe user intent, not implementation:

```text
As a frequent traveler,
I want saved offline trip details,
so I can access reservations without network connectivity.
```

Acceptance criteria must be observable:

```text
Given the user has saved a trip,
when the device is offline,
then the trip details screen loads from local storage within the offline performance budget,
and displays data freshness.
```

Required acceptance criteria categories:

- Functional behavior.
- Empty/error/offline states.
- Accessibility.
- Localization and RTL.
- Security and privacy.
- Performance budget.
- Analytics or monitoring.
- Migration and compatibility where applicable.

### 34.7 Feature Evolution and Removal

Features must be maintained, evolved, or removed. A feature that no longer serves users is product debt.

Feature removal process:

1. Identify usage, support cost, defect rate, and strategic fit.
2. Determine user impact and migration path.
3. Communicate changes where appropriate.
4. Remove UI, data, analytics, tests, documentation, and backend assumptions.
5. Monitor for regressions after removal.

Never leave abandoned UI entry points, unused permissions, or dead settings.

### 34.8 Product Metrics and KPIs

Metrics must be defined with:

- Name.
- Owner.
- Calculation.
- Grain.
- Exclusions.
- Data source.
- Privacy classification.
- Decision it supports.
- Expected movement.
- Guardrail metrics.

Example:

```text
Metric: Offline task completion rate
Calculation: completed offline workflows / started offline workflows
Grain: user-session-day
Guardrails: crash rate, sync conflict rate, support contact rate
Privacy: no personal content stored in event payloads
Decision: whether offline workflow is reliable enough for wider rollout
```

### 34.9 Technical Debt Strategy

Product and engineering debt must be managed together:

| Debt Type | Example | Required Response |
|---|---|---|
| UX debt | Confusing settings, dead-end flow | Redesign in touched area or backlog with owner |
| Architecture debt | Shared manager with unrelated responsibilities | Refactor behind interface |
| Test debt | Critical path lacks regression coverage | Add tests before high-risk change |
| Security debt | Token stored outside Keychain | Fix before release |
| Performance debt | Slow launch from eager initialization | Budget, measure, defer work |
| Product debt | Feature exists but no longer has purpose | Evolve or remove |

Security, privacy, data loss, broken controls, and crash-path debt cannot be accepted as routine debt.

---

## 35. Enterprise Design System Framework

This chapter expands Chapter 4. The design system is an engineering system, not a visual sticker sheet. It must encode product philosophy, Apple platform behavior, accessibility, localization, motion, component states, and implementation APIs.

### 35.1 Design Philosophy

The project design philosophy:

- Native before novel.
- Semantic before decorative.
- Accessible before expressive.
- Consistent before surprising.
- Adaptive before device-specific.
- Performant before ornamental.
- Clear before dense.

The design system must help engineers make correct UI decisions without re-litigating fundamentals in every feature.

### 35.2 Visual Language

Visual language must define:

- Shape: radii, borders, separators, grouping.
- Space: density, margins, rhythm, hierarchy.
- Color: semantic roles, contrast, dynamic appearance.
- Type: hierarchy, readability, content priority.
- Motion: state continuity and feedback.
- Material: depth, translucency, glass, blur, and platform effects.
- Iconography: SF Symbols usage, custom asset rules.

Visual language must be documented as tokens and components, not screenshots alone.

### 35.3 Apple Design Language Interpretation

Apple design language emphasizes clarity, deference, depth, continuity, direct manipulation, and platform fit. Interpret it as follows:

| Apple Principle | Project Interpretation | Engineering Consequence |
|---|---|---|
| Clarity | Content and actions are understandable | Prefer semantic labels, hierarchy, readable spacing |
| Deference | UI supports content | Avoid decorative chrome that competes with work |
| Depth | Layers communicate structure | Use navigation, sheets, materials, and motion intentionally |
| Consistency | Platform behaviors are familiar | Use native controls and patterns first |
| Feedback | Actions produce visible response | Provide loading, success, failure, and disabled states |
| Control | Users understand consequences | Use undo, confirmation, and reversible operations |

### 35.4 Information Hierarchy

Every screen must have:

- A primary purpose.
- A primary action or clear reason for no primary action.
- A hierarchy of content groups.
- Secondary actions that do not compete with the primary action.
- Supporting metadata that does not overwhelm the main task.

Hierarchy tools:

- Navigation title.
- Section headings.
- Font weight and text style.
- Spacing.
- Grouping.
- Color and material.
- Disclosure.
- Toolbar placement.

### 35.5 Layout Systems

Use layout systems that adapt to device, orientation, text size, locale, and platform:

| Platform | Preferred Structures |
|---|---|
| iPhone | Navigation stack, tabs, sheets, full-screen flows for immersive tasks |
| iPad | Split views, sidebars, inspectors, adaptive sheets, pointer-aware controls |
| macOS | Windows, sidebars, toolbars, menus, inspectors, keyboard shortcuts |
| watchOS | Glanceable stacks, simple lists, complications, crown interaction |
| tvOS | Focus-driven layouts, large targets, clear spatial grouping |
| visionOS | Volumetric or windowed surfaces, depth-aware placement, comfortable scale |

Rules:

- Use safe areas and readable margins.
- Use `ViewThatFits`, adaptive grids, and size classes where useful.
- Avoid hard-coded breakpoints unless tied to component behavior.
- Test Dynamic Type before declaring layout complete.

### 35.6 Responsive and Adaptive Layout

Responsive layout changes dimensions. Adaptive layout changes structure.

| Scenario | Responsive Response | Adaptive Response |
|---|---|---|
| iPhone portrait to landscape | Reflow content | Consider two-column only if task improves |
| iPad compact split screen | Reduce columns | Collapse sidebar |
| macOS wide window | Increase visible columns | Add inspector or persistent sidebar |
| Dynamic Type large | Wrap and grow | Move secondary content below primary |
| RTL locale | Mirror direction | Reconsider directional icons |

### 35.7 Window Management

For iPadOS, macOS, and visionOS:

- Preserve window state where useful.
- Support multiple windows only when independent tasks benefit.
- Keep toolbars and sidebars stable.
- Avoid assuming one active scene.
- Use scene storage for per-window state.
- Test Stage Manager and split view.

### 35.8 Stage Manager Considerations

Stage Manager can produce unexpected window sizes. Requirements:

- Primary workflows must remain usable in narrow and medium widths.
- Sidebars must collapse or become overlays.
- Toolbars must avoid clipped labels.
- Detail views must not require full-screen width.
- Drag and drop must be tested if supported.

### 35.9 visionOS Layout

visionOS design must respect comfort:

- Avoid placing critical UI at uncomfortable angles.
- Use depth sparingly and meaningfully.
- Prefer stable surfaces for reading and input.
- Avoid excessive motion toward the user.
- Use ornaments and volumes only when they improve the task.
- Keep text large enough for comfortable viewing.

### 35.10 watchOS Layout

watchOS design must be glanceable:

- One primary idea per screen.
- Minimal text.
- Large tappable controls.
- Crown-friendly scrolling.
- Complications that summarize, not duplicate the app.
- Avoid long forms.

### 35.11 tvOS Layout

tvOS design must be focus-first:

- Every interactive item must have a clear focused state.
- Avoid dense text entry.
- Use large spatial grouping.
- Ensure remote navigation is predictable.
- Test overscan-safe composition where relevant.

### 35.12 Color System

Color tokens must be semantic:

| Token Type | Examples | Notes |
|---|---|---|
| Surface | `surfacePrimary`, `surfaceSecondary`, `surfaceElevated` | Dynamic light/dark |
| Text | `textPrimary`, `textSecondary`, `textCritical` | Contrast-tested |
| Action | `actionPrimary`, `actionDestructive`, `actionDisabled` | Role-based |
| Status | `statusSuccess`, `statusWarning`, `statusError`, `statusInfo` | Never color-only |
| Border | `borderSubtle`, `borderStrong`, `divider` | Material-aware |

Rules:

- Never encode meaning only by hue.
- Define dark mode and high contrast variants.
- Avoid arbitrary per-screen colors.
- Document contrast expectations.

### 35.13 Materials, Blur, Glass, and Liquid Glass

Materials are depth and context tools. They are not decoration.

Use materials when:

- Content floats above dynamic content.
- A toolbar or overlay needs separation without heavy borders.
- The platform convention expects translucency.

Avoid materials when:

- Text contrast becomes weak.
- Performance suffers.
- The effect competes with content.
- The screen already has multiple layered surfaces.

Liquid Glass and glass-like effects must follow current Apple guidance:

- Use system-provided materials and APIs when available.
- Maintain legibility in light, dark, and high contrast modes.
- Avoid stacking glass effects.
- Avoid glass for dense reading surfaces.
- Test animation and scroll performance.

### 35.14 Shadows, Elevation, Radius, Borders, and Dividers

Depth must be systematic:

| Element | Radius | Shadow | Border |
|---|---:|---|---|
| Small controls | System/default | None or subtle | Optional |
| Cards | 8px or system equivalent | Subtle only when needed | Subtle separator |
| Sheets/modals | System | System | None unless needed |
| Floating controls | Circular or capsule by platform | Platform material shadow | Optional |

Rules:

- Do not use heavy web-style shadows in native apps.
- Do not nest elevated surfaces.
- Use dividers for structure, not decoration.
- Prefer system separators in lists and tables.

### 35.15 Typography System

Typography must define:

| Role | Preferred SwiftUI Style | Usage |
|---|---|---|
| Large title | `.largeTitle` | Major navigation or landing context |
| Title | `.title`, `.title2`, `.title3` | Screen and major section hierarchy |
| Headline | `.headline` | Cards, rows, important labels |
| Body | `.body` | Primary reading text |
| Callout | `.callout` | Supporting emphasis |
| Subheadline | `.subheadline` | Metadata |
| Caption | `.caption`, `.caption2` | Dense secondary information |

Rules:

- Use Dynamic Type for user-facing text.
- Avoid fixed line heights that clip.
- Test long localized strings.
- Use monospaced digits for counters and timers where useful.

### 35.16 Iconography and SF Symbols

SF Symbols are the default icon system.

Rules:

- Use symbols that match platform meaning.
- Pair unfamiliar icons with text or tooltips.
- Use symbol variants consistently.
- Match icon weight to text weight.
- Respect bidirectional symbols in RTL.
- Do not use custom icons for common system concepts without strong reason.

### 35.17 Image and Illustration Systems

Images must reveal useful reality or reinforce a domain-specific concept.

Rules:

- Use asset catalogs.
- Provide appropriate scale and appearance variants.
- Avoid stock-like imagery in operational tools.
- Use illustrations sparingly and consistently.
- Add accessibility labels or mark decorative images as hidden.
- Downsample large images before display.

### 35.18 Enterprise Component Governance

Every shared component must include:

- Purpose.
- API.
- Visual rules.
- State model.
- Accessibility contract.
- Localization behavior.
- Motion behavior.
- Performance notes.
- Preview states.
- Test strategy.
- Usage examples.
- Anti-patterns.

Component ownership must be clear. Breaking changes require migration guidance.

---

## 36. Motion Design System

Motion communicates continuity, causality, hierarchy, and feedback. Motion must help users understand state change. It must never be used to distract from slow work, hide broken behavior, or create inaccessible experiences.

### 36.1 Animation Philosophy

Motion in this project must be:

- Purposeful.
- Brief.
- Interruptible where user-driven.
- Performance-aware.
- Accessibility-aware.
- Consistent with platform conventions.

### 36.2 Apple Motion Language

Apple motion typically favors continuity, direct manipulation, spring behavior, and spatial coherence. Apply it as:

- Objects should move from where users perceive them to originate.
- Navigation transitions should preserve orientation.
- Gesture-driven elements should track touch or pointer input.
- Success and error motion should be subtle and legible.
- System transitions should be preferred over custom transitions.

### 36.3 Duration Standards

| Motion Type | Recommended Duration |
|---|---:|
| Tap feedback | 80-140 ms |
| Micro-interaction | 120-220 ms |
| State transition | 180-320 ms |
| Navigation transition | System default |
| Loading skeleton shimmer | 900-1500 ms cycle |
| Success confirmation | 250-500 ms |
| Error attention | 180-350 ms |

Durations are guidance, not absolutes. Prefer system defaults when available.

### 36.4 Spring Animations

Use spring animations for physical continuity:

```swift
withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
    isExpanded.toggle()
}
```

Rules:

- Avoid bouncy springs for serious or enterprise workflows.
- Use tighter damping for productivity interfaces.
- Use more expressive springs only for playful domains.
- Ensure final state settles quickly.

### 36.5 Ease Curves

| Curve | Use |
|---|---|
| Ease out | Elements entering or completing |
| Ease in | Elements leaving |
| Ease in out | Symmetric state changes |
| Linear | Progress, timers, shimmer loops |
| Spring | Direct manipulation and expansion |

### 36.6 Transition Standards

Transitions must preserve user orientation:

- Push transitions for hierarchy.
- Sheet transitions for focused tasks.
- Fade/scale for lightweight overlays.
- Matched geometry for continuity between list and detail when stable.
- Avoid arbitrary slide directions that contradict navigation.

### 36.7 Matched Geometry

Use matched geometry when:

- The same object changes representation.
- Users benefit from spatial continuity.
- Identity is stable.

Avoid it when:

- Source and destination are conceptually different.
- It creates jank in large lists.
- It breaks accessibility Reduce Motion expectations.

### 36.8 Loading, Skeleton, and Progress

Loading patterns:

| Pattern | Use |
|---|---|
| Inline `ProgressView` | Short, local work |
| Skeleton loading | Predictable content layout |
| Determinate progress | File upload, export, long processing |
| Background status | Sync or non-blocking refresh |

Rules:

- Do not show indefinite loading without failure path.
- Skeletons must match final layout.
- Progress must be cancellable when the operation is user-initiated and long-running.

### 36.9 Success and Error Motion

Success:

- Confirm completion without blocking.
- Avoid excessive celebration in professional workflows.
- Use checkmark, subtle color, or row state change.

Error:

- Use motion to direct attention, not shame the user.
- Avoid repeated shaking.
- Pair motion with text and recovery action.
- Respect Reduce Motion.

### 36.10 Performance-Aware Motion

Motion performance checklist:

- No heavy blur during scroll unless measured.
- No unbounded animations in off-screen cells.
- No layout thrash from animated geometry.
- No image decoding during transition.
- Test on older supported devices.
- Profile animation hitches with Instruments.

### 36.11 Accessibility-Aware Motion

When Reduce Motion is enabled:

- Replace large spatial transitions with fades.
- Disable parallax-like effects.
- Avoid looping decorative animation.
- Preserve feedback using non-motion cues.

SwiftUI pattern:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

withAnimation(reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.28, dampingFraction: 0.86)) {
    isPresented = true
}
```

---

## 37. UX Engineering Deep Standard

UX engineering bridges design intent and production implementation. A usable mockup is not enough; UX must survive data variation, failure, accessibility settings, localization, and long-term product evolution.

### 37.1 Cognitive Load

Reduce cognitive load by:

- Grouping related controls.
- Naming actions concretely.
- Revealing complexity progressively.
- Avoiding unnecessary choices.
- Keeping primary workflows short.
- Using platform conventions.
- Preserving user context.

Warning signs:

- Users must remember values from previous screens.
- Multiple actions look equally important.
- Error messages explain the system instead of the recovery.
- Users must learn custom gestures for basic tasks.

### 37.2 Mental Models

Design must match how users think about the domain. Engineering must preserve that model in state and data structures.

Example:

```text
User mental model: "My trip has reservations, documents, and reminders."
Good architecture: Trip aggregates reservations/documents/reminders through clear repositories.
Bad architecture: Each screen separately fetches unrelated fragments and reconstructs the idea differently.
```

### 37.3 Information Architecture

Information architecture must define:

- Top-level destinations.
- Hierarchy.
- Object relationships.
- Search and filtering model.
- Empty states.
- Deep links.
- Settings placement.

Decision rule:

```text
If a user thinks of something as a place -> navigation destination.
If a user thinks of something as an action -> button, menu, or command.
If a user thinks of something as a property -> form field, filter, or inspector.
```

### 37.4 Navigation Psychology

Navigation must answer:

- Where am I?
- What can I do here?
- How did I get here?
- How do I go back or exit?
- What changed?

Avoid:

- Deep stacks for flat tasks.
- Modals that hide important context.
- Tabs that change meaning across states.
- Back buttons that discard unsaved work without warning.

### 37.5 First Run and Onboarding

Onboarding must accelerate value, not delay it.

Rules:

- Start with the user's job, not product marketing.
- Ask for permissions only at moment of need.
- Let users skip non-essential onboarding.
- Persist progress.
- Avoid carousel tutorials unless they measurably improve activation.
- Provide sample data only if it improves understanding and cannot be confused with real data.

### 37.6 Settings UX

Settings are for user control, not unresolved design decisions.

Good settings:

- Privacy preferences.
- Notification preferences.
- Account management.
- Export/delete data.
- Display preferences that users expect.

Bad settings:

- Basic workflow choices that should be inferred.
- Hidden feature toggles for incomplete work.
- Technical options users cannot evaluate.

### 37.7 Offline UX

Offline UX must explain:

- Whether data is cached.
- Freshness of data.
- Whether edits are queued.
- Sync status.
- Conflict state.
- Recovery action.

Offline state copy should be practical:

```text
You are offline. Showing trip details saved 12 minutes ago.
Changes will sync when your connection returns.
```

### 37.8 Error Recovery

Every error must have:

- Human-readable title.
- Specific explanation.
- Recovery action.
- Preservation of user input.
- Diagnostic logging.

Error taxonomy:

| Type | User Treatment |
|---|---|
| Offline | Show cached data or retry path |
| Unauthorized | Reauthenticate or explain access |
| Validation | Inline field correction |
| Conflict | Compare and resolve |
| Server | Retry or status explanation |
| Unknown | Calm fallback and support path |

### 37.9 Undo and Confirmation

Prefer undo when:

- Action is reversible.
- Consequence is low to moderate.
- Confirmation would slow frequent work.

Use confirmation when:

- Action is destructive and hard to undo.
- Data loss is likely.
- User may not understand consequence.
- Legal, financial, or security impact exists.

### 37.10 Progressive Disclosure

Progressive disclosure must:

- Keep common paths simple.
- Reveal advanced controls only when relevant.
- Preserve discoverability.
- Avoid hiding critical actions.

Pattern examples:

- Disclosure groups for advanced filters.
- Inspector panels for metadata.
- Context menus for secondary object actions.
- Toolbars for common commands.

### 37.11 Trust UX

Users trust apps that:

- Explain data use.
- Recover gracefully.
- Do not surprise them with permissions.
- Preserve work.
- Make destructive actions clear.
- Perform consistently.
- Provide accurate status.

Trust is damaged by:

- Silent failures.
- Unexpected data loss.
- Misleading progress.
- Inaccurate AI output presented as fact.
- Privacy surprises.

---

## 38. Complete Component Library Standards

This chapter defines the required component quality contract. Components must be reusable only when they encode stable product semantics or remove meaningful duplication.

### 38.1 Component Contract Template

Every component specification must include:

```text
Name:
Purpose:
When to use:
When not to use:
Content model:
States:
Accessibility:
Localization:
Motion:
Performance:
API:
Examples:
Common mistakes:
Tests:
```

### 38.2 Buttons

Purpose: Initiate actions.

States:

- Default.
- Pressed.
- Focused.
- Disabled.
- Loading.
- Destructive.
- Success after action where appropriate.

Accessibility:

- Use `Button`.
- Provide labels for icon-only buttons.
- Use roles such as `.destructive`.
- Ensure target size.

Implementation:

```swift
Button(role: .destructive) {
    viewModel.delete()
} label: {
    Label("Delete", systemImage: "trash")
}
.disabled(viewModel.isDeleting)
```

Anti-patterns:

- `onTapGesture` as a button.
- Disabled button with no explanation.
- Button that starts duplicate requests.

### 38.3 Cards

Purpose: Group a compact object summary or repeated item.

Rules:

- One object or concept per card.
- Avoid nested cards.
- Keep actions clear.
- Use stable spacing and typography.
- Do not make the entire card tappable if it contains conflicting controls.

States:

- Default.
- Selected.
- Focused.
- Loading skeleton.
- Error.
- Disabled.

### 38.4 Lists

Purpose: Present ordered or scannable collections.

Rules:

- Use stable IDs.
- Support pagination or lazy loading for large data.
- Preserve scroll position.
- Keep row computation cheap.
- Include empty, error, and refresh states.

Common mistakes:

- Using index as identity.
- Fetching images synchronously.
- Re-sorting on every row render.

### 38.5 Grids

Purpose: Present visual or equally weighted items.

Rules:

- Use adaptive columns.
- Preserve aspect ratios.
- Avoid dense text.
- Ensure keyboard/focus behavior on iPad/macOS/tvOS.
- Handle long localized labels.

### 38.6 Forms and Inputs

Purpose: Collect user-provided data.

Rules:

- Validate inline.
- Use correct keyboard and content type.
- Preserve draft data.
- Mark required fields.
- Support submit flow.
- Support secure text entry and password managers.

State model:

```swift
enum FieldState<Value: Equatable>: Equatable {
    case pristine(Value)
    case editing(Value)
    case valid(Value)
    case invalid(Value, message: String)
}
```

### 38.7 Pickers and Menus

Use pickers for choosing a value from a known set. Use menus for secondary actions or compact option sets.

Rules:

- Avoid hiding primary actions in menus.
- Keep labels specific.
- Use checkmarks for selected values.
- Support keyboard and pointer interaction.

### 38.8 Toolbars

Toolbars contain high-frequency commands for the current context.

Rules:

- Keep toolbar actions stable.
- Place destructive actions carefully.
- Use system placements.
- Provide labels/tooltips where needed.
- Avoid toolbar overflow for primary actions.

### 38.9 Navigation Components

Navigation components must be semantically correct:

- Tabs for top-level destinations.
- Stacks for hierarchy.
- Sidebars for broad structure on large displays.
- Breadcrumb-like affordances only where platform appropriate.

### 38.10 Sheets, Dialogs, and Alerts

Sheets:

- Use for focused tasks.
- Preserve context.
- Support cancellation.
- Warn before discarding unsaved work.

Dialogs/alerts:

- Use sparingly.
- Prefer clear action labels.
- Avoid vague "OK" when a specific action is better.
- Do not use alerts for routine success.

### 38.11 Context Menus

Context menus are secondary accelerators.

Rules:

- Do not hide essential actions only in context menus.
- Keep destructive actions separated.
- Match visible actions where appropriate.
- Support pointer and touch expectations.

### 38.12 Search

Search component must define:

- Query state.
- Debounce behavior.
- Local vs remote search.
- Suggestions.
- Recent searches.
- No-results state.
- Privacy of stored queries.

### 38.13 Pagination

Pagination must:

- Load incrementally.
- Avoid duplicate rows.
- Handle retry per page.
- Preserve list position.
- Expose loading state at the correct location.

### 38.14 Tables

Tables are for comparison and dense structured data.

Rules:

- Use tables on iPad/macOS when comparison matters.
- Support sorting when useful.
- Keep columns meaningful.
- Avoid truncating critical values.
- Provide responsive alternatives on iPhone.

### 38.15 Charts

Charts must:

- Have a clear question.
- Use accessible labels.
- Avoid misleading axes.
- Support color-blind interpretation.
- Provide summary text for VoiceOver.
- Avoid chart junk.

### 38.16 Maps

Maps must:

- Request location permission just in time.
- Provide manual search alternative.
- Explain location use.
- Avoid background location unless essential and reviewed.
- Support annotations and selected states accessibly.

### 38.17 Avatars and Badges

Avatars:

- Use initials fallback.
- Avoid exposing private images unexpectedly.
- Provide accessibility labels.

Badges:

- Must communicate status clearly.
- Must not rely on color alone.
- Must avoid excessive visual noise.

### 38.18 Progress Indicators, Toasts, Snackbars, and Banners

Progress indicators:

- Determinate when possible.
- Cancellable for long user-initiated work.

Toasts/snackbars:

- Use for transient, low-risk feedback.
- Include undo when relevant.
- Do not hide critical errors.

Banners:

- Use for persistent system-level state such as offline, sync failure, or account issue.
- Provide action when possible.

### 38.19 Widgets

Widgets must:

- Be glanceable.
- Avoid requiring interaction to understand.
- Respect privacy on lock screen.
- Use timeline updates responsibly.
- Deep link into the relevant app context.

---

## 39. Advanced Swift and Apple Platform Engineering

This chapter expands Chapters 6 through 10. Swift engineering quality is measured by correctness, clarity, isolation, testability, and long-term compatibility.

### 39.1 Foundation Standards

Use Foundation APIs correctly:

- Use `URL`, `URLComponents`, and `URLRequest` instead of manual URL strings.
- Use `Date`, `Calendar`, `DateComponents`, and `Duration` instead of raw timestamps for domain logic.
- Use `FormatStyle` for user-facing formatting.
- Use `Locale`, `TimeZone`, and `Calendar` explicitly when behavior matters.
- Use `Measurement` for units.
- Use `Decimal` for money-like values.

### 39.2 Protocols

Protocols should describe capabilities:

```swift
protocol ProfileLoading: Sendable {
    func profile() async throws -> Profile
}
```

Rules:

- Avoid protocols with vague names.
- Avoid protocols created only for one implementation unless testing or boundary value is real.
- Use associated types when the abstraction benefits from compile-time specificity.
- Use existential `any` intentionally at dependency boundaries.

### 39.3 Generics

Use generics to preserve type safety and remove duplication:

```swift
struct Page<Item: Identifiable & Sendable>: Sendable {
    let items: [Item]
    let nextCursor: String?
}
```

Avoid generics when:

- They make call sites unreadable.
- The abstraction is speculative.
- Runtime polymorphism is clearer.

### 39.4 Extensions

Extensions must be cohesive:

- Group protocol conformances separately.
- Avoid dumping unrelated helpers into global extensions.
- Do not add surprising behavior to standard library types.
- Keep access control tight.

### 39.5 Macros

Use macros when they:

- Remove repetitive, error-prone code.
- Preserve readability.
- Are testable.
- Do not hide important behavior.

Avoid macros for business logic or behavior that maintainers need to debug frequently.

### 39.6 Documentation Standards

Document:

- Public APIs.
- Non-obvious concurrency isolation.
- Security-sensitive decisions.
- Data migration behavior.
- Complex algorithms.
- Architecture decisions.

Use comments to explain why, not what:

```swift
// Keep refresh serialized so concurrent 401 responses do not rotate tokens out of order.
actor TokenRefreshCoordinator { }
```

### 39.7 SwiftUI Optimization

Rules:

- Keep view bodies simple.
- Use stable identity.
- Move heavy computation out of views.
- Avoid broad observable state that invalidates large trees.
- Use `Equatable` domain values.
- Profile before micro-optimizing.

Problem:

```swift
ForEach(items.indices, id: \.self) { index in
    Row(item: items[index])
}
```

Better:

```swift
ForEach(items) { item in
    Row(item: item)
}
```

### 39.8 UIKit and AppKit Modernization

Modern UIKit/AppKit code should:

- Use diffable data sources for complex collections.
- Use compositional layouts where appropriate.
- Keep view controllers thin.
- Use coordinators only when they reduce navigation complexity.
- Avoid retain cycles in delegates, closures, and tasks.
- Bridge into SwiftUI through focused wrappers.

### 39.9 Package Organization

Package boundaries should follow stable ownership:

```text
Packages/
  DesignSystem/
  Networking/
  Persistence/
  Security/
  Analytics/
  FeatureProfile/
  TestSupport/
```

Rules:

- Avoid cross-feature imports.
- Keep package public APIs small.
- Put test doubles in test support modules.
- Document dependency direction.

### 39.10 Architecture Comparison

| Pattern | Strength | Risk | Use When |
|---|---|---|---|
| MVVM | Simple SwiftUI fit | View models become too large | Feature complexity is moderate |
| The Composable Architecture-like reducer | Testable state transitions | Boilerplate and learning curve | Complex state and effects |
| Clean Architecture | Strong boundaries | Over-abstraction | Large, long-lived products |
| MVC/UIKit | Framework-native | Massive controllers | Legacy or simple UIKit screens |

Choose architecture per product scale, not trend.

---

## 40. Advanced AI Engineering

AI features must be engineered as probabilistic systems with explicit safety, evaluation, privacy, UX, and fallback design. AI must not bypass the quality standards in this manual.

### 40.1 AI Capability Taxonomy

| Capability | Examples | Primary Risk |
|---|---|---|
| Classification | Categorize support request | Bias, misclassification |
| Extraction | Pull dates from text | Missing or wrong fields |
| Generation | Draft message | Hallucination, tone mismatch |
| Summarization | Condense notes | Omitted critical detail |
| Retrieval | Answer from documents | Bad grounding |
| Tool use | Create event, edit file | Unsafe action |

### 40.2 Prompt Engineering

Prompts must define:

- Role.
- Task.
- Context.
- Constraints.
- Output schema.
- Safety rules.
- Examples when useful.
- Refusal or fallback behavior.

Example:

```text
Task: Summarize the user's selected note.
Constraints:
- Use only the provided note.
- Do not infer facts not present.
- Preserve dates and names exactly.
- Return JSON matching the schema.
```

### 40.3 Context Engineering

Context is a budgeted resource:

- Include only relevant context.
- Prefer structured context over raw dumps.
- Preserve source identifiers.
- Separate user content from system instructions.
- Redact secrets.
- Limit stale context.

### 40.4 Tool Calling

Tool-calling AI must:

- Use explicit schemas.
- Validate arguments before execution.
- Require confirmation for destructive or external actions.
- Log tool decisions safely.
- Handle tool failure.
- Avoid repeated unsafe retries.

### 40.5 Apple Intelligence and Foundation Models

When Apple Intelligence or Foundation Models APIs are available and suitable:

- Prefer on-device execution for private user content.
- Check availability and device support.
- Respect user settings.
- Provide non-AI fallback for critical workflows.
- Do not promise AI behavior on unsupported devices.
- Keep generated content editable.

### 40.6 RAG, Embeddings, and Vector Search

RAG systems must define:

- Source corpus.
- Chunking strategy.
- Embedding model.
- Index update strategy.
- Retrieval filters.
- Reranking if needed.
- Citation requirements.
- Evaluation dataset.
- Privacy classification.

RAG answer rule:

```text
If retrieved context does not support the answer, say so or ask for more information.
Do not fill gaps with model guesses.
```

### 40.7 Hallucination Mitigation

Use:

- Grounding.
- Citations.
- Output schemas.
- Confidence thresholds.
- Human review for high-impact actions.
- Deterministic validation.
- Post-generation checks.
- Refusal paths.

### 40.8 AI UX

AI UX must make uncertainty visible:

- Show what input was used.
- Let users review before applying.
- Provide regenerate/edit controls.
- Explain limitations in context.
- Avoid anthropomorphic overclaiming.
- Preserve user control.

### 40.9 AI Privacy

AI privacy rules:

- Do not send private data to external models without explicit product policy and user trust basis.
- Redact secrets.
- Avoid retaining prompts longer than necessary.
- Do not log raw sensitive prompts.
- Classify embeddings as derived sensitive data when generated from private content.

### 40.10 AI Evaluation

Every AI feature must have an evaluation plan:

| Evaluation Type | Purpose |
|---|---|
| Golden set | Regression on known examples |
| Adversarial set | Failure and abuse cases |
| Multilingual set | Localization quality |
| Safety set | Harmful or private content |
| Human review | Product quality and trust |
| Online monitoring | Drift and real-world failures |

### 40.11 Fallback Strategies

Fallbacks:

- Manual workflow.
- Template-based output.
- Reduced model capability.
- Cached result.
- Ask user for clarification.
- Defer action with clear status.

Never block critical user workflows solely because AI is unavailable.

---

## 41. Enterprise Security and Privacy Engineering

This chapter expands Chapters 13 and 14 into an enterprise security model.

### 41.1 Threat Modeling

Use STRIDE or equivalent for high-risk features:

| Threat | Question |
|---|---|
| Spoofing | Can an attacker pretend to be someone else? |
| Tampering | Can data or code be modified? |
| Repudiation | Can actions be denied without auditability? |
| Information disclosure | Can private data leak? |
| Denial of service | Can the app or service be made unavailable? |
| Elevation of privilege | Can permissions be bypassed? |

Threat models must identify assets, actors, trust boundaries, mitigations, and residual risk.

### 41.2 OWASP Mobile and MASVS

Security-sensitive work should be reviewed against OWASP MASVS categories:

- Architecture, design, and threat modeling.
- Data storage and privacy.
- Cryptography.
- Authentication and session management.
- Network communication.
- Platform interaction.
- Code quality and build settings.
- Resilience against reverse engineering where required.

### 41.3 Authentication and Authorization

Authentication verifies identity. Authorization verifies permission.

Rules:

- Keep auth state explicit.
- Handle session expiration.
- Rotate tokens safely.
- Store tokens in Keychain.
- Scope tokens minimally.
- Never trust client-side authorization alone for server-protected resources.

### 41.4 Token Lifecycle

Token lifecycle must define:

- Issuance.
- Storage.
- Refresh.
- Expiration.
- Revocation.
- Logout deletion.
- Device migration behavior.
- Error handling.

Token refresh must be serialized to avoid race conditions.

### 41.5 Secure Enclave and Biometrics

Use Secure Enclave-backed keys when high-value local secrets require hardware protection.

Rules:

- Use LocalAuthentication access control.
- Handle biometric enrollment changes.
- Provide recovery strategy.
- Avoid using biometrics as identity proof by itself for server authorization.

### 41.6 Certificate Pinning

Pinning decision tree:

```text
Is the app protecting high-value traffic against compromised CA scenarios?
  No -> Use standard TLS validation.
  Yes -> Can operations rotate certificates safely?
    No -> Do not pin.
    Yes -> Pin public keys with backup pins and remote kill strategy.
```

Pinning without operational maturity can create outages.

### 41.7 Jailbreak, Tamper, and Reverse Engineering

Use resilience techniques only for justified risk:

- Jailbreak signals can inform risk scoring but must not be the only control.
- Obfuscation can slow attackers but not guarantee secrecy.
- Server-side controls remain essential.
- Do not store critical business secrets only in the client.

### 41.8 Logging Security

Logs must never include:

- Access tokens.
- Refresh tokens.
- Passwords.
- Private keys.
- Full personal content.
- Payment data.
- Precise location unless explicitly approved.
- Raw AI prompts containing private data.

### 41.9 Privacy Engineering

Privacy engineering requires:

- Data minimization.
- Purpose limitation.
- Retention policy.
- User deletion/export where appropriate.
- Privacy manifest accuracy.
- Required Reason API compliance.
- Consent and tracking review.

---

## 42. Performance Engineering Deep Standard

Performance is a product feature and a release gate.

### 42.1 Performance Budget Template

```text
Workflow:
Device class:
OS:
Cold launch:
Warm launch:
Time to first content:
Peak memory:
Main-thread blocking:
Network payload:
Battery-sensitive work:
Regression threshold:
Measurement tool:
Owner:
```

### 42.2 Launch Performance

Launch rules:

- Do not perform network calls on launch critical path.
- Do not perform heavy database migrations synchronously without progress strategy.
- Defer analytics initialization when possible.
- Lazy-load feature services.
- Measure cold and warm launch separately.

### 42.3 Scrolling and Rendering

Rules:

- Keep row views cheap.
- Use stable identity.
- Precompute expensive formatting.
- Downsample images.
- Avoid heavy shadows and blur in scrolling content.
- Use pagination for large datasets.

### 42.4 SwiftUI Performance

Common risks:

- Broad observable invalidation.
- Complex type-checking from huge view bodies.
- Expensive computed properties.
- Unstable `id`.
- Excessive geometry readers.

Fixes:

- Split state by concern.
- Extract meaningful subviews.
- Memoize derived data in view model.
- Use Instruments and SwiftUI diagnostics.

### 42.5 Instruments Workflow

Use Instruments for:

- Time Profiler: CPU hotspots.
- Allocations: memory growth.
- Leaks: retain cycles.
- Hangs: main-thread stalls.
- Energy Log: battery issues.
- Network: request behavior.
- Core Animation: frame drops.

### 42.6 Performance Regression Policy

A performance regression must be fixed before release when:

- It affects primary workflow.
- It causes visible stutter.
- It increases crash or memory termination risk.
- It materially increases battery drain.
- It violates documented budgets.

---

## 43. Enterprise Testing Engineering

Testing is risk management. Test depth must scale with user impact, data risk, and change complexity.

### 43.1 Testing Strategy

Each feature must define:

- Unit test scope.
- Integration test scope.
- UI test scope.
- Snapshot test need.
- Accessibility test need.
- Localization test need.
- Performance test need.
- Security test need.

### 43.2 Integration Testing

Integration tests must verify boundaries:

- Repository with local database.
- Network decoding and error mapping.
- Cache invalidation.
- Migration behavior.
- Auth refresh behavior.
- Offline queue behavior.

### 43.3 Accessibility Testing

Accessibility tests must verify:

- Labels.
- Traits.
- Dynamic Type.
- Focus order.
- Color-independent state.
- Reduce Motion.

Manual VoiceOver review remains required for critical journeys.

### 43.4 Localization Testing

Test:

- Long German-like strings.
- Arabic RTL.
- Pseudolocalization.
- Non-Gregorian calendars if relevant.
- Currency and number formatting.
- Plurals.

### 43.5 Security Testing

Security tests should include:

- Keychain storage behavior.
- Token deletion on logout.
- Sensitive log redaction.
- TLS configuration.
- Permission denial flows.
- Local file protection where relevant.

### 43.6 Performance Testing

Performance tests must use realistic datasets and device classes. Avoid benchmarking only on high-end development machines.

### 43.7 TestFlight Validation

TestFlight validation must include:

- Fresh install.
- Upgrade install.
- Auth.
- Primary workflow.
- Offline behavior.
- Push/background behavior if applicable.
- Crash and analytics monitoring.
- App Store metadata smoke review.

---

## 44. App Store Engineering

App Store success requires product honesty, technical compliance, privacy accuracy, and operational readiness.

### 44.1 Submission Workflow

```text
Finalize build -> Archive -> Validate -> Upload -> TestFlight smoke test
-> Metadata review -> Privacy review -> App Review notes -> Submit
-> Monitor review -> Release/phased release -> Monitor production
```

### 44.2 Metadata

Metadata must be accurate:

- Name.
- Subtitle.
- Description.
- Keywords.
- Screenshots.
- Preview videos.
- Category.
- Age rating.
- Support URL.
- Privacy policy URL.

Do not mention features unavailable in the submitted build.

### 44.3 Screenshots

Screenshots must:

- Match current UI.
- Avoid misleading claims.
- Represent supported devices.
- Avoid private data.
- Show real product value.
- Be localized when the listing is localized.

### 44.4 Review Notes

Review notes should include:

- Demo account if required.
- Steps to access reviewed features.
- Explanation of permissions.
- Notes for background modes.
- Notes for regulated content.
- Contact for review questions.

### 44.5 Privacy Manifest and Nutrition Labels

Privacy declarations must match implementation:

- Data collected.
- Purpose.
- Linked to user or not.
- Tracking or not.
- Third-party SDK behavior.
- Required Reason APIs.

Review privacy every time dependencies, analytics, permissions, or AI data flows change.

### 44.6 Common Rejections

Common rejection causes:

- Incomplete app or broken flows.
- Misleading metadata.
- Permission purpose mismatch.
- Missing account deletion.
- In-app purchase violations.
- Crashes.
- Hidden features.
- Privacy disclosure mismatch.
- Background mode misuse.

### 44.7 Release and Rollback

Rollback options are limited in App Store distribution. Mitigation must be designed:

- Feature flags.
- Server-side kill switches.
- Phased release pause.
- Hotfix build.
- Backward-compatible migrations.
- Defensive client behavior.

---

## 45. Engineering Decision Trees

### 45.1 Architecture Decision Tree

```text
Is the feature simple and local?
  Yes -> Use local SwiftUI state and small view model.
  No -> Does it coordinate data, navigation, or side effects?
    Yes -> Use MVVM with repository/use-case boundaries.
    No -> Keep simple.
  Does state have complex transitions?
    Yes -> Use explicit state machine or reducer pattern.
  Does the feature need independent ownership or build isolation?
    Yes -> Create feature module.
```

### 45.2 Navigation Decision Tree

```text
Is it a top-level destination?
  Yes -> Tab or sidebar.
Is it a child object?
  Yes -> Navigation stack.
Is it a focused temporary task?
  Yes -> Sheet.
Is it immersive or required before continuing?
  Yes -> Full-screen presentation only if justified.
```

### 45.3 SwiftUI vs UIKit/AppKit Decision Tree

```text
Can SwiftUI provide native behavior with acceptable quality?
  Yes -> Use SwiftUI.
  No -> Is UIKit/AppKit control mature and appropriate?
    Yes -> Wrap or implement in UIKit/AppKit.
    No -> Build custom only after accessibility/performance plan.
```

### 45.4 Networking Decision Tree

```text
Is data remote?
  Yes -> Define request, response, errors, cache, retry, cancellation.
Does request mutate state?
  Yes -> Ensure idempotency or duplicate prevention.
Can it fail offline?
  Yes -> Define offline behavior.
Contains sensitive data?
  Yes -> Redact logs and classify data.
```

### 45.5 Persistence Decision Tree

```text
Preference-like and non-sensitive? -> UserDefaults/AppStorage.
Secret? -> Keychain.
Structured relational local data? -> SwiftData/Core Data.
Large binary? -> File storage + metadata.
Cache? -> Explicit TTL and invalidation.
```

### 45.6 Concurrency Decision Tree

```text
Is work UI state mutation? -> MainActor.
Is shared mutable state accessed across tasks? -> Actor.
Is work cancellable from UI lifecycle? -> Structured task.
Is work independent and long-lived? -> Explicit owner and cancellation.
Does data cross concurrency boundary? -> Sendable.
```

### 45.7 Authentication and Authorization Decision Tree

```text
Does action require identity? -> Authenticate.
Does identity have permission? -> Authorize server-side.
Does token expire? -> Refresh safely.
Is operation sensitive? -> Consider biometric reauthentication.
```

### 45.8 AI Decision Tree

```text
Can deterministic code solve it reliably?
  Yes -> Do not use AI.
Does AI output affect high-impact decision?
  Yes -> Require human review and grounding.
Does it require private data?
  Yes -> Prefer on-device or explicit privacy approval.
Can failure block critical workflow?
  Yes -> Provide non-AI fallback.
```

### 45.9 Testing Decision Tree

```text
Pure logic? -> Unit test.
Boundary integration? -> Integration test.
Critical user journey? -> UI test.
Visual contract? -> Snapshot test.
Performance-sensitive? -> Performance test.
Security-sensitive? -> Security test.
Localized UI? -> Localization test.
```

### 45.10 Security Decision Tree

```text
Does feature store/transmit personal data?
  Yes -> Classify, minimize, protect, disclose.
Does it handle secrets?
  Yes -> Keychain/Secure Enclave.
Does it cross trust boundary?
  Yes -> Threat model.
Could failure harm users?
  Yes -> Security review required.
```

---

## 46. Enterprise Checklist Library

### 46.1 Product Checklist

- Problem validated.
- Target user defined.
- Success metric defined.
- Guardrail metrics defined.
- Non-goals documented.
- Feature removal path considered.
- Analytics privacy reviewed.

### 46.2 UX Checklist

- Primary journey clear.
- Cognitive load minimized.
- Empty/error/offline states complete.
- Undo/confirmation appropriate.
- Onboarding justified.
- Settings not used as design escape.
- Trust cues present.

### 46.3 UI Checklist

- Native controls used where appropriate.
- Layout adaptive.
- Dynamic Type tested.
- Dark mode tested.
- RTL considered.
- Components use design tokens.
- No broken controls.

### 46.4 Accessibility Checklist

- VoiceOver labels and order.
- Traits and actions.
- Dynamic Type.
- Contrast.
- Reduce Motion.
- Keyboard/focus.
- Color-independent state.

### 46.5 Localization Checklist

- All user strings localizable.
- No concatenated sentences.
- Plurals handled.
- Dates/numbers formatted.
- RTL tested.
- Pseudolocalization reviewed.

### 46.6 Architecture Checklist

- Boundaries clear.
- Dependencies injected.
- Domain models explicit.
- Data flow documented.
- Concurrency isolation defined.
- Test seams available.
- ADR added for significant decisions.

### 46.7 Swift Checklist

- No routine force unwraps.
- Errors modeled.
- Sendable considered.
- Names clear.
- APIs avoid Boolean traps.
- Documentation added where useful.

### 46.8 SwiftUI Checklist

- State owner correct.
- View body readable.
- Stable list identity.
- No network work in body.
- Previews for key states.
- Accessibility semantics.

### 46.9 Performance Checklist

- Launch path reviewed.
- Main thread work minimized.
- Images downsampled.
- Caches bounded.
- Scrolling profiled if complex.
- Battery-sensitive work minimized.

### 46.10 Security Checklist

- Threat model for high-risk work.
- Secrets in Keychain.
- Logs redacted.
- TLS correct.
- Permissions justified.
- Token lifecycle safe.

### 46.11 Privacy Checklist

- Data minimized.
- Purpose documented.
- Retention defined.
- Deletion/export considered.
- Privacy manifest updated.
- AI data handling reviewed.

### 46.12 Networking Checklist

- HTTPS.
- Status codes mapped.
- Cancellation.
- Retry policy.
- Timeout.
- Offline behavior.
- Sensitive data redaction.

### 46.13 Database Checklist

- Schema versioned.
- Migration tested.
- Queries bounded.
- Indexes defined.
- Sensitive data protected.
- Large data tested.

### 46.14 AI Checklist

- Deterministic alternative considered.
- Prompt and context designed.
- Grounding provided.
- Evaluation set exists.
- Human review for high-impact output.
- Privacy reviewed.
- Fallback exists.

### 46.15 Testing Checklist

- Unit tests.
- Integration tests.
- UI tests for critical journeys.
- Accessibility checks.
- Localization checks.
- Performance tests where needed.
- Regression tests for bug fixes.

### 46.16 Bug Fix Checklist

- Root cause identified.
- Regression test added when practical.
- Adjacent states checked.
- User impact understood.
- Monitoring reviewed.

### 46.17 Refactoring Checklist

- Behavior preserved.
- Tests exist or added.
- Scope controlled.
- Naming improved.
- Dead code removed.
- Architecture clearer.

### 46.18 Code Review Checklist

- Correctness.
- UX completeness.
- Architecture.
- Security.
- Privacy.
- Performance.
- Accessibility.
- Tests.
- Maintainability.

### 46.19 App Store Checklist

- Metadata accurate.
- Screenshots current.
- Privacy labels correct.
- Review notes prepared.
- Account deletion if required.
- Permission strings correct.
- No hidden/broken features.

### 46.20 Release Checklist

- Build validated.
- TestFlight smoke tested.
- Release notes ready.
- Monitoring ready.
- Rollout plan.
- Rollback/mitigation plan.
- Support team informed where applicable.

---

## 47. Expanded Anti-Pattern Library

Each anti-pattern must be identified, explained, and corrected.

### 47.1 Massive View Model

Why it happens: Teams put networking, formatting, navigation, validation, analytics, and persistence into one object.

Why dangerous: It becomes hard to test, hard to reason about, and easy to break.

How to identify:

- Hundreds of lines.
- Many unrelated dependencies.
- Multiple workflows in one model.
- Tests require excessive setup.

Fix:

- Extract repositories.
- Extract formatters/presenters.
- Extract validators.
- Model state explicitly.

### 47.2 Stringly Typed Domain

Why it happens: API strings leak into app logic.

Danger: Invalid states compile, analytics drift, and refactors miss cases.

Fix:

```swift
enum SubscriptionStatus: String, Codable, Sendable {
    case trial
    case active
    case pastDue
    case canceled
}
```

### 47.3 Hidden Singleton Dependency

Why it happens: Convenience.

Danger: Tests are brittle, behavior is global, concurrency is unclear.

Fix: Use initializer or environment injection.

### 47.4 Placeholder UX

Why it happens: Feature pressure.

Danger: Users encounter dead ends and App Review may reject incomplete apps.

Fix: Remove entry point or complete the flow.

### 47.5 Unbounded Cache

Why it happens: Performance issue solved locally without lifecycle policy.

Danger: Memory growth, disk bloat, privacy retention.

Fix: Define TTL, size limit, eviction, and privacy classification.

### 47.6 AI as Magic Button

Why it happens: AI feature added without workflow design.

Danger: Untrusted output, hallucination, poor recovery, privacy risk.

Fix: Provide grounding, review, editability, and fallback.

### 47.7 Permission Wall

Why it happens: App asks for all permissions at launch.

Danger: Low trust and poor conversion.

Fix: Ask just in time with contextual value.

### 47.8 Custom Control Without Semantics

Why it happens: Visual design implemented with gestures and stacks.

Danger: Accessibility failure, keyboard/focus failure, inconsistent behavior.

Fix: Use native control or implement full accessibility contract.

---

## 48. Reference Implementations

### 48.1 Network Client

```swift
protocol APIRequest: Sendable {
    associatedtype Response: Decodable & Sendable
    var method: String { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
    var body: Data? { get }
}

struct URLSessionHTTPClient: Sendable {
    let baseURL: URL
    let session: URLSession

    func send<Request: APIRequest>(_ request: Request) async throws -> Request.Response {
        var components = URLComponents(url: baseURL.appending(path: request.path), resolvingAgainstBaseURL: false)
        components?.queryItems = request.queryItems.isEmpty ? nil : request.queryItems
        guard let url = components?.url else { throw NetworkError.invalidURL }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = 30

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard 200..<300 ~= http.statusCode else { throw NetworkError.httpStatus(http.statusCode) }
        return try JSONDecoder().decode(Request.Response.self, from: data)
    }
}
```

### 48.2 Keychain Wrapper

```swift
struct KeychainStore: Sendable {
    func save(_ data: Data, account: String, service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandled(status) }
    }
}
```

### 48.3 Localized Formatting

```swift
struct TripDateFormatter: Sendable {
    func displayRange(start: Date, end: Date, locale: Locale, calendar: Calendar) -> String {
        let format = DateInterval.FormatStyle(date: .abbreviated, time: .omitted)
            .locale(locale)
            .calendar(calendar)
        return format.format(DateInterval(start: start, end: end))
    }
}
```

### 48.4 Accessibility-Friendly Error View

```swift
struct ErrorStateView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button(action: retry) {
                Label("Retry", systemImage: "arrow.clockwise")
            }
        }
        .accessibilityElement(children: .contain)
    }
}
```

### 48.5 Repository with Cache Policy

```swift
protocol ArticleRepository: Sendable {
    func articles(policy: CachePolicy) async throws -> [Article]
}

enum CachePolicy: Sendable {
    case cacheFirst(maxAge: Duration)
    case networkFirst
    case cacheOnly
}
```

---

## 49. Future Compatibility Standards

Future compatibility is an operating discipline. Apple platforms evolve every year; this project must be able to adopt new capabilities without destabilizing core workflows.

### 49.1 Future iOS and iPadOS

- Avoid device-specific assumptions.
- Test split view and Stage Manager.
- Use availability checks.
- Keep permissions minimal.
- Watch for HIG updates.

### 49.2 Future macOS

- Respect keyboard, menus, windows, and pointer.
- Avoid iOS-only assumptions in shared code.
- Keep AppKit bridges isolated.
- Test multi-window behavior.

### 49.3 Future watchOS

- Keep workflows glanceable.
- Avoid heavy networking on watch.
- Respect battery.
- Use complications responsibly.

### 49.4 Future visionOS

- Keep spatial design adaptable.
- Avoid hard-coded depth assumptions.
- Prefer system affordances for comfort.
- Test readable scale and motion.

### 49.5 Future tvOS

- Preserve focus semantics.
- Keep controls large.
- Avoid dense text input.
- Test remote navigation.

### 49.6 Future Swift

- Track Swift language evolution.
- Adopt stricter concurrency checking.
- Prefer Sendable-safe models.
- Avoid deprecated patterns.
- Keep public APIs source-stable where possible.

### 49.7 Future SwiftUI

- Prefer standard SwiftUI APIs.
- Avoid depending on undocumented behavior.
- Isolate workarounds.
- Revisit custom controls when SwiftUI gains native replacements.

### 49.8 Future Xcode

- Keep build settings documented.
- Avoid fragile script phases.
- Keep CI images updated.
- Treat new warnings as modernization opportunities.

### 49.9 Future Apple Intelligence

- Design AI boundaries independent of one model.
- Keep evaluation datasets.
- Prefer on-device privacy-preserving capabilities when sufficient.
- Support fallback for unsupported devices.

---

## 50. Expanded Codex Constitution

This chapter extends Chapter 23. Codex is not merely a code generator in this project. Codex is required to act as an engineering agent operating under this constitution.

### 50.1 Codex Permanent Duties

Within the current task scope, Codex must continuously:

- Review.
- Audit.
- Improve.
- Optimize.
- Refactor.
- Modernize.
- Secure.
- Document.
- Test.
- Validate.
- Polish.
- Simplify.
- Redesign poor UX.
- Improve weak UI.
- Improve architecture.
- Improve maintainability.
- Improve accessibility.
- Improve performance.
- Improve scalability.

Codex does not need a separate explicit user request to make clearly beneficial local improvements that are safe, scoped, and aligned with the current task.

### 50.2 Codex Scope Discipline

Codex must distinguish:

| Improvement Type | Action |
|---|---|
| Local and clearly beneficial | Implement within current task |
| Broader but related | Document and recommend follow-up |
| Risky or destructive | Ask for explicit approval |
| Unrelated refactor | Do not perform |

### 50.3 Codex Product Stewardship

When touching product code, Codex must ask:

- Does this improve user value?
- Does this preserve trust?
- Does this reduce cognitive load?
- Does this complete all states?
- Does this maintain Apple platform quality?

### 50.4 Codex Architecture Stewardship

Codex must improve architecture by:

- Respecting dependency direction.
- Removing hidden global coupling.
- Making state explicit.
- Adding test seams.
- Keeping modules cohesive.
- Avoiding speculative abstractions.

### 50.5 Codex UX and UI Stewardship

Codex must not preserve poor UX merely because it already exists in touched code. Within scope, Codex must:

- Fix broken controls.
- Complete states.
- Improve labels.
- Align components.
- Respect accessibility.
- Use native patterns.
- Remove placeholder UI.

### 50.6 Codex Security Stewardship

Codex must treat secrets, personal data, permissions, AI prompts, logs, and external uploads as security-relevant. It must minimize exposure and disclose limitations.

### 50.7 Codex Verification Stewardship

Codex must verify work using the strongest practical signal:

- Build.
- Unit tests.
- UI tests.
- Static checks.
- Visual inspection.
- PDF rendering inspection.
- Manual reasoning only when tooling is unavailable, disclosed clearly.

### 50.8 Codex Final Response Contract

Codex final responses must state:

- What changed.
- Where it changed.
- What was verified.
- What remains unverified, if anything.
- Any follow-up that materially improves the product.

---

End of manual.

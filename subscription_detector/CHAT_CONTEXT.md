# Subscription Detector Chat Context

This folder contains the Flutter MVP built during the Codex chat for:

- Arabic name: كاشف الاشتراكات
- English name: Subscription Detector

Implemented scope:

- Clean Architecture with feature-first structure.
- Arabic and English UI.
- SAR and USD currency support.
- Authentication flow with email, Google, and Apple abstractions.
- Firebase-ready authentication datasource with safe fallback.
- PDF and CSV statement import.
- Manual transaction entry.
- Persistent local transaction storage using Hive.
- Subscription detection for monthly, annual, and recurring charges.
- Subscription classification by category and review status.
- Dashboard with subscription totals, spend, and potential savings.
- AI insights layer with local fallback and OpenAI API datasource via `OPENAI_API_KEY`.
- Local notifications layer for payment and monthly review reminders.
- Tests for CSV parsing, subscription detection, and the main sign-in/dashboard flow.

External configuration still required:

- Firebase project files such as `firebase_options.dart`.
- Google and Apple OAuth configuration in Firebase/Apple Developer accounts.
- OpenAI key at runtime through `--dart-define=OPENAI_API_KEY=...`.

Verification completed before repository transfer:

- `flutter analyze`
- `flutter test`
- `flutter build web --no-wasm-dry-run`

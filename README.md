# my-codex

Personal repository for Codex projects, experiments, generated artifacts, and chat handoff notes.

## Price Detector MVP

This repository now includes the Flutter MVP built in this chat: `price_detector`, an app named "Kashif Al-Asaar" / "Price Detector".

Implemented scope:

- Flutter app using Clean Architecture and feature-first structure.
- Riverpod dependency injection and GoRouter navigation.
- Login flow with an in-memory MVP auth repository and Firebase Auth implementation ready for wiring.
- Camera capture screen.
- Google ML Kit OCR repository and OCR text parser.
- Mock market price data source.
- Price analysis result screen.
- Price status classification: excellent, fair, high, overpriced.
- Purchase recommendation: buy now, wait, do not buy.
- Fake discount detection when previous price data exists.
- Search history saved locally with Hive.
- Unit and widget tests for OCR parsing, price analysis, result UI, and history UI.

Run checks:

```powershell
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat test
C:\src\flutter\bin\flutter.bat build apk --debug
```

Debug APK output:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## Existing Repository Content

The remote repository already contained other projects and documentation. This merge keeps that history and content while adding the current Flutter MVP.

Existing content includes:

- Patrol Hub / Safari Y60 related files.
- SwiftUI and Flutter catalog projects.
- Documentation and chat archive files under `docs/`.
- Generated PDFs, scripts, and supporting artifacts.

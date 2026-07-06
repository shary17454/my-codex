# Ask People MVP - Chat Context

This repository was built from a Codex chat to create an MVP for an Arabic social Flutter app named "اسأل الناس".

## Original Product Request

The requested app lets users ask optional or comparative questions such as:

- Should I buy car A or B?
- Which phone is better?
- Which restaurant do you recommend?
- Is this product worth buying?

Questions should reach people interested in the same category so they can vote and comment.

## MVP Scope

The MVP requested:

- Login
- Account creation
- Interest selection
- Home page
- Add new question
- Question category
- Question types:
  - Two-option choice
  - Multiple-option choice
  - Open question
- Voting
- Comments
- Voting results
- Filter questions by interests
- Save questions the user participated in

## Categories

- Cars
- Phones
- Restaurants
- Travel
- Shopping
- Technology
- Devices
- Fashion
- Health
- Education
- Real estate
- Other

## Architecture Direction

The agreed architecture:

- Flutter and Dart
- Clean Architecture
- Feature-first structure
- Repository Pattern
- Riverpod
- GoRouter
- Firebase Authentication
- Firebase Firestore
- Firebase Messaging, Analytics, Crashlytics
- Hive for local storage
- Error handling and logging

Firebase is kept behind repository interfaces so the data layer can be replaced later without changing domain contracts.

## Implemented Work

The repository includes:

- Flutter project scaffold
- Feature-first folders
- Core constants, errors, logging, and shared widgets
- Routing with GoRouter
- Theme setup
- Auth domain/data/presentation layers
- Profile and interests layers
- Firebase-backed repository implementations prepared for real backend use
- Local demo MVP mode when Firebase config is missing
- Arabic start page
- Login and register screens
- Interest selection screen
- Home feed with category and interest filtering
- Create question screen
- Question details screen
- Voting and results
- Comments
- Follow/save behavior
- Saved/participated questions screen
- Standalone HTML MVP demo in `web_start/mvp.html`

## Verification Performed

The project was checked with:

- `flutter analyze`
- `flutter test`

Both passed after the latest implementation.

## Known Environment Notes

- Firebase project files are not included because they require a real Firebase project and credentials.
- Windows desktop build failed in this environment because the Visual Studio toolchain was not installed.
- Chrome was detected as a Flutter target and a run attempt was started.
- A standalone HTML version exists and can be opened directly without Firebase or Flutter build tooling.


# 🎭 MafMof — Offline Arabic Social Deduction Game

<p align="center">
  <img src="assets/images/mofmof_app_icon.png" alt="MafMof App Icon" width="120" />
</p>

<p align="center">
  <strong>A host-led Arabic mystery party game built offline-first with Flutter, Drift, BLoC, and go_router.</strong>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" />
  <img alt="License" src="https://img.shields.io/badge/license-MIT-green" />
  <img alt="CI" src="https://github.com/esmael-mohsen/mafmof-offline-mystery-game/actions/workflows/flutter-ci.yml/badge.svg" />
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white" />
</p>

---

## 📖 Overview

**MafMof** is an offline-first Arabic social deduction game designed for host-led in-person play sessions. Inspired by party games like Mafia and Cluedo, it layers a mystery narrative on top of classic role-reveal mechanics — with full RTL support and a carefully designed host UX.

The app ships with **Case 01**, a complete mystery scenario, supporting **5, 6, 7, and 8 player** configurations. Every role assignment, clue, voting round, and narrative reveal happens locally — no internet, no backend, no accounts required.

This project is an Android-first Flutter MVP demonstrating clean architecture, a seeded local SQLite database, and safe state management for a real multi-player card game experience.

---

## 🌟 Why This Project

This codebase was built to solve real problems that show up in offline game apps:

- **Role privacy during reveal** — only the active player sees their role at the right moment; the screen is designed to prevent accidental reveals.
- **Idempotent database seeding** — game content (cases, roles, clues) is seeded from bundled JSON into SQLite using `OnConflictStrategy.replace`, meaning reinstalls and restarts never corrupt state.
- **Safe session teardown** — timers and BLoC streams are disposed deterministically even when the app is force-closed.
- **RTL-first layout** — all screens are built Arabic-first with Cairo and Amiri fonts, RTL text directionality, and tested for long-text overflow.
- **Mid-range device performance** — optimized for the sub-2s key transition target on mid-range Android hardware.

---

## ✨ Key Features

| Feature | Details |
|---|---|
| 🕵️ Mystery cases | Bundled Case 01 with complete roles, clues, and narrative flow |
| 👥 Player variants | 5, 6, 7, and 8 player configurations per case |
| 🎭 Role reveal | Private per-player role screen with tap-to-reveal |
| 🗳️ Voting rounds | Structured elimination voting with animated transitions |
| ⏱️ Game timer | Configurable phase timer with safe disposal |
| 🔊 Sound effects | Optional SFX for reveals, votes, and win states via `SafeAudioService` |
| 🌙 Arabic / RTL | Full right-to-left layout, Arabic typography, long-text safe |
| 📴 100% offline | Zero internet dependency during gameplay |
| 🗄️ Local database | Drift/SQLite seeded from JSON assets; idempotent on reinstall |

---

## 🎮 Gameplay Flow

```
App Launch
  └─► Home / Case Catalog
        └─► Case Details (narrative, roles overview)
              └─► Player Setup (enter player names, select count)
                    └─► Role Assignment (private reveal per player)
                          └─► Game Stage (host-narrated phases + timer)
                                ├─► Clue Reveal
                                ├─► Voting Round (multiple rounds)
                                └─► Final Reveal (winner announced)
```

The **Host** controls the app throughout. Players pass the device for private role reveal. All game state is managed locally in the Drift database and synchronized through BLoC/Cubit streams.

---

## 🏗️ Architecture

This project follows **feature-first clean architecture**:

```
lib/
├── app/
│   ├── app.dart               # Root MaterialApp
│   ├── router/                # go_router configuration
│   ├── theme/                 # App-wide ThemeData, typography, colors
│   └── di/                    # get_it / injectable setup
├── core/
│   ├── audio/                 # SafeAudioService (audioplayers wrapper)
│   ├── constants/             # App-wide constants
│   ├── database/              # Drift database, DAOs, seed logic
│   ├── errors/                # Failure types
│   ├── utils/                 # Shared utilities
│   └── widgets/               # Reusable UI widgets
└── features/
    └── game/
        ├── data/              # Repository implementations, DTOs
        ├── domain/            # Entities, repository interfaces, use cases
        └── presentation/      # Cubits, pages, widgets
```

### Key Architectural Decisions

- **Drift/SQLite** — single source of truth for all game content and session state.
- **BLoC/Cubit** — all game session state is managed in dedicated Cubits; UI never mutates state directly.
- **go_router** — declarative routing with redirect guards for invalid session states.
- **get_it + injectable** — compile-time DI with code generation; no service locator anti-pattern leaks into UI.
- **Repository pattern** — data sources are abstracted behind domain interfaces.

---

## 🗄️ Offline-First Data Model

Game content lives in `assets/data/cases/` as JSON files. On first launch, the database is seeded using `OnConflictStrategy.replace` — making the seed operation safe to repeat on reinstall or schema migration.

```
assets/data/cases/
├── case_01_5p.json    # 5-player variant
├── case_01_6p.json    # 6-player variant
├── case_01_7p.json    # 7-player variant
└── case_01_8p.json    # 8-player variant
```

The Drift schema covers:
- `cases` — case metadata and narrative
- `roles` — all role definitions per case variant
- `clues` — ordered clue content per case
- `sessions` — active game session (one at a time)
- `session_players` — player ↔ role assignments per session

---

## 🧭 Routing & Session Safety

go_router handles all navigation. Route guards ensure:
- Players cannot reach the game stage without a valid active session.
- An orphaned session from a force-close returns the user to a safe home state on relaunch.
- The role reveal screen is only accessible in the correct game phase.

No session data leaks between game runs.

---

## 🧪 Testing Strategy

```
test/
├── app/router/        # Route guard tests (invalid routes, redirects)
├── core/              # Database seed, DAO unit tests
├── features/game/     # Cubit unit tests, use case tests
└── support/           # Test helpers and mock factories
```

Run all tests:

```bash
flutter test
```

Run with verbose output:

```bash
flutter test --reporter expanded
```

---

## 📸 Screenshots

| Screen | Preview |
|---|---|
| Home / Case Catalog | 🖼️ Screenshot coming soon |
| Case Details | 🕵️ Screenshot coming soon |
| Player Setup | 👥 Screenshot coming soon |
| Role Reveal (Arabic) | 🎭 Screenshot coming soon |
| Game Stage / Timer | 🎬 Screenshot coming soon |
| Voting Round | 🗳️ Screenshot coming soon |
| Final Reveal | 🏁 Screenshot coming soon |

> Screenshots will be added from a device/emulator run. See `screenshots/` folder.

---

## 🎬 Demo

> 📱 APK demo build — coming soon.
>
> To run locally, follow the Getting Started steps below.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.x` ([install](https://docs.flutter.dev/get-started/install))
- Dart SDK `^3.x` (included with Flutter)
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device (Android-first)

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/esmael-mohsen/mafmof-offline-mystery-game.git
cd mafmof-offline-mystery-game

# 2. Install dependencies
flutter pub get

# 3. Generate code (Drift DAOs, injectable, JSON serialization)
dart run build_runner build --delete-conflicting-outputs

# 4. Run on Android
flutter run
```

### Verify code quality

```bash
flutter analyze
flutter test
```

---

## 📦 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x / Dart 3.x |
| State management | flutter_bloc (Cubit) |
| Local database | Drift (type-safe SQLite ORM) |
| Navigation | go_router |
| Dependency injection | get_it + injectable |
| JSON serialization | json_serializable |
| Audio | audioplayers (with SafeAudioService fallback) |
| Code generation | build_runner, drift_dev, injectable_generator |
| Typography | Cairo, Amiri, Aref Ruqaa Ink (Arabic), Manrope, Cormorant Garamond |
| CI | GitHub Actions (flutter-ci.yml) |

---

## 🔮 Future Improvements

- [ ] Add Case 02 and Case 03 with different role configurations
- [ ] Implement a replay / spectator mode for the host
- [ ] Add animated role card transitions
- [ ] Localize to English for wider accessibility
- [ ] Add a case content management screen for custom cases
- [ ] Tablet-optimized layout

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

Audio assets are sourced from OpenGameArt under CC0 and CC-BY 3.0 licenses.
See [`docs/audio_licenses.md`](docs/audio_licenses.md) for attribution details.

---

## 👤 Author

**Esmael Mohsen**

- GitHub: [@esmael-mohsen](https://github.com/esmael-mohsen)

---

<p align="center">
  Built with Flutter · Offline-first · Arabic-first · Host-led gameplay
</p>

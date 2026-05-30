# MafMof MVP — Professional Implementation Plan

## 0. Document Purpose

This implementation plan is designed for Spec Kit / coding-agent workflows.

It keeps the project limited to **5 phases** while making each phase detailed enough to implement professionally.

The implementation must prioritize:

1. stability
2. clean architecture
3. local database correctness
4. scalable structure
5. good Host UX
6. smooth but lightweight visuals and sound

---

## 1. Implementation Principles

### Do

- Use Drift/SQLite from the beginning.
- Use feature-first clean architecture.
- Keep game state centralized.
- Use go_router for app routing.
- Use get_it/injectable for dependencies.
- Use local JSON seeding for case content.
- Use local optimized images and SFX.
- Write code that can scale to more cases later.
- Keep phases limited and focused.

### Do Not

- Add backend.
- Add authentication.
- Add online multiplayer.
- Hardcode gameplay directly into widgets.
- Use static Dart-only case data as the primary gameplay source.
- Over-engineer every small action into a separate class if unnecessary.
- Add heavy animations that hurt performance.
- Add mandatory background music.

---

# Phase 1 — Foundation, Architecture, Routing, DI

## Objective

Create the professional Flutter foundation and skeleton flow before implementing real gameplay logic.

## Scope

This phase establishes:

- Flutter project setup
- folder structure
- architecture boundaries
- routing
- dependency injection
- theme foundation
- placeholder screens
- audio service contract

## Required Dependencies

### Runtime

```yaml
flutter_bloc
equatable
go_router
drift
sqlite3_flutter_libs
path_provider
path
get_it
injectable
json_annotation
audioplayers
```

### Dev

```yaml
build_runner
drift_dev
injectable_generator
json_serializable
```

Optional only if later needed:

```yaml
freezed
freezed_annotation
```

## Folder Structure

Create:

```text
lib/
  app/
    app.dart
    router/
    theme/
    di/

  core/
    database/
    audio/
    constants/
    errors/
    utils/
    widgets/

  features/
    game/
      data/
      domain/
      presentation/
```

## Routing

Set up go_router with placeholder routes:

```text
/
 /case/:caseId
 /case/:caseId/setup
 /game/:sessionId/reveal
 /game/:sessionId/dashboard
 /game/:sessionId/stage/:stageNumber
 /game/:sessionId/voting/:stageNumber
 /game/:sessionId/final
```

Create route constants and route names.

## Dependency Injection

Set up:

```text
get_it
injectable
configureDependencies()
```

At this phase, register:

- AppRouter
- AudioService
- placeholder database provider if needed
- GameCubit placeholder

## Theme

Create a base dark cinematic theme:

- dark background
- warm gold accent
- readable Arabic font configuration
- clear button style
- card style
- warning/error colors

Do not over-polish yet.

## Screens

Create placeholder versions of:

- HomeScreen
- CaseDetailsScreen
- SetupScreen
- RoleRevealScreen
- HostDashboardScreen
- StageScreen
- VotingScreen
- FinalRevealScreen

Each screen should have enough layout to validate navigation.

## Audio Contract

Create:

```dart
abstract class AudioService {
  Future<void> playSfx(String key);
  Future<void> setEnabled(bool enabled);
  bool get isEnabled;
}
```

Create a simple implementation that does not crash even if files are missing.

## Phase 1 Deliverables

- Flutter app runs.
- go_router navigation works.
- DI initializes.
- Theme is applied.
- Placeholder screens exist.
- Basic AudioService exists.
- Project structure is clean.

## Phase 1 Acceptance Criteria

- App launches without runtime errors.
- All placeholder routes are reachable.
- No raw Navigator is used for main flow.
- DI setup compiles with generated files.
- Theme is centralized.
- No real database/gameplay required yet.

---

# Phase 2 — Drift Database, JSON Seeding, Data Layer

## Objective

Create the offline-first local data foundation.

The app must load Case 01 and all four variants from local SQLite through Drift.

## Scope

This phase implements:

- Drift database
- tables
- seed metadata
- bundled JSON case data
- seeding service
- local datasource
- repository implementation
- domain entities
- data mapping

## Database Tables

Create Drift tables for at least:

```text
app_settings
seed_metadata
cases
case_variants
characters
variant_characters
role_assignments
stages
```

Optional but recommended:

```text
sound_effects
```

Session persistence tables can be added now or later:

```text
game_sessions
session_players
votes
```

For MVP, active game session may stay in memory, but table design should not block future persistence.

## Required Table Concepts

### cases

Stores general case information.

### case_variants

Stores each playable version of a case by player count.

### characters

Stores character base data.

### variant_characters

Maps characters to variants and marks active players vs NPC evidence.

### role_assignments

Stores role/team/tasks/special ability per character per variant.

### stages

Stores stage text, clue, host notes, expected suspects, discussion time, vote type.

### app_settings

Stores sound enabled and volume.

### seed_metadata

Stores seed version to prevent duplicate seeding.

## JSON Asset

Create:

```text
assets/data/cases/case01_farah_eltagamoa.json
```

The JSON must include:

```text
case metadata
characters
variants
variant characters
role assignments
stages
final explanations
NPC evidence
asset paths
```

## Seeder Requirements

Implement `CaseSeeder`.

Responsibilities:

1. load bundled JSON asset
2. parse JSON into seed models
3. check current seed version
4. insert/update case data transactionally
5. avoid duplicate data
6. store seed metadata
7. fail with meaningful error if JSON is invalid

Seeding should run at app startup before Home loads case list.

## Local Datasource

Create methods:

```dart
Future<List<CaseModel>> getActiveCases();
Future<CaseModel?> getCaseById(String caseId);
Future<CaseVariantModel?> getVariantByPlayerCount(String caseId, int playerCount);
Future<List<CharacterModel>> getCharactersForVariant(String variantId);
Future<List<RoleAssignmentModel>> getRoleAssignmentsForVariant(String variantId);
Future<List<StageModel>> getStagesForVariant(String variantId);
Future<AppSettingsModel> getAppSettings();
Future<void> updateSoundEnabled(bool enabled);
```

## Repository

Create `GameRepository` in domain and implementation in data.

Required methods mirror datasource but return domain entities.

## Mapping

Keep mapping explicit:

```text
Drift rows → data models → domain entities
JSON seed models → Drift companion inserts
```

## Phase 2 Deliverables

- Drift database created.
- JSON case seed added.
- Case 01 seeded locally.
- Four variants retrievable.
- Settings stored locally.
- Repository usable from presentation.

## Phase 2 Acceptance Criteria

- First launch seeds database.
- Second launch does not duplicate case data.
- Case 01 appears from database.
- 5-player variant loads correctly.
- 6-player variant loads correctly.
- 7-player variant loads correctly.
- 8-player variant loads correctly.
- App handles missing/invalid seed gracefully.
- No widget reads JSON directly for gameplay.

---

# Phase 3 — Game Session, Role Reveal, Stage Flow, Timer

## Objective

Implement playable game state up to stage progression.

This phase makes the app able to start a session, reveal roles privately, and navigate through stages.

## Scope

This phase implements:

- setup validation
- game session state
- role assignment loading
- player creation
- private role reveal flow
- host dashboard
- stage display
- discussion timer
- basic SFX triggers

## GameState

Create a robust state object with:

```text
status
selectedCase
selectedVariant
playerCount
playerNames
players
currentRevealIndex
isCurrentCardRevealed
currentStageNumber
currentStage
currentVotes
eliminatedPlayerIds
suspicionMarks
finalAccusedPlayerId
soundEnabled
errorMessage
```

## Status Enum

Recommended:

```text
initial
loading
ready
setup
revealingRoles
hostDashboard
stageInProgress
voting
finalReveal
completed
error
```

## GameCubit Actions

Implement:

```dart
loadInitialData()
selectCase(caseId)
selectPlayerCount(count)
updatePlayerName(index, name)
startGame()
revealCurrentPlayerCard()
hideCurrentPlayerCard()
goToNextReveal()
finishRoleReveal()
goToDashboard()
goToStage(stageNumber)
startTimer()
pauseTimer()
resetTimer()
completeStageDiscussion()
goToVoting()
toggleSound(enabled)
restartGame()
```

Voting resolution can be completed in Phase 4.

## Setup Flow

Requirements:

1. player count must be 5, 6, 7, or 8
2. number of name fields must match player count
3. names cannot be empty
4. duplicate names should show warning or be blocked
5. selected player count loads matching variant
6. players are created in variant role assignment order unless randomization is explicitly added later

For this MVP, deterministic assignment is acceptable and easier to test.

## Role Reveal Flow

Requirements:

1. screen starts hidden
2. player taps reveal
3. role card appears
4. role and team are explicit
5. private secret/tasks are visible only after reveal
6. player taps hide
7. next player only after card is hidden or confirmed
8. after last player, Host continues to dashboard

## Role Card Content

Each card must show:

```text
Player name
Character
Role
Team
Public info
Secret
Secret meaning
Goal
Tasks
Special ability
Must-not-say
```

If a field is empty, hide that section cleanly.

## Host Dashboard

Show:

- case title
- selected variant/player count
- current stage progress
- active players
- eliminated players
- suspicion marks
- next action
- sound toggle shortcut
- restart with confirmation

## Stage Screen

Show:

- stage number
- stage title
- stage image
- host script
- public clue
- host-only notes
- discussion time
- timer controls
- go to voting button

Public clue and Host-only notes must be visually distinct.

## Timer

Timer requirements:

- start
- pause
- reset
- warning near end
- no memory leaks
- no whole-screen rebuild on every tick if avoidable

Suggested warning threshold:

```text
30 seconds remaining
```

## SFX in Phase 3

Connect SFX for:

```text
role_reveal
clue_reveal
timer_start
timer_warning
ui_tap
```

## Phase 3 Deliverables

- Setup works.
- Session state created.
- Role reveal works privately.
- Host dashboard works.
- Stage screens display real database-loaded content.
- Timer works.
- Initial SFX works.

## Phase 3 Acceptance Criteria

- Correct variant is loaded by player count.
- Every player receives exactly one role card.
- Role cards show explicit role/team.
- Private card data is hidden after reveal.
- Host can reach all 5 stages.
- Timer does not continue after leaving screen.
- Sound toggle affects SFX.
- No database query is repeatedly called in widget build methods.

---

# Phase 4 — Voting, Final Reveal, Assets, SFX, UX Polish

## Objective

Complete the full game loop and integrate MVP-level polish.

## Scope

This phase implements:

- voting system
- suspicion marks
- eliminations
- final vote
- final result logic
- final reveal
- role summary
- image assets
- full SFX integration
- lightweight animations
- UX safety

## Voting State

Voting state should include:

```text
stageNumber
voteType
votesByVoterId
tiedPlayerIds
resolvedTargetId
isResolved
```

## Vote Types

```text
suspicion
elimination
final
```

## Voting Actions

Implement:

```dart
castVote(voterId, targetId)
clearVote(voterId)
resolveVote()
applySuspicionMark(playerId)
eliminatePlayer(playerId)
startRevote()
setFinalAccused(playerId)
resolveFinalResult()
showFinalReveal()
```

## Valid Vote Rules

- eliminated players do not vote by default
- eliminated players cannot be targeted
- voter cannot vote twice unless changing vote before lock
- Host can clear vote
- Host confirms result before applying
- tie case must show tie handling UI

## Stage 1 Logic

- vote type = suspicion
- highest voted player receives suspicion mark
- no elimination

## Stage 2–4 Logic

- vote type = elimination
- highest voted active target can be eliminated after confirmation

## Stage 5 Logic

- final vote
- app determines whether accused target satisfies win condition
- final reveal is shown

## Final Result Logic

For MVP:

- if final accused is Mafioso, Innocent Team wins
- if all Mafioso were eliminated before final, Innocent Team wins
- otherwise Mafia Team wins

For 7/8 players with two Mafioso, ensure result handles both.

## Final Reveal Screen

Must show:

- final image
- winning team
- selected variant final explanation
- role summary for all players
- who was eliminated
- suspicion marks
- restart button

## Image Assets

Integrate:

```text
cover.webp
opening.webp
clue_1_phone.webp
clue_2_camera.webp
clue_3_camera.webp or clue_2_camera.webp depending naming
clue_3_gate.webp
clue_4_voice_note.webp
clue_5_contract.webp
final_reveal.webp
role_reveal_bg.webp
characters/laila.webp
characters/karim.webp
characters/omar.webp
characters/shady.webp
characters/nader.webp
characters/sara.webp
characters/magdy.webp
characters/bebo.webp
```

Use exact names consistently in JSON and assets.

## SFX Assets

Integrate:

```text
app_start
case_select
role_reveal
secret_reveal
clue_reveal
timer_start
timer_warning
vote_start
vote_lock
elimination
final_reveal
mafia_win
innocent_win
ui_tap
```

## SFX Rules

- respect sound_enabled
- moderate volume
- no crashing on missing file
- no noisy overlap
- no mandatory music

## Lightweight Animations

Add:

- fade screen transition
- role card reveal animation
- clue reveal fade/slide
- vote lock feedback
- final reveal fade

Avoid:

- heavy blur everywhere
- particle effects
- expensive continuous animation

## UX Safety

Add confirmation dialogs for:

- starting game after names entered
- hiding role card / next player if needed
- eliminating player
- final reveal
- restart game

Add validation messages for:

- empty names
- invalid player count
- incomplete votes
- tie result

## Phase 4 Deliverables

- Full playable loop.
- Voting works.
- Final reveal works.
- Images integrated.
- SFX integrated.
- UX confirmations implemented.
- Basic cinematic animations added.

## Phase 4 Acceptance Criteria

- Stage 1 never eliminates.
- Stage 2–4 can eliminate after confirmation.
- Stage 5 final vote works.
- Tie handling works.
- Final explanation matches selected variant.
- Role summary is correct.
- Images load without visible lag.
- SFX plays at expected moments.
- SFX mute works.
- No private role data leaks before final reveal.
- UI remains readable in Arabic.

---

# Phase 5 — Testing, Optimization, Stabilization, MVP Freeze

## Objective

Make the app reliable and ready for real playtesting.

## Scope

This phase validates all flows, fixes bugs, optimizes assets, and prepares the playtest build.

## Manual Test Matrix

Test each variant:

```text
5 players
6 players
7 players
8 players
```

For each variant, test:

1. app launch
2. database seed
3. case details
4. setup
5. role reveal
6. stage 1
7. stage 2
8. stage 3
9. stage 4
10. stage 5
11. voting
12. final reveal
13. restart

## Database Tests

Verify:

- first launch seeds data
- second launch does not duplicate
- seed metadata is stored
- variant count is correct
- stage count is exactly 5 per variant
- role assignment count matches player count
- all required text fields exist
- all referenced asset paths exist

## Gameplay Tests

Verify:

- 5 players produce 5 cards
- 6 players produce 6 cards
- 7 players produce 7 cards
- 8 players produce 8 cards
- roles are correct per variant
- Agent tasks appear
- Detective ability appears
- Witness info appears
- Stage 1 applies suspicion only
- later stages apply elimination
- eliminated player status is correct
- final result logic works

## UI/UX Tests

Verify:

- Arabic text direction
- no text overflow
- long text scrolls
- Host notes are separate
- buttons are clear
- confirmation dialogs appear
- role card hidden state is safe
- timer UI is clear
- final explanation is readable

## Audio Tests

Verify:

- all SFX play
- mute disables all SFX
- unmute restores SFX
- missing audio does not crash
- no excessive overlapping
- volume is acceptable

## Performance Tests

Verify on target Android device:

- app launch time acceptable
- no lag during stage transitions
- no lag during role reveal
- timer stable
- image memory usage acceptable
- no jank from audio playback
- no repeated heavy database queries
- no Cubit memory leaks/timer leaks

## Optimization Tasks

- compress images
- compress audio
- remove unused assets
- reduce rebuilds
- ensure const widgets where applicable
- optimize scrolling long text
- avoid repeated database fetches
- cache loaded variant in GameState

## Bug Fix Categories

Fix:

- crashes
- bad routes
- invalid session handling
- wrong role assignment
- missing stage text
- text overflow
- broken RTL
- broken audio
- bad final result
- reset/restart issues
- timer continuing after dispose

## Playtest Host Checklist

Create a simple checklist:

```text
1. Choose player count.
2. Enter names.
3. Give phone to each player during role reveal.
4. Tell players not to reveal direct role.
5. Read each clue aloud.
6. Start timer.
7. Run discussion.
8. Enter votes.
9. Confirm suspicion/elimination.
10. Read final reveal.
```

## Phase 5 Deliverables

- Playtest-ready APK.
- Stable local database.
- Optimized assets.
- Host checklist.
- Known issues list if any.
- Final MVP freeze.

## Phase 5 Acceptance Criteria

- Full game completes without crash.
- All four variants work.
- No duplicate seeding.
- No wrong roles.
- No missing stages.
- No missing final explanation.
- SFX is stable and optional.
- Performance is stable on mid-range Android.
- App is ready for real group playtest.

---

# Final Build Definition

The build is considered ready when:

```text
A Host can run the complete Case 01 experience offline,
for 5, 6, 7, or 8 players,
with local database-loaded content,
private role reveal,
five clue stages,
timer,
voting,
eliminations,
final reveal,
role summary,
local images,
local SFX,
and no backend/authentication/internet dependency.
```

---

# Recommended Agent Execution Order

When using Spec Kit or a coding agent:

1. Implement Phase 1 fully.
2. Run build and fix structural errors.
3. Implement Phase 2 database/seeding.
4. Verify database data before UI logic.
5. Implement Phase 3 game flow.
6. Implement Phase 4 voting/assets/SFX.
7. Implement Phase 5 tests and stabilization.

Do not start premium UI polishing before the gameplay and database are correct.

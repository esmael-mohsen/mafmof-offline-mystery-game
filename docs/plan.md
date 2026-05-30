# MafMof MVP — Professional Spec Plan

## 0. Document Purpose

This document defines the professional product and technical plan for the first MafMof MVP.

It is written to be suitable for Spec Kit / coding-agent workflows.  
It should guide implementation without requiring repeated clarification.

The MVP must stay focused, but the architecture must be scalable enough to support future cases, future roles, richer UI, and more advanced local/offline gameplay.

---

## 1. Product Summary

**MafMof** is a host-led Egyptian mystery / mafia social deduction mobile game.

Players sit together physically.  
One phone is controlled by the Host.  
The Host selects a case, enters player names, lets players privately reveal role cards, then controls clue reveals, discussions, voting, eliminations, and final reveal.

The first MVP contains only one approved case:

```text
Case 01: فرح التجمع — العريس اختفى قبل الزفة
```

This case contains four complete player-count variants:

```text
5 players
6 players
7 players
8 players
```

All variants must feel complete and exciting.  
The 5-player variant must not feel like a short/light version.  
The 8-player variant must not feel bloated.  
All variants share the same core mystery, five stages, and final twist.

---

## 2. MVP Product Goals

### Primary Goal

Build a stable offline-first Flutter MVP that proves the full gameplay loop for one case.

### Secondary Goals

1. Create a scalable local architecture.
2. Use a real local database from the start.
3. Keep all gameplay offline.
4. Make future case additions easy.
5. Provide a strong UI/UX foundation.
6. Add cinematic visual and sound feedback.
7. Avoid over-engineering while preserving professional structure.

---

## 3. Hard Constraints

### Must Have

- Offline-first app.
- No authentication.
- No backend.
- No cloud database.
- Local SQLite database using Drift.
- One approved case only.
- Four variants: 5, 6, 7, 8 players.
- Host-led single-device flow.
- Explicit role display for every player.
- Local image assets.
- Local sound effects.
- Clean architecture.
- go_router navigation.
- dependency injection.
- stable performance.

### Must Not Have

- Online multiplayer.
- User login.
- Remote APIs.
- Payment system.
- Case marketplace.
- Real-time sync.
- Admin dashboard.
- Large multi-case library in MVP.
- Complex 3D animations.
- Heavy background music as a required feature.
- Any dependency on internet connection during gameplay.

---

## 4. Confirmed Tech Stack

### App Framework

```text
Flutter
Dart
```

### Architecture

```text
Feature-first Clean Architecture
```

Architecture layers:

```text
presentation
domain
data
```

The project should be clean and scalable, but avoid unnecessary abstraction for this small MVP.

### State Management

```text
flutter_bloc / Cubit
Equatable
```

Cubit will manage the active game session and screen states.

### Navigation

```text
go_router
```

Use named routes and route constants.  
Avoid raw Flutter Navigator calls for main navigation.

### Local Database

```text
Drift + SQLite
```

The app must store case data in a local database, not only in Dart constants.

### Dependency Injection

```text
get_it
injectable
```

### Code Generation

```text
build_runner
drift_dev
injectable_generator
json_serializable
```

Optional only if genuinely useful:

```text
freezed
```

### Audio

Recommended package:

```text
audioplayers
```

Purpose: short local sound effects only.

### Asset Types

```text
Images: WebP preferred
Audio: compressed MP3/OGG/WAV depending on quality/size
Data seed: JSON asset
```

---

## 5. MVP Functional Scope

## 5.1 Screens

The MVP must include these screens:

1. Splash / App Entry
2. Home Screen
3. Case Details Screen
4. Game Setup Screen
5. Role Reveal Screen
6. Host Dashboard Screen
7. Stage / Clue Screen
8. Voting Screen
9. Final Reveal Screen
10. Settings / Sound Toggle section or lightweight modal

Settings can be minimal and does not need to be a full standalone screen if a simple sound toggle is available in the app menu.

---

## 5.2 Main User Flow

```text
Open App
  ↓
Database seed check
  ↓
Home
  ↓
Case Details
  ↓
Setup Game
  - choose player count
  - enter player names
  ↓
Start Session
  - load matching variant from local database
  - generate player cards from role assignments
  ↓
Private Role Reveal
  - player receives phone
  - tap to reveal
  - read private card
  - hide card
  - pass phone to Host
  ↓
Host Dashboard
  ↓
Stage 1
  - clue reveal
  - timer
  - suspicion vote
  ↓
Stage 2
  - clue reveal
  - timer
  - elimination vote
  ↓
Stage 3
  - clue reveal
  - timer
  - elimination vote
  ↓
Stage 4
  - clue reveal
  - timer
  - elimination vote
  ↓
Stage 5
  - final clue
  - final discussion
  - final vote
  ↓
Final Reveal
  - winning team
  - crime explanation
  - role summary
  ↓
Restart / Back Home
```

---

## 6. Case Content Scope

The MVP uses only:

```text
Case 01: فرح التجمع — العريس اختفى قبل الزفة
```

### Core Mystery

The groom disappeared before the wedding entrance.  
His broken phone was found near the swimming pool.  
The last video contains a cut and a threatening voice.

The truth:

- the groom discovered a dangerous financial contract
- he planned to leave temporarily with Sara’s help
- Magdy discovered the plan
- Magdy used the side gate and black car to turn the escape into a kidnapping
- in 7/8 player variants, Karim helps Magdy
- several innocent characters look suspicious because they hide personal secrets

### Fixed Stages

1. التليفون المكسور
2. الفيديو الناقص
3. الباب الجانبي
4. الرسالة الصوتية
5. ورق الصفقة

### Required Variants

```text
case01_5_players
case01_6_players
case01_7_players
case01_8_players
```

### Variant Rule

Do not treat smaller variants as shorter variants.  
Characters not active as players can still appear as NPC evidence.

---

## 7. Role System

### Supported Roles

```text
Mafioso
Agent
Detective
Witness
Innocent
Innocent Suspect
Innocent Witness-lite
```

### Team Types

```text
Mafia Team
Mafia Support Team
Innocent Team
```

### Role Reveal Requirements

Each role card must show:

- Player name
- Character name
- Role
- Team
- Public info
- Secret
- What the secret means
- Goal
- Secret tasks if any
- Special ability if any
- Must-not-say rules

### Forbidden Gameplay Statement Examples

Players should not reveal direct app-given role identity:

```text
"أنا Mafioso"
"أنا Detective"
"أنا Innocent"
"التطبيق قال إني بريء"
```

### Allowed Gameplay Behavior

Players may:

- speak as characters
- reveal secrets gradually
- lie if their role benefits from deception
- accuse others using clues
- defend themselves
- misdirect if mafia/agent

---

## 8. Voting Rules

### Stage 1

Suspicion vote only.

- Highest voted player receives a suspicion mark.
- No one is eliminated in Stage 1.

### Stages 2–4

Elimination voting.

- Host records votes.
- App calculates highest voted target.
- Host confirms elimination.
- Eliminated players are marked inactive.
- Eliminated players do not vote by default unless future mode says otherwise.

### Stage 5

Final vote / final accusation.

- Host records or selects final accused.
- App determines result based on variant win rules.
- App shows final reveal.

### Tie Handling

If there is a tie:

- App displays tied players.
- Host chooses one of:
  - revote
  - no elimination
  - Host decision
- MVP must support at least revote or Host decision.

---

## 9. Local Database Requirements

### Database Engine

```text
Drift + SQLite
```

### Seeding Strategy

The app ships with bundled JSON case data:

```text
assets/data/cases/case01_farah_eltagamoa.json
```

On first launch:

1. App opens local database.
2. App checks seed version.
3. If the target seed version is missing, seed the database.
4. App inserts/updates case data.
5. App stores seed version.
6. App avoids duplicate insertion on later launches.

### Seed Versioning

Store a seed metadata record, for example:

```text
key: case_seed_version
value: 1
```

Future case updates should not require wiping the database.

---

## 10. Database Entity Design

This is a recommended logical schema.  
Implementation may adjust names as needed, but the same concepts must exist.

### app_settings

Purpose: store local settings.

Fields:

```text
id
sound_enabled
sfx_volume
created_at
updated_at
```

### seed_metadata

Purpose: avoid duplicate seeding and support future migrations.

Fields:

```text
key
value
updated_at
```

### cases

Fields:

```text
id
title_ar
subtitle_ar
description_ar
difficulty
min_players
max_players
duration_minutes
cover_image_path
opening_image_path
is_active
created_at
updated_at
```

### case_variants

Fields:

```text
id
case_id
player_count
variant_name
variant_summary_ar
final_explanation_ar
innocent_win_text_ar
mafia_win_text_ar
created_at
updated_at
```

### characters

Fields:

```text
id
case_id
name_ar
title_ar
image_path
public_info_ar
secret_ar
secret_meaning_ar
goal_ar
must_not_say_ar
created_at
updated_at
```

### variant_characters

Purpose: define which characters are active in each variant.

Fields:

```text
id
variant_id
character_id
sort_order
is_active_player
is_npc
npc_description_ar
```

### role_assignments

Fields:

```text
id
variant_id
character_id
role
team
tasks_json
special_ability_ar
private_hint_rules_json
sort_order
```

### stages

Fields:

```text
id
variant_id
stage_number
title_ar
image_path
host_script_ar
public_clue_ar
host_notes_json
expected_suspects_json
discussion_seconds
vote_type
created_at
updated_at
```

### sound_effects

Optional table if dynamic mapping is desired.

Fields:

```text
id
event_key
asset_path
default_volume
is_enabled
```

For MVP, sound mapping can also be static constants while sound settings are stored in database.

### game_sessions

For MVP, active session can be in memory.  
If resume support is desired, store session state.

Fields if implemented:

```text
id
case_id
variant_id
status
current_stage_number
created_at
updated_at
```

### session_players

Fields if session persistence is implemented:

```text
id
session_id
player_name
character_id
role
team
status
suspicion_marks
sort_order
```

### votes

Fields if vote history is persisted:

```text
id
session_id
stage_number
voter_player_id
target_player_id
created_at
```

Persistence for sessions/votes is optional for MVP, but schema should not block future support.

---

## 11. Data Loading Contract

### On App Start

The app must:

1. initialize DI
2. initialize database
3. run seeder
4. load app settings
5. navigate to Home

### On Case Details

The app must:

1. read active case list from database
2. display Case 01
3. show metadata:
   - title
   - subtitle
   - player range
   - duration
   - difficulty
   - cover image

### On Game Setup

The app must:

1. validate player count
2. validate names
3. fetch matching variant
4. prepare role assignments
5. create game session state

### On Role Reveal

The app must:

1. show one player card at a time
2. hide content before moving to next player
3. play role reveal SFX if enabled
4. prevent accidental private info leak

### On Stage

The app must:

1. show stage image
2. show stage title
3. show host script
4. show public clue
5. show host-only notes in clearly marked UI
6. show timer
7. play clue reveal SFX

### On Voting

The app must:

1. list active voters
2. list valid targets
3. store vote selections in state
4. calculate result
5. request Host confirmation before applying result
6. play vote lock or elimination SFX

### On Final Reveal

The app must:

1. determine result
2. show final explanation for the selected variant
3. show role summary
4. play final reveal/win SFX
5. allow restart

---

## 12. Routing Specification

Use go_router named routes.

Recommended route names:

```text
splash
home
caseDetails
setupGame
roleReveal
hostDashboard
stage
voting
finalReveal
```

Recommended paths:

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

If sessions are in-memory only, `sessionId` may be generated locally and held in Cubit.

---

## 13. State Management Specification

Use one main `GameCubit` for the MVP.

### GameState should include:

```text
status
selectedCase
selectedVariant
playerCount
playerNames
players
currentRevealIndex
currentStageNumber
currentVotes
eliminatedPlayerIds
suspicionMarks
finalAccusedPlayerId
soundEnabled
errorMessage
```

### Recommended statuses:

```text
initial
loading
setup
revealingRoles
hostDashboard
stageInProgress
voting
finalReveal
completed
error
```

### Cubit Actions

```text
loadInitialData()
selectCase(caseId)
selectPlayerCount(count)
updatePlayerName(index, name)
startGame()
revealCurrentPlayerCard()
hideCurrentPlayerCard()
goToNextReveal()
goToStage(stageNumber)
startTimer()
pauseTimer()
resetTimer()
goToVoting()
castVote(voterId, targetId)
clearVote(voterId)
resolveVote()
applySuspicionMark(playerId)
eliminatePlayer(playerId)
setFinalAccused(playerId)
showFinalReveal()
restartGame()
toggleSound(enabled)
```

Timer can be implemented in Cubit or a dedicated timer controller.  
Keep timer disposal safe to avoid leaks.

---

## 14. Sound Effects Specification

### Required SFX Events

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

### Audio Service Responsibilities

The audio service must:

1. play local SFX by key
2. respect sound enabled setting
3. control volume
4. avoid overlapping noisy sounds
5. fail silently if an asset is missing
6. expose a simple interface to presentation layer

### Suggested Interface

```dart
abstract class AudioService {
  Future<void> playSfx(String key);
  Future<void> setEnabled(bool enabled);
  bool get isEnabled;
}
```

### MVP Audio Rules

- No copyrighted sounds.
- No mandatory background music.
- Keep SFX short.
- Use moderate default volume.
- Add mute toggle.

---

## 15. Visual Asset Specification

### Required Images

```text
case cover
opening scene
stage 1 broken phone
stage 2 missing camera clip
stage 3 side gate
stage 4 voice note
stage 5 wedding contract
final reveal
role reveal background
8 character cards
```

### Asset Format

Preferred:

```text
WebP
```

### Image Ratios

```text
Case / stage images: 16:9
Character cards: 3:4
Role reveal background: 9:16
```

### Optimization Rules

- Compress images before bundling.
- Avoid very large raw images.
- Avoid loading all high-resolution images upfront.
- Use placeholders/fallbacks if image is missing.

---

## 16. UI/UX Specification

### Design Direction

The app should feel:

- cinematic
- mysterious
- Egyptian
- elegant
- dark
- premium but not overdone

### Main UI Requirements

#### Home

- title/logo area
- start button
- sound toggle or settings entry
- dark cinematic background

#### Case Details

- cover image
- case title
- subtitle
- player range
- difficulty
- duration
- start button

#### Setup

- player count selector
- name inputs matching count
- validation messages
- start game button

#### Role Reveal

- safe hidden state before reveal
- reveal button
- dramatic card reveal animation
- explicit role and team
- hide card button
- next player button

#### Host Dashboard

- current stage indicator
- active/eliminated players
- next clue/action button
- restart option with confirmation

#### Stage Screen

- stage image
- stage number/title
- host script
- public clue
- host notes separated
- timer
- go to voting button

#### Voting Screen

- active voters
- selectable targets
- vote summary
- tie handling UI
- confirm result button

#### Final Reveal

- final image
- winning team
- final explanation
- role summary
- restart button

---

## 17. Accessibility & Arabic Support

### Requirements

- Arabic-first text.
- RTL layout where appropriate.
- Large enough font sizes.
- High contrast text.
- Avoid tiny dense paragraphs.
- Long text should scroll smoothly.
- Buttons should be clear and large enough.
- Do not rely only on sound to communicate state.

---

## 18. Error Handling Requirements

Handle:

- database initialization failure
- seed failure
- missing case
- missing variant
- invalid player count
- empty player name
- missing image asset
- missing audio asset
- invalid vote
- tie result
- timer disposal
- navigation to invalid session

User-facing errors should be simple and actionable.

---

## 19. Performance Requirements

### Target

Stable on mid-range Android phone.

### Requirements

- no unnecessary rebuilds
- no heavy global rebuild on timer tick
- no huge image memory spikes
- audio playback must not freeze UI
- database queries should not run repeatedly inside build methods
- use local cached session state after loading variant
- avoid overusing blur/shadows
- keep animations short and simple

### Timer Performance

Timer updates should only rebuild timer UI where possible, not the whole screen.

### Database Performance

Load current variant once when starting the session.  
Do not re-query full case data on every stage screen rebuild.

---

## 20. Testing Requirements

### Manual Test Matrix

Test all variants:

```text
5 players
6 players
7 players
8 players
```

For each:

1. setup
2. role reveal
3. all stages
4. voting
5. final reveal
6. restart

### Specific Tests

- duplicate seed prevention
- sound mute/unmute
- missing name validation
- tie handling
- eliminated player status
- suspicion mark
- final role summary
- app restart during setup
- navigation back behavior
- text overflow
- RTL layout

---

## 21. Definition of Done

The MVP is done when:

```text
A Host can open the app offline,
load the local database,
select Case 01,
choose 5/6/7/8 players,
enter names,
privately reveal all roles,
run all 5 stages,
use timer,
manage suspicion vote,
manage elimination votes,
perform final vote,
play local SFX,
mute/unmute SFX,
show final crime explanation,
show role summary,
and restart the game,
without login, backend, internet, or developer help.
```

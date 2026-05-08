# Feature Specification: Word Storm — Core Game

**Feature Branch**: `001-word-storm-core`
**Created**: 2026-05-09
**Status**: Draft
**Input**: User description: "Build Word Storm — a casual mobile word game for Android (primary) and iOS (secondary) in Godot 4 GDScript."

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Complete Game Loop (Priority: P1)

A player opens the app, watches letters fall in 5 columns, taps letters to spell a word, submits it, sees a burst effect and score increment, then keeps playing until letters pile up and they lose all 3 lives, at which point the Game Over screen shows their final score with a restart option.

**Why this priority**: Without a playable end-to-end loop there is nothing to test, tune, or ship. Every other story depends on this skeleton being solid. The core loop must feel good in under 10 seconds.

**Independent Test**: Install the APK on an Android device. Watch letters fall. Tap three letters to form a word. Tap submit. Confirm burst effect fires, score increments, and those letters are removed. Let letters pile past the danger line and confirm lives decrement. Lose all lives and confirm Game Over screen appears with a restart button — all without crashes.

**Acceptance Scenarios**:

1. **Given** the app is open on the title screen, **When** the player taps "Play", **Then** letters begin falling from the top of the screen in 5 columns at a steady speed.
2. **Given** letters are falling, **When** the player taps a falling letter, **Then** it is highlighted/selected and added to the current word tray at the bottom of the screen.
3. **Given** the player has selected 3+ letters, **When** they tap "Submit", **Then** the game validates the word against the English dictionary; if valid, a burst effect fires on each selected letter, score increases, and those letters are removed; if invalid, the selection flashes red and clears.
4. **Given** the player taps "Clear", **When** letters are selected, **Then** all selected letters are deselected and the word tray empties.
5. **Given** a letter reaches the bottom pile zone, **When** it lands, **Then** it joins the pile; when the pile count in any column reaches the pile limit, the player loses one life and that column's pile is cleared.
6. **Given** lives reach zero, **When** the last life is lost, **Then** the Game Over screen shows the final score and a "Play Again" button.
7. **Given** the Game Over screen, **When** the player taps "Play Again", **Then** a new session starts with fresh letters, 3 lives, and score reset to 0.

---

### User Story 2 — Letter Selection & Word Submission (Priority: P1)

A player can tap any visible falling letter or piled letter to add it to their word, tap letters out of order across columns, and submit with one tap. The selection mechanism must be fast and forgiving for one-handed play.

**Why this priority**: This is the only meaningful interaction in the game. If selection feels laggy or misses taps, the entire experience collapses. Must be tuned before any other feature is polished.

**Independent Test**: Play with only letters and selection UI active (no scoring or lives). Tap 5 different letters across non-adjacent columns in quick succession. Confirm all 5 appear in the word tray in tap order. Tap "Clear". Confirm tray empties. Repeat 20 times on a mid-range Android device — no missed taps, no ghost selections.

**Acceptance Scenarios**:

1. **Given** a letter is visible (falling or piled), **When** the player taps it, **Then** it is highlighted within 1 frame and added to the word tray; the tap target is at least 48×48 dp to comply with mobile touch guidelines.
2. **Given** a letter is already selected, **When** the player taps it again, **Then** it is deselected and removed from the word tray.
3. **Given** the same physical letter tile on screen (not the same character), **When** selected, **Then** only that specific tile instance is selected — two tiles showing "A" are independent.
4. **Given** a word tray with letters, **When** the player taps "Submit" and the word is valid, **Then** only the selected tile instances are removed; other tiles with the same characters remain on screen.
5. **Given** a submitted word is invalid, **When** the validation fails, **Then** the word tray flashes red for 0.3 s, clears automatically, and selected letters return to their previous state (falling or piled) without being destroyed.

---

### User Story 3 — Scoring & Difficulty Scaling (Priority: P2)

Score increases with word length and letter rarity. The game gets harder over time by increasing fall speed and spawning more frequent rare/high-point letters. A session lasts 2–5 minutes for a casual player.

**Why this priority**: Needed before public testing to ensure the game has progression tension, but scoring formula can be tuned after core loop is verified.

**Independent Test**: Play a session to 60 seconds and note score per word. Verify a 3-letter word scores less than a 6-letter word. Verify that at the 90-second mark, letters fall noticeably faster than at 0 seconds. Verify that after 120 seconds a skilled player can still survive (not an instant loss).

**Acceptance Scenarios**:

1. **Given** a valid word is submitted, **When** scored, **Then** base points = sum of letter point values (Scrabble-style: common letters = 1pt, rare letters = 8–10pt) × word-length multiplier (3 letters = 1×, 4 = 1.5×, 5 = 2×, 6+ = 3×).
2. **Given** the session has been running for N seconds, **When** fall speed is computed, **Then** speed increases every 30 seconds by 10% of the base speed, capped at 3× base speed.
3. **Given** score is displayed in the HUD, **When** a word is submitted, **Then** the score animates (count-up tween over 0.5 s) to the new value — not an instant jump.
4. **Given** a letter's point value, **When** the letter tile is rendered, **Then** its point value is visible as a small subscript number on the tile (like Scrabble tiles).

---

### User Story 4 — Daily Challenge Mode (Priority: P2)

Each calendar day presents a fixed letter set and sequence (seeded by the date). The player gets one attempt per day. Their best score for the day is saved. A "Daily Challenge" button on the title screen distinguishes it from the endless Classic mode.

**Why this priority**: Retention driver. Without it the game has no reason to return daily. Should be designed early so the architecture supports deterministic seeding from day one.

**Independent Test**: Set device date to 2026-05-09. Play Daily Challenge. Note the letter sequence. Close and reopen the app on the same date. Confirm the exact same letter sequence appears. Change device date to 2026-05-10. Confirm a different sequence. Change back to 2026-05-09. Confirm the original sequence reappears.

**Acceptance Scenarios**:

1. **Given** the title screen, **When** the player taps "Daily Challenge", **Then** the game loads a session seeded from today's date (YYYY-MM-DD formatted as an integer seed); the same seed always produces the same letter sequence on any device.
2. **Given** a Daily Challenge session, **When** the player has already completed today's challenge, **Then** the "Daily Challenge" button shows "Done Today ✓" and tapping it shows their score for the day — they cannot replay it until tomorrow.
3. **Given** a Daily Challenge session ends, **When** the score is saved, **Then** it is persisted to local storage; the title screen shows "Today's Best: [score]" below the Daily Challenge button.
4. **Given** no internet connection, **When** the player attempts Daily Challenge, **Then** the session loads normally using the local device date — no network request is made.

---

### User Story 5 — Best Score Persistence (Priority: P2)

The player's all-time best score for Classic mode is saved locally and shown on the title screen and Game Over screen. No account or network required.

**Why this priority**: Basic retention hook. Required before any public build.

**Independent Test**: Play Classic mode and achieve a score of 500. Close the app fully. Reopen. Confirm "Best: 500" is shown on the title screen. Play again and achieve 300. Confirm best remains 500. Achieve 600. Confirm best updates to 600.

**Acceptance Scenarios**:

1. **Given** a Classic game ends, **When** the final score exceeds the saved best score, **Then** the new best is saved to `user://save.json` and a "New Best!" label appears on the Game Over screen.
2. **Given** the title screen loads, **When** a best score exists in `user://save.json`, **Then** it is displayed as "Best: [score]" on the title screen.
3. **Given** no save file exists (first launch), **When** the title screen loads, **Then** best score shows "Best: 0" — no crash, no missing UI.

---

### User Story 6 — Juice Layer: Bursts, Sounds, Feedback (Priority: P2)

Every meaningful game event (valid word submit, invalid word, letter land, life lost, game over) triggers a visual and audio response that makes the game feel satisfying without being distracting.

**Why this priority**: "Juice" is what separates a casual hit from a tech demo. Must be layered in early so it can be tuned, not bolted on last.

**Independent Test**: Play a session with sound on. For each event type, confirm a response fires within 1 frame and does not degrade frame rate below 55 fps on a mid-range device. Confirm no audio clipping or overlapping loops.

**Acceptance Scenarios**:

1. **Given** a valid word is submitted, **When** letters are destroyed, **Then** each destroyed letter emits a particle burst (8–12 particles) in a colour matching its point tier; a satisfying "whoosh-pop" sound plays once per word (not per letter).
2. **Given** an invalid word is submitted, **When** the validation fails, **Then** the word tray shakes horizontally for 0.2 s (trauma shake pattern) and a short "error buzz" sound plays.
3. **Given** a letter lands on the pile, **When** it settles, **Then** a soft "thud" plays; no screen shake.
4. **Given** a life is lost, **When** the life counter decrements, **Then** a heart-break icon animates out of the HUD, a low "whomp" sound plays, and the screen flashes dark red for 0.2 s.
5. **Given** a juice effect fires, **When** the effect plays, **Then** frame time does not exceed 20 ms (≥ 50 fps) measured via Godot's performance monitor.

---

### User Story 7 — Halal-Safe Rewarded Ads (Priority: P3)

The game offers a "Continue" option on the Game Over screen: watch a rewarded ad to earn one extra life and resume the current session. The ad integration applies family-safe content filters. No ad ever blocks core gameplay.

**Why this priority**: Monetization layer. Comes after the core game is fun. The ad SDK must degrade gracefully to a no-op when offline or when no fill is available.

**Independent Test**: On a real device with internet, reach Game Over. Tap "Watch Ad to Continue". Confirm an ad loads and plays. After the ad, confirm one extra life is granted and gameplay resumes. Disconnect the device from the internet, reach Game Over again, tap "Watch Ad to Continue". Confirm a graceful "No ad available" message appears and the button disappears — no crash.

**Acceptance Scenarios**:

1. **Given** the Game Over screen, **When** an ad is available, **Then** a "Continue (Watch Ad)" button is visible; tapping it loads and plays a rewarded video ad.
2. **Given** the ad completes successfully, **When** the reward callback fires, **Then** the player is granted 1 extra life, the pile is partially cleared (50% of piled letters removed), and the session resumes.
3. **Given** no ad fill or offline state, **When** the player taps "Continue", **Then** the button shows "No ad available" for 2 s then hides — the game does not crash or hang.
4. **Given** an ad is playing, **When** the ad content is rendered, **Then** the ad SDK is configured with category exclusions: no alcohol, no gambling, no dating/adult, no financial products with interest, no music/dancing apps, no ads with female imagery.
5. **Given** the rewarded ad option, **When** offered, **Then** it may be used at most once per game session — a second "Continue" is not offered after the first.

---

### Edge Cases

- What happens when the player taps a letter that is mid-fall and moves before the tap registers? → The tap target uses the letter's position at the moment `_input()` fires; a 48 dp minimum tap area compensates for small drift.
- What happens when two letters overlap in adjacent columns? → Each letter is an independent touch target; overlapping areas trigger the letter whose centre is closest to the tap point.
- What happens when all 5 columns have maxed-out piles simultaneously? → All 5 piles are cleared, 1 life is deducted, and a "Storm Surge!" text effect plays — not 5 separate life deductions.
- What happens when the player has no letters selected and taps Submit? → Nothing happens — Submit button is disabled (greyed out) until at least 3 letters are selected.
- What happens when the word dictionary file is missing or corrupted? → The game falls back to a minimal hardcoded word list (top 500 common English words) and logs a warning; gameplay continues.
- What happens when `user://save.json` is corrupted? → The file is deleted and replaced with defaults (best score = 0, no daily challenge history); no crash.
- What happens when the device date is manipulated to replay a Daily Challenge? → The local save stores the date string of the last completed challenge; if today's date matches, the "Done Today ✓" state shows regardless of system clock manipulation — the date used to seed is locked at session start, not re-read mid-session.
- What happens when a letter falls during the Game Over transition? → All falling letters are frozen (set to `_active = false`) when Game Over is triggered; no letters continue moving during the overlay.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST support a complete loop: title → classic/daily → play → game over → restart/continue.
- **FR-002**: All player input MUST use `InputEventScreenTouch`; no keyboard, mouse, or gamepad input in game logic.
- **FR-003**: Letters MUST fall in 5 independent columns at a configurable speed that increases over time.
- **FR-004**: Each letter tile MUST display its character and point value (Scrabble-style) as a subscript.
- **FR-005**: The word validator MUST check submitted words against a bundled offline English word list (minimum 50,000 words); no network call is permitted for validation.
- **FR-006**: Valid word submission MUST destroy only the selected tile instances, trigger particle bursts, play a sound, and add score.
- **FR-007**: Invalid word submission MUST NOT destroy any tiles; it MUST provide clear negative feedback (shake + sound) and auto-clear the selection.
- **FR-008**: Letters that reach the bottom MUST stack in a pile per column; when any column's pile reaches the limit, 1 life is deducted.
- **FR-009**: The game MUST persist best Classic score and daily challenge result to `user://save.json` using Godot's `FileAccess` API.
- **FR-010**: Daily Challenge mode MUST use a deterministic seed derived from the current local date (YYYYMMDD as integer); the same date always produces the same session on any device.
- **FR-011**: Juice effects (particles, screen shake, sound) MUST NOT allocate heap memory in `_physics_process` or `_process`; burst scenes use `GPUParticles2D` with `one_shot = true`.
- **FR-012**: The APK MUST be exportable via `godot --headless --export-release` on Mac, Windows, and Linux without opening the Godot editor GUI.
- **FR-013**: The game MUST target a minimum of 60 fps on a mid-range Android device (≈ 2019–2021, Adreno 618 / Mali-G76).
- **FR-014**: Draw calls per frame MUST NOT exceed 30; all letter tile sprites MUST use a single texture atlas.
- **FR-015**: The ad SDK MUST be initialised asynchronously and MUST NOT block the main thread or delay game start; if initialisation fails, all ad-related UI is hidden silently.

### Key Entities

- **LetterTile**: `Area2D` (not `RigidBody2D` — deterministic fall, no physics engine non-determinism). Has: character, point value, column index, fall speed scalar, pile state (`falling` | `piled` | `selected` | `destroying`). Emits `tapped(tile)` signal.
- **Column**: `Node2D`. Owns its `LetterTile` instances. Tracks pile count. Emits `pile_overflow` signal when pile limit is reached. Spawns new tiles from a letter queue.
- **WordTray**: `CanvasLayer` UI node. Holds the ordered array of selected `LetterTile` references. Exposes `get_word() -> String`, `clear()`, `submit()`.
- **WordValidator**: Autoload singleton. Loads word list from `res://assets/data/words_en.txt` at startup. Exposes `is_valid(word: String) -> bool`. Pure function — no scene dependencies.
- **LetterSpawner**: Autoload singleton (or `GameSession` child). Generates the letter queue from a weighted frequency table (English letter frequency + Scrabble distribution). Uses a seeded `RandomNumberGenerator` so Daily Challenge is reproducible.
- **GameSession**: `Node` scene root for a play session. Owns all 5 `Column` nodes, the `WordTray`, `HUD`, and `JuiceManager` reference. Connects signals and drives the state machine.
- **GameManager**: Autoload singleton. Tracks `lives`, `score`, `session_type` (classic | daily), `current_seed`. Emits `state_changed`, `score_changed`, `lives_changed`.
- **SaveManager**: Autoload singleton. Wraps `FileAccess` for reading/writing `user://save.json`. Exposes `get_best_score()`, `set_best_score(n)`, `get_daily_result(date_str)`, `set_daily_result(date_str, score)`.
- **JuiceManager**: Autoload singleton. Exposes `shake(intensity, duration)`, `flash(colour, duration)`, `emit_burst(position, tier)`. Trauma-based camera shake. No `Camera2D.global_position` mutation.
- **AudioManager**: Autoload singleton. 8-slot `AudioStreamPlayer` pool. Exposes `play(sound_name: String)`.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time player reaches their first valid word submission within 10 seconds of tapping "Play" — no tutorial or instructions required (confirmed via 5-person playtest on fresh install).
- **SC-002**: The game sustains ≥ 60 fps for at least 3 consecutive minutes on a mid-range Android device (Adreno 618 / Mali-G76), confirmed via Godot's built-in profiler.
- **SC-003**: Draw calls per frame remain ≤ 30 during active gameplay (letters falling, particles firing), confirmed via Godot's profiler.
- **SC-004**: The Daily Challenge produces identical letter sequences on two different physical devices set to the same date, verified by comparing first 10 spawned letters.
- **SC-005**: `user://save.json` correctly survives a force-close and reopen: best score and daily result are intact across 10 consecutive test cycles.
- **SC-006**: The complete game loop (launch → spell word → life lost → game over → restart) runs 10 consecutive times without a crash or freeze.
- **SC-007**: All juice events (valid word, invalid word, letter land, life lost) fire correctly and do not cause frame time to exceed 20 ms.
- **SC-008**: A headless CLI export command in `docs/build.md` produces a working APK ≤ 30 MB on a clean machine within 5 minutes.
- **SC-009**: The rewarded ad flow completes end-to-end on a real device (ad loads → plays → reward granted → session resumes) without a crash.
- **SC-010**: Disabling the network mid-session causes zero crashes, errors, or UI freezes — the game continues uninterrupted.

---

## Assumptions

- The game targets Android API level 26 (Android 8.0) as the minimum, consistent with Godot 4's default Android export target. iOS is a secondary target using the same Godot project; iOS-specific export configuration is out of scope for v1 implementation tasks.
- Portrait orientation only, viewport 400 × 680 logical pixels. Godot's `canvas_items` stretch mode with `keep` aspect ratio handles other screen sizes.
- The English word list will be sourced from a royalty-free, offline-compatible dictionary (e.g. SOWPODS or TWL06 filtered to common words); minimum 50,000 entries; bundled as a plain text file in `res://assets/data/`.
- Letter frequency distribution follows English Scrabble tile distribution (12× E, 9× A/I, etc.) with a slight skew toward higher-frequency letters in early game sessions.
- Sound assets will be sourced from royalty-free libraries (not commissioned); format is `.ogg` for Android compatibility. No music track in v1 — SFX only.
- The rewarded ad SDK will be integrated via Godot's Android plugin system. The specific SDK (AdMob, Unity Ads, etc.) is to be confirmed before Phase 5. The spec assumes a standard rewarded ad callback API.
- No persistent data beyond `user://save.json` (best score, daily challenge history). No cloud sync, no account system.
- The Godot editor version is **Godot 4.3** (stable); no Godot 4.4+ features should be assumed.
- GDScript is the sole scripting language; no C# or GDNative.
- Developer background is JavaScript/TypeScript; all non-trivial GDScript blocks must include `# [JS equiv]` comments.
- "Halal-safe" ad filtering is achieved via ad SDK category exclusion settings, not by building a custom ad network. The project accepts that 100% filter compliance cannot be guaranteed by SDK alone; the filter is a best-effort configuration.
- Arabic language support (for UI text and word validation) is planned for v2. For v1, all UI text is English only.

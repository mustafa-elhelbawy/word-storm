# Implementation Plan: Word Storm — Core Game

**Branch**: `001-word-storm-core` | **Date**: 2026-05-09 | **Spec**: `specs/001-word-storm-core.md`

---

## Summary

Build a casual mobile word game in Godot 4 (GDScript) for Android (primary) and Web/HTML5 (secondary). Letters fall in 5 independent columns; the player taps to select letters, spells valid English words, and submits for points. Letters that pile up cost lives. Three lives lost = game over. Delivered in five phases sized for 1–2 hour sessions, with a rewarded-ad monetisation layer in Phase 5.

---

## Technical Context

| Key | Value |
|-----|-------|
| **Language / Version** | GDScript · Godot 4.3 stable |
| **Scripting only** | No C#, no GDNative, no third-party plugins (ad plugin in Phase 5 only) |
| **Target Platforms** | Android API 26+ (primary) · Web HTML5 (secondary) · Same Godot project |
| **Viewport** | 400 × 680 logical px · Portrait locked · `canvas_items` stretch · `keep` aspect |
| **Performance Goals** | ≥ 60 fps sustained · ≤ 30 draw calls · no heap alloc in `_process` |
| **Storage** | `user://save.json` via `FileAccess` — offline, local only |
| **Testing** | Manual playtest on device + Godot profiler; no automated test runner |
| **Build Machine** | Mac, Windows, or Linux (Godot CLI + Android SDK) |
| **Export Formats** | Signed `.aab` (Play Store) · `.apk` (sideload) · `.html` + `.pck` (itch.io) |
| **APK Size Limit** | ≤ 30 MB (hard cap, constitution) |
| **Word List** | Bundled offline `.txt` — minimum 50,000 words — no network validation |

---

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. GDScript + Godot 4 only | REQUIRED — all scripts `.gd`, no plugins in phases 1–4 | Ad plugin (Phase 5) is Android-only native plugin; isolated behind `AdManager.gd` stub |
| II. Portrait touch only | REQUIRED — all input via `InputEventScreenTouch` | `emulate_touch_from_mouse = true` for editor testing only |
| III. Offline-first | REQUIRED — `WordValidator` loads from `res://`, `SaveGame` uses `user://` | Ad SDK initialises async and fails silently if offline |
| IV. APK ≤ 30 MB | REQUIRED — word list as plain `.txt`, `.ogg` audio, compressed textures | Atlas enforced per scene; `specs/` and `docs/` excluded via `.gdignore` |
| V. Halal-safe ads | REQUIRED — ad SDK category exclusions configured before any real ad traffic | `AdManager.gd` stub returns no-op in phases 1–4 |
| VI. Single-player only | PASS — no multiplayer, no live leaderboard | Local best score only |
| VII. Tight scope | PASS — Arabic mode, cloud sync, social sharing, story mode all explicitly excluded | |

---

## Project File Structure

```text
word-storm/                        ← git + Godot project root (project.godot lives here)
│
├── project.godot                  ← display/stretch, autoloads, input map
├── export_presets.cfg             ← committed; keystore + signing via env vars
│
├── docs/
│   ├── build.md                   ← headless export steps (Android + Web)
│   └── .gdignore                  ← exclude docs/ from APK
│
├── scenes/
│   ├── main/
│   │   └── Main.tscn              ← root scene; scene switcher
│   ├── screens/
│   │   ├── StartScreen.tscn       ← logo, best score, Play / Daily buttons
│   │   ├── GameScreen.tscn        ← HUD + 5 columns + word tray + controls
│   │   └── GameOver.tscn          ← score, ad slot, play again
│   ├── game/
│   │   ├── Column.tscn            ← Node2D; owns LetterTile instances
│   │   ├── LetterTile.tscn        ← Area2D; letter + point value display
│   │   ├── WordTray.tscn          ← HBoxContainer; selected letter slots
│   │   └── PileIndicator.tscn     ← danger bar per column
│   ├── overlays/
│   │   └── SettingsOverlay.tscn   ← sound toggle, theme selector
│   └── effects/
│       └── TileBurst.tscn         ← GPUParticles2D one-shot burst
│
├── scripts/
│   └── autoloads/
│       ├── GameManager.gd         ← state machine, lives, speed, session type
│       ├── ScoreManager.gd        ← points table, combo multiplier, best score
│       ├── WordValidator.gd       ← dictionary load, O(1) HashSet lookup
│       ├── SaveGame.gd            ← FileAccess read/write for save.json
│       ├── ParticleManager.gd     ← burst pool, column-colour mapping
│       ├── AudioManager.gd        ← 8-slot AudioStreamPlayer pool
│       ├── AdManager.gd           ← rewarded ad stub (real SDK wired in Phase 5)
│       └── ThemeManager.gd        ← palette per theme; emits theme_changed signal
│
├── scripts/
│   ├── LetterTile.gd              ← fall movement, tap, state machine
│   ├── Column.gd                  ← spawn timer, pile tracking, overflow
│   ├── WordTray.gd                ← selected tile refs, submit/clear
│   └── Palette.gd                 ← class_name Palette; static colour constants
│
├── assets/
│   ├── textures/
│   │   └── atlas.png              ← single sprite atlas (tiles, UI, icons)
│   ├── audio/
│   │   └── sfx/
│   │       ├── tile_land.ogg
│   │       ├── tile_select.ogg
│   │       ├── word_valid.ogg
│   │       ├── word_invalid.ogg
│   │       ├── life_lost.ogg
│   │       └── game_over.ogg
│   ├── fonts/
│   │   └── ui_font.ttf
│   └── data/
│       └── words_en.txt           ← bundled word list (50k+ entries, one per line)
│
├── specs/                         ← speckit docs (excluded from APK via .gdignore)
│   ├── .gdignore
│   ├── 001-word-storm-core.md
│   ├── 001-word-storm-core-plan.md   ← this file
│   └── tasks/
│       └── T001.md … TNNN.md
│
└── build/                         ← gitignored; APK/AAB/HTML output
    ├── android/
    └── web/
```

---

## Signal Map

| Signal | Emitter | Receiver(s) | Trigger Condition |
|--------|---------|-------------|-------------------|
| `tile_tapped(tile: LetterTile)` | `LetterTile.gd` | `WordTray.gd` | Player tap lands on tile's `Area2D` |
| `tile_landed(column_id: int)` | `Column.gd` | `GameManager.gd` | Tile `y_position` reaches pile zone top |
| `pile_overflow(column_id: int)` | `Column.gd` | `GameManager.gd` | Pile count in column reaches `MAX_PILE` |
| `word_submitted(tiles: Array)` | `WordTray.gd` | `WordValidator.gd`, `GameManager.gd` | Player taps Submit with ≥ 3 tiles selected |
| `word_valid(word: String, tiles: Array, score: int)` | `WordValidator.gd` | `GameScreen.gd`, `ScoreManager.gd`, `ParticleManager.gd`, `AudioManager.gd` | Dictionary lookup returns `true` |
| `word_invalid(word: String)` | `WordValidator.gd` | `WordTray.gd`, `AudioManager.gd` | Dictionary lookup returns `false` |
| `score_updated(new_score: int, delta: int)` | `ScoreManager.gd` | `HUD` (score label tween) | Points awarded after valid word |
| `combo_changed(multiplier: float)` | `ScoreManager.gd` | `HUD` (combo indicator) | Combo tier advances or resets |
| `life_lost(lives_remaining: int)` | `GameManager.gd` | `HUD`, `AudioManager.gd`, `ParticleManager.gd` | `pile_overflow` received; lives -= 1 |
| `speed_increased(new_speed: float)` | `GameManager.gd` | All `Column.gd` instances | Every 30 s elapsed in session |
| `game_over` | `GameManager.gd` | `Main.gd` (scene switch to GameOver) | `lives == 0` |
| `theme_changed(palette: Dictionary)` | `ThemeManager.gd` | All tile, column, HUD nodes | Player selects theme in SettingsOverlay |
| `ad_reward_granted` | `AdManager.gd` | `GameManager.gd` | Rewarded ad completes successfully |

---

## Data Model

### LetterTile (runtime node state)
```gdscript
# Held as member vars on LetterTile.gd
var letter: String          # single uppercase character, e.g. "E"
var point_value: int        # 1–10, Scrabble distribution
var column_id: int          # 0–4
var fall_speed: float       # px/s, set by Column at spawn time
var state: TileState        # enum: FALLING | PILED | SELECTED | DESTROYING
var _y_position: float      # tracked internally; not exposed as a property
```

### GameState (held on GameManager.gd)
```gdscript
var score: int              # current session score
var best_score: int         # loaded from SaveGame on _ready()
var lives: int              # starts at 3
var speed_level: int        # 0-based; increments every 30 s
var combo_count: int        # consecutive valid words without miss/timeout
var session_type: SessionType  # enum: CLASSIC | DAILY
var session_seed: int       # rng seed; date-derived for DAILY, random for CLASSIC
var elapsed_seconds: float  # session timer driving speed progression
var active_tiles: Array     # flat list of all LetterTile nodes currently in scene
```

### WordEntry (transient; lives only during submission)
```gdscript
# Created in WordTray.gd on submit, destroyed after resolution
var word_string: String     # concatenated letters in tap order
var tile_refs: Array        # ordered Array[LetterTile] references
var score_value: int        # calculated by ScoreManager before tiles are freed
```

### SaveData (serialised to user://save.json)
```gdscript
{
  "best_score": int,        # all-time Classic best
  "selected_theme": String, # "default" | "ocean" | "ember" | "void"
  "daily": {
    "YYYYMMDD": int         # date string → score achieved; one entry per day
  }
}
```

### Letter Frequency Table (compile-time constant in LetterSpawner)
```gdscript
# Scrabble-derived tile counts → normalised weights
const LETTER_WEIGHTS: Dictionary = {
  "E": 12, "A": 9, "I": 9, "O": 8, "N": 6, "R": 6, "T": 6,
  "L": 4,  "S": 4, "U": 4, "D": 4, "G": 3, "B": 2, "C": 2,
  "M": 2,  "P": 2, "F": 2, "H": 2, "V": 2, "W": 2, "Y": 2,
  "K": 1,  "J": 1, "X": 1, "Q": 1, "Z": 1
}
```

---

## Scene Trees

### `Main.tscn`
```
Main (Node)                       ← Main.gd — scene switcher
└── SceneContainer (Node)         ← holds the active scene instance
```
`Main.gd` listens to `GameManager.state_changed` and swaps the child of `SceneContainer` using `change_scene_to_packed()`.

---

### `StartScreen.tscn`
```
StartScreen (CanvasLayer)
├── Background (ColorRect)        ← Palette.BACKGROUND
├── Logo (Sprite2D)               ← atlas region
├── BestScore (Label)             ← "Best: NNN" — updated from SaveGame
├── DailyBadge (Label)            ← "Today's Best: NNN" or "Done Today ✓"
├── StarParticles (GPUParticles2D) ← ambient idle effect, NOT one_shot
├── PlayButton (Button)           ← emits → GameManager.start_game(CLASSIC)
├── DailyButton (Button)          ← emits → GameManager.start_game(DAILY)
├── SettingsButton (Button)       ← shows SettingsOverlay
└── HouseAdBanner (TextureRect)   ← Deep Break cross-promo; tap opens store URL
```

---

### `GameScreen.tscn`
```
GameScreen (Node2D)               ← GameScreen.gd
│
├── Background (ColorRect)
│
├── HUD (CanvasLayer, layer=5)
│   ├── ScoreLabel (Label)        ← score_updated → tween count-up
│   ├── ComboIndicator (Label)    ← "×1.5" / "×2" / "×3"; hidden at ×1
│   └── LivesContainer (HBoxContainer)
│       └── HeartIcon × 3 (Sprite2D)  ← life_lost → animate heart out
│
├── ColumnArea (Node2D)           ← contains all 5 Column instances
│   ├── Column0 (instance Column.tscn, x=40)
│   ├── Column1 (instance Column.tscn, x=120)
│   ├── Column2 (instance Column.tscn, x=200)
│   ├── Column3 (instance Column.tscn, x=280)
│   └── Column4 (instance Column.tscn, x=360)
│
├── PileZone (Node2D)             ← visual danger line (y=580); no physics
│
├── WordTray (instance WordTray.tscn, CanvasLayer layer=4)
│
├── Controls (CanvasLayer, layer=4)
│   ├── SubmitButton (Button)     ← disabled until ≥ 3 tiles selected
│   └── ClearButton (Button)
│
├── FlashOverlay (ColorRect)      ← full-screen flash; normally alpha=0
│
└── EffectsLayer (Node2D)         ← TileBurst instances added here at runtime
```

---

### `Column.tscn`
```
Column (Node2D)                   ← Column.gd
├── SpawnPoint (Marker2D)         ← y = -30 (above viewport)
├── PileZoneMarker (Marker2D)     ← y = 580 (pile starts here)
└── PileIndicator (instance PileIndicator.tscn)
```
`Column.gd` manages its own `RandomNumberGenerator` (seeded from `GameManager.session_seed + column_id`) for spawn timing. This ensures Daily Challenge columns are reproducible.

---

### `LetterTile.tscn`
```
LetterTile (Area2D)               ← LetterTile.gd
├── CollisionShape2D [RectangleShape2D, size=(64, 64)]
├── TileBackground (Sprite2D)     ← atlas region; colour set by ThemeManager
├── LetterLabel (Label)           ← large centred character
└── PointsLabel (Label)           ← subscript point value (font size 10)
```
`Area2D` (not `CharacterBody2D`) is used because tiles do not collide with each other — they fall independently in isolated columns. Tap detection uses `input_event` signal on the `Area2D`.

---

### `WordTray.tscn`
```
WordTray (CanvasLayer, layer=4)
├── Background (NinePatchRect)
├── TileSlots (HBoxContainer)     ← TileSlot labels added dynamically
└── EmptyHint (Label)             ← "Tap letters to spell a word"; hidden when tiles selected
```

---

### `GameOver.tscn`
```
GameOver (CanvasLayer)
├── Background (ColorRect)        ← semi-transparent overlay
├── ScorePanel (PanelContainer)
│   ├── FinalScoreLabel (Label)
│   ├── BestScoreLabel (Label)    ← "New Best!" shown if beaten
│   └── NewBestBadge (Label)      ← animated in; hidden by default
├── AdSlot (VBoxContainer)
│   ├── ContinueAdButton (Button) ← "Watch Ad → +1 Life"; hidden if no fill
│   └── NoAdLabel (Label)         ← "No ad available"; shown 2s then hidden
└── PlayAgainButton (Button)
```

---

### `SettingsOverlay.tscn`
```
SettingsOverlay (CanvasLayer, layer=10)
├── DimBackground (ColorRect)     ← tap to dismiss
├── Panel (PanelContainer)
│   ├── SoundToggle (CheckButton)
│   ├── ThemeLabel (Label)        ← "Theme"
│   └── ThemeGrid (GridContainer)
│       ├── ThemeDefault (Button) ← "Default"
│       ├── ThemeOcean (Button)   ← "Ocean" (IAP)
│       ├── ThemeEmber (Button)   ← "Ember" (IAP)
│       └── ThemeVoid (Button)    ← "Void" (IAP)
└── CloseButton (Button)
```

---

## Script Responsibilities

### `GameManager.gd` (Autoload)
- State machine: `TITLE → WAITING → PLAYING → GAME_OVER`
- Tracks `lives`, `elapsed_seconds`, `speed_level`, `session_type`, `session_seed`
- Drives speed progression: `_process()` increments `elapsed_seconds`; every 30 s emits `speed_increased` and updates all Column fall speeds
- Handles `pile_overflow` → `lose_life()` → emits `life_lost` → if `lives == 0` emits `game_over`
- Handles `ad_reward_granted` → restore 1 life, clear 50% of all piles
- `start_game(type)`: sets seed (date-int for DAILY, `randi()` for CLASSIC), resets state, emits `state_changed`

### `LetterTile.gd`
- Owns `TileState` enum: `FALLING | PILED | SELECTED | DESTROYING`
- `_process(delta)`: when `FALLING`, moves `position.y += fall_speed * delta`; when `PILED`, does nothing
- `_on_input_event(viewport, event, shape_idx)`: on touch press, emits `tile_tapped(self)`
- `select()` / `deselect()`: flips state, updates visual modulate
- `destroy()`: plays `DESTROYING` animation via `Tween`, then `queue_free()`
- Tap target is 64×64 px (≥ 48 dp on 160dpi baseline) — satisfies mobile touch guideline

### `Column.gd`
- Owns `_rng: RandomNumberGenerator` seeded from `GameManager.session_seed ^ column_id`
- `_spawn_timer`: `wait_time` randomised between 1.5–3.5 s per spawn
- `spawn_tile()`: picks letter from `LetterSpawner.next_letter(column_id)`, instances `LetterTile.tscn`, sets `fall_speed` from `GameManager.current_speed`
- Tracks `_pile: Array[LetterTile]` — tiles that have landed
- On `tile_landed`: appends to `_pile`; if `_pile.size() >= MAX_PILE` (default 5), emits `pile_overflow`
- `clear_pile(fraction: float)`: removes `ceil(pile.size() * fraction)` tiles from bottom (used by ad reward)
- Enforces spawn rules: checks last 2 spawned letters per column; blocks same letter 3× consecutive; follows Q with U

### `WordTray.gd`
- Holds `_selected: Array[LetterTile]` — ordered by tap time
- `add_tile(tile)` / `remove_tile(tile)`: manages `_selected`; updates `SubmitButton.disabled`
- `get_word() -> String`: returns `"".join(_selected.map(func(t): return t.letter))`
- `submit()`: emits `word_submitted(_selected.duplicate())`; cleared after emission
- `clear()`: calls `deselect()` on all tiles, empties `_selected`
- On `word_invalid`: plays horizontal shake `Tween` on tray background (8 px left-right, 0.2 s), then calls `clear()`
- On `word_valid`: calls `tile.destroy()` on each tile in the submitted array; calls `clear()`

### `WordValidator.gd` (Autoload)
- Loads `res://assets/data/words_en.txt` in `_ready()` into a `Dictionary` keyed by word (value = `true`)
- O(1) average lookup: `func is_valid(word: String) -> bool: return _words.has(word.to_lower())`
- Falls back to hardcoded 500-word set if file missing
- Emits `word_valid` or `word_invalid` on `word_submitted` signal received

### `ScoreManager.gd` (Autoload)
- Scoring table:

  | Word Length | Base Points |
  |-------------|------------|
  | 3 | 10 |
  | 4 | 25 |
  | 5 | 50 |
  | 6+ | 100 |

- Combo multiplier tiers: 1× → 1.5× (2 consecutive) → 2× (4 consecutive) → 3× (6 consecutive)
- Combo resets on: invalid word submitted OR 6 s elapsed since last valid word
- `award(tiles: Array) -> int`: computes `base × multiplier × letter_bonus`; emits `score_updated`
- Letter bonus: sum of point values of all tiles (Scrabble weights) × 0.1 added as bonus multiplier
- Updates `GameManager.best_score` and calls `SaveGame.set_best_score()` if new score exceeds it

### `ParticleManager.gd` (Autoload)
- Preloads `TileBurst.tscn`
- `emit_burst(world_pos: Vector2, column_id: int)`: instances burst, sets colour from `ThemeManager.column_colour(column_id)`, adds to `EffectsLayer`, auto-frees after `lifetime + 0.1 s`
- `flash(colour: Color, duration: float)`: tweens `FlashOverlay.color.a` 0.5 → 0

### `SaveGame.gd` (Autoload)
- Path: `user://save.json`
- `_ready()`: loads file; if missing or corrupt, initialises defaults
- `get_best_score() -> int`
- `set_best_score(n: int)`: updates in-memory + writes file
- `get_daily_result(date_str: String) -> int`: returns -1 if not played
- `set_daily_result(date_str: String, score: int)`: updates + writes
- `get_theme() -> String`
- `set_theme(name: String)`: updates + writes
- All writes use `FileAccess.WRITE` with JSON serialisation; parse errors reset to defaults

### `AdManager.gd` (Autoload — stub in phases 1–4)
```gdscript
# AdManager.gd — stub; real SDK wired in Phase 5
extends Node
signal ad_reward_granted
signal ad_unavailable

func load_rewarded() -> void: pass      # no-op until Phase 5
func show_rewarded() -> void:
    emit_signal("ad_unavailable")       # stub always reports no fill
```

### `ThemeManager.gd` (Autoload)
- Holds `_current: String` (theme name)
- `PALETTES: Dictionary` maps theme name → `{ bg, col0…col4, text, pile_warn }`
- `column_colour(col_id: int) -> Color`
- On `theme_changed`: all subscribed nodes update their modulate/colour

---

## Letter Spawning Rules

```gdscript
# In Column.gd — enforced at spawn time
func _pick_letter() -> String:
    var letter: String = LetterSpawner.next_weighted(session_rng)

    # Rule 1: Never same letter 3+ times simultaneously across all columns
    var active_letters := GameManager.active_tiles.map(func(t): return t.letter)
    var count := active_letters.count(letter)
    var attempts := 0
    while count >= 2 and attempts < 10:
        letter = LetterSpawner.next_weighted(session_rng)
        count = active_letters.count(letter)
        attempts += 1

    # Rule 2: Q always followed by U in same column within 2 spawns
    if _last_spawned_letter == "Q":
        letter = "U"

    _last_spawned_letter = letter
    return letter
```

---

## Speed Progression

```gdscript
# In GameManager.gd _process()
const BASE_SPEED:    float = 80.0   # px/s
const SPEED_STEP:    float = 10.0   # px/s per interval
const SPEED_INTERVAL:float = 30.0   # seconds
const MAX_SPEED:     float = 220.0  # px/s cap

func _process(delta: float) -> void:
    if state != State.PLAYING:
        return
    elapsed_seconds += delta
    var new_level: int = int(elapsed_seconds / SPEED_INTERVAL)
    if new_level != speed_level:
        speed_level = new_level
        current_speed = minf(BASE_SPEED + speed_level * SPEED_STEP, MAX_SPEED)
        emit_signal("speed_increased", current_speed)
```

---

## Phase Plan

### Phase 1 — Godot Project Scaffold + Title Screen

**Goal**: Project opens, stretches correctly on Android, title screen renders with best score. Nothing moves yet.
**Estimated sessions**: 2 × 90 min

#### 1.1 — `project.godot` Settings
```ini
[display]
window/size/viewport_width  = 400
window/size/viewport_height = 680
window/stretch/mode         = "canvas_items"
window/stretch/aspect       = "keep"

[input_devices]
pointing/emulate_touch_from_mouse = true

[rendering]
renderer/rendering_method = "mobile"
```

#### 1.2 — Autoload Registration (stubs)
Register in this order (GameManager before all others):
```
GameManager, ScoreManager, WordValidator, SaveGame,
ParticleManager, AudioManager, AdManager, ThemeManager
```
Each stub: `extends Node` + empty `_ready()`. Fills out in later phases.

#### 1.3 — `Palette.gd` (static class, not autoload)
```gdscript
class_name Palette
const BACKGROUND: Color = Color(0.055, 0.039, 0.118)  # #0e0a1e deep violet
const COL_COLOURS: Array[Color] = [
    Color(0.0, 0.784, 0.722),   # teal
    Color(0.0, 0.878, 1.000),   # cyan
    Color(1.0, 0.757, 0.027),   # amber
    Color(0.694, 0.404, 1.000), # violet
    Color(0.0, 0.941, 0.502),   # mint
]
```

#### 1.4 — `SaveGame.gd` (full implementation)
Implement completely in Phase 1 so every subsequent phase can read/write persistence without stubs.

#### 1.5 — `StartScreen.tscn` + `Main.tscn`
- Set `Main.tscn` as main scene
- `Main.gd` loads `StartScreen` as first child
- `StartScreen` reads `SaveGame.get_best_score()` and `SaveGame.get_daily_result(today)`
- Play button calls `GameManager.start_game(CLASSIC)` → `Main.gd` switches to `GameScreen`

**Phase 1 done when**: App opens on Android, shows title with best score (0 on first run), Play button is tappable.

---

### Phase 2 — Letter Rain + Core Mechanics

**Goal**: Letters fall in 5 columns at correct speed, pile up, trigger life loss. No word validation yet.
**Estimated sessions**: 3 × 90 min

#### 2.1 — `LetterTile.tscn` + `LetterTile.gd`
Full implementation: fall movement, tap detection, state machine, visual states.

#### 2.2 — `Column.tscn` + `Column.gd`
Full implementation: spawn timer, letter picking (frequency weights, no constraint enforcement yet), pile tracking, `pile_overflow` signal.

#### 2.3 — `GameManager.gd` (Phase 2 portion)
- State machine (TITLE / WAITING / PLAYING / GAME_OVER)
- Life tracking + `life_lost` / `game_over` signals
- Speed progression (`_process` timer)

#### 2.4 — `GameScreen.tscn` Phase 2 assembly
- 5 Column instances placed at x = 40, 120, 200, 280, 360
- HUD showing lives (3 hearts) and score (0)
- FlashOverlay for life-lost feedback

**Phase 2 done when**: Letters fall, pile up, losing all lives transitions to `GameOver` screen.

---

### Phase 3 — Word Selection, Validation & Scoring

**Goal**: Player can tap letters, build words in the tray, submit valid words for points, get feedback on invalid words.
**Estimated sessions**: 3 × 90 min

#### 3.1 — `WordValidator.gd` (Autoload, full)
Load `words_en.txt` → `Dictionary`. `is_valid()`. Emit `word_valid` / `word_invalid`.

#### 3.2 — `WordTray.tscn` + `WordTray.gd`
Tap → add to tray. Tap again → remove. Submit → validate. Clear → deselect all. Invalid → shake + clear. Valid → destroy tiles.

#### 3.3 — `ScoreManager.gd` (Autoload, full)
Scoring table, combo multiplier, combo reset timer, `score_updated` signal, best score persistence.

#### 3.4 — `LetterSpawner` spawn constraints
Add Q→U rule and simultaneous-duplicate cap to `Column.gd`.

**Phase 3 done when**: Full game loop runs end-to-end — spell word → score → lives → game over → restart.

---

### Phase 4 — Juice, Polish & Daily Challenge

**Goal**: All juice events firing, Daily Challenge mode, theme system, settings overlay.
**Estimated sessions**: 3 × 90 min

#### 4.1 — `TileBurst.tscn` + `ParticleManager.gd`
GPUParticles2D burst per destroyed tile, coloured by column theme.

#### 4.2 — `AudioManager.gd` (full)
8-slot pool. Load all 6 SFX. Wire to: tile land, tile select, word valid, word invalid, life lost, game over.

#### 4.3 — `JuiceManager` (shake + flash)
Trauma-based shake on `life_lost`. Red flash on `life_lost`. Green flash on `word_valid`. Horizontal tray shake on `word_invalid`.

#### 4.4 — Daily Challenge seed system
`GameManager.start_game(DAILY)`: seed = `int("".join(Time.get_date_string_from_system().split("-")))` e.g. `20260509`. Column RNGs seeded from this — same date = same sequence on any device.

#### 4.5 — `ThemeManager.gd` + `SettingsOverlay.tscn`
Default theme free. Ocean/Ember/Void gated behind IAP stub (unlockable in Phase 5). `theme_changed` signal refreshes all tile/column colours.

**Phase 4 done when**: All juice events fire correctly, Daily Challenge is reproducible, settings overlay works.

---

### Phase 5 — Monetisation + Export Pipeline

**Goal**: Rewarded ad integration, IAP theme unlocks, signed APK + AAB, Web HTML5 export.
**Estimated sessions**: 2 × 90 min

#### 5.1 — AdMob Rewarded Ad (Android plugin)
Replace `AdManager.gd` stub with real Godot AdMob plugin integration.
- Category exclusions: set in AdMob dashboard (exclude: dating, gambling, alcohol, financial/interest, music/entertainment)
- `load_rewarded()` called on `GameOver` screen open
- `show_rewarded()` called on "Watch Ad" button tap
- On `ad_reward_granted`: `GameManager` receives signal, restores 1 life, clears 50% of piles, switches back to `GameScreen`
- On offline / no fill: `AdManager` emits `ad_unavailable` → GameOver shows "No ad available" label for 2 s

#### 5.2 — IAP Theme Unlocks
- Godot's built-in `InAppPurchase` singleton (Android)
- Product IDs: `theme_ocean`, `theme_ember`, `theme_void`
- On successful purchase: `SaveGame.set_theme_unlocked(name)`; `ThemeManager` unlocks the button

#### 5.3 — `export_presets.cfg`
```ini
[preset.0]  # Android Release (AAB)
platform = "Android"
export_filter = "all_resources"
exclude_filter = "specs/*,docs/*,build/*"
options/package/unique_name = "com.wordstorm.game"
options/screen/orientations = 1    # portrait
options/keystore/release = "%WORD_STORM_KEYSTORE_PATH%"
options/keystore/release_user = "%WORD_STORM_KEY_ALIAS%"
options/keystore/release_password = "%WORD_STORM_KEY_PASSWORD%"

[preset.1]  # Web HTML5
platform = "Web"
export_filter = "all_resources"
exclude_filter = "specs/*,docs/*"
options/progressive_web_app/enabled = false
```

#### 5.4 — Headless export commands
```bash
# Android APK (sideload / itch.io)
godot --headless --export-release "Android" build/android/WordStorm.apk

# Android AAB (Play Store)
godot --headless --export-release "Android AAB" build/android/WordStorm.aab

# Web HTML5 (itch.io browser)
godot --headless --export-release "Web" build/web/index.html
```

**Phase 5 done when**: Signed APK ≤ 30 MB installs and runs on device. Ad flow completes. Web export runs in browser on itch.io. AAB passes Play Store pre-launch report.

---

## Complexity Tracking

No constitution violations. All choices use Godot 4 built-ins (ad plugin in Phase 5 is Android-native, isolated behind a stub interface).

| Architectural Choice | Justification |
|----------------------|---------------|
| `Area2D` for LetterTile (not `CharacterBody2D`) | Tiles do not collide with each other; they fall in isolated columns. `Area2D.input_event` handles tap detection cleanly without physics overhead |
| `Dictionary` for word lookup (not `Array`) | O(1) average lookup vs O(n). 50k-word list would make O(n) validation noticeable at submit time on mid-range Android |
| Column-level `RandomNumberGenerator` instances (not global `randi()`) | Enables Daily Challenge reproducibility per-column; global rng shares state with the engine and would break determinism |
| `AdManager.gd` stub through phases 1–4 | Isolates ad SDK behind a stable interface; phases 1–4 have zero dependency on any ad SDK; Phase 5 swaps the stub without touching any other file |
| 8 autoloads | Each has a single non-overlapping responsibility. Collapsing them would create a 600+ line god object. Godot 4's autoload system has negligible overhead for 8 nodes |

---

## Session Roadmap

| Phase | Sessions (est.) | Gate to next phase |
|-------|-----------------|-------------------|
| 1 — Scaffold + title screen | 2 | App opens on Android, title renders, SaveGame works |
| 2 — Letter rain + lives | 3 | Letters fall, pile, life is lost correctly |
| 3 — Word selection + scoring | 3 | Full loop: spell → score → game over → restart |
| 4 — Juice + daily challenge | 3 | All juice events fire, daily seed reproducible |
| 5 — Monetisation + export | 2 | APK ≤ 30 MB, ad flow works, Web export runs |
| **Total** | **13 sessions** | ≈ 3–4 months at 1 session/week |

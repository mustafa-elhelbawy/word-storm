<div align="center">

# Word Storm

**Letters rain down. Spell words before the storm buries you.**

![Godot](https://img.shields.io/badge/Godot-4.3-478CBF?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-100%25-355570)
[![Play in browser](https://img.shields.io/badge/Play-in%20browser-00C8B8?logo=html5&logoColor=white)](https://www.glitchy-tap.com/revamp/games/word-storm/)
![Offline](https://img.shields.io/badge/Offline--first-yes-blue)
![Workflow](https://img.shields.io/badge/Workflow-Spec--Driven-8A2BE2)

### [▶ Play in your browser](https://www.glitchy-tap.com/revamp/games/word-storm/)

<sub>Hosted on <a href="https://www.glitchy-tap.com/revamp/">GlitchyTap</a>, the studio showcase I run with a fellow developer</sub>

</div>

---

A casual mobile word game built with **Godot 4 (GDScript)**. Letters rain down in five columns — tap to grab them, spell valid English words, and submit before the pile reaches the top. Miss too many and you lose a life. Lose three lives and the storm wins.

Targets **Android** (primary) and **Web/HTML5**. The web build is [playable on GlitchyTap](https://www.glitchy-tap.com/revamp/games/word-storm/).

## Highlights

- **Data-driven word engine:** ~100k-word English dictionary bundled offline, with O(1) hash lookup on every submit
- **Deterministic Daily Challenge:** per-column RNGs seeded from the date, so every player gets the same letter sequence
- **Signal-based architecture:** 8 single-responsibility autoloads that talk only through Godot signals
- **Mobile-first:** portrait touch input, APK size budget of 30 MB or less, Mobile renderer, fully offline save
- **Game feel:** combo multipliers, HUD tweens, pooled particles and audio, 4 switchable colour themes
- **Spec-driven delivery:** every phase was specified, planned, split into tasks, built on its own branch, reviewed in a PR, and review findings fixed before merge

---

## Gameplay

```
┌───┬───┬───┬───┬───┐
│   │ E │   │   │   │
│ T │   │ A │ R │   │
│   │ S │   │   │ M │
│ O │   │ N │ E │   │
╞═══╪═══╪═══╪═══╪═══╡  ← pile zone (danger line)
│ T │ E │ A │ R │ M │  ← piled tiles cost lives
└───┴───┴───┴───┴───┘

 Selected: [ T ][ E ][ A ][ R ]  →  TEAR  ✓  +25 pts
```

- **5 independent columns** — letters fall at increasing speed as the game progresses
- **Tap to select** — tap a selected tile again to deselect; order matters for scoring
- **Submit words of 3+ letters** — valid English words score points, destroy tiles, and keep columns clear
- **Pile overflow = life lost** — a column that fills to the danger line costs 1 of 3 lives
- **Combo multiplier**: chain valid words to reach ×1.5 (2 words) → ×2 (4) → ×3 (6). The combo resets after 6 s without a valid word
- **Speed escalates** every 30 seconds — from 80 px/s up to a 220 px/s cap
- **Daily Challenge** — same letter sequence for every player on a given date (date-derived seed)
- **Classic mode** — random seed, unlimited play until all 3 lives are gone

### Scoring

| Word length | Base points |
|-------------|-------------|
| 3 letters   | 10 pts      |
| 4 letters   | 25 pts      |
| 5 letters   | 50 pts      |
| 6+ letters  | 100 pts     |

Each tile also carries a Scrabble-style point value (1–10). High-value tiles like **Q**, **Z**, and **X** boost your score when used in words. The combo multiplier applies on top of all bonuses.

---

## Tech Stack

| | |
|---|---|
| **Engine** | Godot 4.3 stable (GDScript only — no C#, no GDNative) |
| **Target platforms** | Android API 26+ · Web HTML5 |
| **Viewport** | 400 × 680 logical px · Portrait locked |
| **Renderer** | Mobile (Godot's forward mobile pipeline) |
| **Persistence** | `user://save.json` via `FileAccess` — fully offline |
| **Word list** | Bundled `words_en.txt` — 100k entries, O(1) Dictionary lookup |
| **Themes** | 4 palettes (Default, Ocean, Ember, Void) via `ThemeManager.theme_changed` |
| **Monetisation** | Rewarded "continue" ad behind an `AdManager` interface (stubbed with Google test IDs; live AdMob SDK + IAP theme unlocks planned) |

---

## Project Structure

```
word-storm/
├── project.godot              # display, stretch, autoloads, input map
├── export_presets.cfg         # Android (AAB/APK) + Web HTML5 presets
│
├── scenes/
│   ├── main/                  # Main.tscn — root scene switcher
│   ├── screens/               # StartScreen, GameScreen, GameOver
│   ├── game/                  # Column, LetterTile, WordTray, PileIndicator
│   ├── overlays/              # SettingsOverlay
│   └── effects/               # TileBurst (GPUParticles2D)
│
├── scripts/
│   ├── GameScreen.gd          # Gameplay orchestrator · HUD · signal wiring
│   ├── Column.gd              # Per-column spawn, fall, pile + continue pre-fill (seeded RNG)
│   ├── LetterTile.gd          # Area2D tile · tap detection · Scrabble value
│   ├── WordTray.gd            # Selected-letter tray · submit / clear
│   ├── StartScreen.gd · GameOver.gd · SettingsOverlay.gd · Main.gd · TileBurst.gd
│   ├── Palette.gd             # Static colour constants (class_name, not autoload)
│   └── autoloads/             # 8 global singletons — load order matters
│       ├── GameManager.gd     # State machine · lives · speed progression
│       ├── ScoreManager.gd    # Points table · combo multiplier · best score
│       ├── WordValidator.gd   # Dictionary load · O(1) HashSet lookup
│       ├── SaveGame.gd        # FileAccess read/write for save.json
│       ├── ParticleManager.gd # Burst pool · column-colour mapping
│       ├── AudioManager.gd    # 8-slot AudioStreamPlayer pool
│       ├── AdManager.gd       # Rewarded ad interface (stub → real SDK in Phase 5)
│       └── ThemeManager.gd    # Palette per theme · theme_changed signal
│
├── assets/
│   ├── textures/              # sprite atlas slot
│   ├── audio/sfx/             # .ogg SFX slots (AudioManager skips missing files)
│   ├── fonts/                 # Orbitron (ui_font.ttf) + font resource
│   └── data/
│       └── words_en.txt       # 100k English words, 3–8 chars, bundled offline
│
├── docs/                      # Build guide, credits (.gdignore — excluded from APK)
└── specs/                     # Spec and task files (.gdignore — excluded from APK)
```

---

## Development Roadmap

The project is built in five phases, each sized for 1–2 hour coding sessions and delivered as a reviewed pull request.

| Phase | Goal | Status |
|-------|------|:------:|
| **1: Scaffold** | Godot project at 400×680 portrait; autoload stubs; word list + font bundled | ✅ |
| **2: Letter Rain** | `LetterTile`, `Column`, `GameManager`: letters fall in 5 columns and pile up; 3 lives → Game Over | ✅ |
| **3: Word Logic** | Tap → tray → validate → score or reject; full game loop | ✅ |
| **4: Juice & Daily** | Scoring combos, HUD tweens, particles, audio, themes, Daily Challenge | ✅ |
| **5: Screens & Export** | Start / Game Over / Settings screens, save system, ad-reward continue (stub), Android + Web export presets | ✅ |
| **Web release** | HTML5 build playable on [GlitchyTap](https://www.glitchy-tap.com/revamp/games/word-storm/) | ✅ |
| **Next** | Final SFX + art atlas, live AdMob + IAP, signed Play Store release | 🔜 |

### How it was built

Each phase followed a spec-driven loop ([GitHub Spec Kit](https://github.com/github/spec-kit)): **specify → plan → tasks → implement → architect review → fix → merge**. The specs and task files live in [`specs/`](specs). The commit history shows each review round (for example `fix(phase-3): resolve all 4 architect review findings`).

---

## Building

### Prerequisites

- [Godot 4.3 stable](https://godotengine.org/download)
- Android SDK + NDK (for Android export)
- Android export templates (Editor → Export → Manage Export Templates → Download)

### Run in editor

Open Godot 4, choose **Import**, point it at the `word-storm/` directory, and press **Play**.

Or via CLI:

```bash
godot --path /path/to/word-storm
```

### Export — Android APK (sideload / itch.io)

```bash
godot --headless --export-release "Android" build/android/WordStorm.apk
```

### Export — Android AAB (Play Store)

```bash
# Keystore details are never committed — pass via environment variables
export WORD_STORM_KEYSTORE_PATH=/path/to/release.keystore
export WORD_STORM_KEY_ALIAS=upload
export WORD_STORM_KEY_PASSWORD=your_password

godot --headless --export-release "Android AAB" build/android/WordStorm.aab
```

### Export — Web HTML5 (itch.io)

```bash
godot --headless --export-release "Web" build/web/index.html
```

> **APK size target**: ≤ 30 MB hard cap. Word list is plain `.txt` (694 KB), audio is `.ogg`, no third-party plugins before Phase 5.

---

## Architecture Notes

**Why `Area2D` for letter tiles instead of `CharacterBody2D`?**
Tiles fall independently in isolated columns and never collide with each other. `Area2D.input_event` handles tap detection cleanly with zero physics overhead.

**Why `Dictionary` for word lookup instead of `Array`?**
O(1) average lookup vs O(n). Scanning 100k words on every submit would be noticeable on mid-range Android hardware.

**Why per-column `RandomNumberGenerator` instances?**
Daily Challenge reproducibility — each column's RNG is seeded from `session_seed ^ column_id`. Same date = identical letter sequence on any device, anywhere.

**Why 8 autoloads?**
Each has a single non-overlapping responsibility. Collapsing them creates 500+ line god objects. Godot 4's autoload system has negligible overhead for 8 nodes.

---

## Signal Map

The game communicates entirely through Godot signals — no direct cross-node calls between unrelated systems.

| Signal | Emitter → Receiver | When fired |
|--------|-------------------|------------|
| `tile_tapped(tile)` | LetterTile → WordTray | Player taps a falling or piled tile |
| `pile_overflow(column_id)` | Column → GameManager | Pile reaches `MAX_PILE` (5 tiles) |
| `word_submitted(tiles)` | WordTray → WordValidator | Player taps Submit with ≥ 3 tiles |
| `word_valid(word, tiles, score)` | WordValidator → GameScreen / ScoreManager / ParticleManager / AudioManager | Dictionary lookup passes |
| `word_invalid(word)` | WordValidator → WordTray / AudioManager | Dictionary lookup fails |
| `life_lost(lives_remaining)` | GameManager → HUD / AudioManager | Overflow received; lives decremented |
| `game_over` | GameManager → Main | Lives reach 0 |
| `speed_increased(new_speed)` | GameManager → all Columns | Every 30 s of play |
| `theme_changed(palette)` | ThemeManager → all visual nodes | Player selects a theme |
| `ad_reward_granted` | AdManager → GameManager | Rewarded ad watched to completion |

---

## Constraints

| Rule | Detail |
|------|--------|
| GDScript + Godot 4 only | No C#, GDNative, or third-party plugins in Phases 1–4 |
| Portrait touch only | All input via `InputEventScreenTouch`; mouse emulation for editor only |
| Offline-first | Word list and save data are fully local; no network dependency |
| APK ≤ 30 MB | Specs/docs excluded via `.gdignore`; no large binary assets |
| Halal-safe ads | AdMob category exclusions enforced before any live ad traffic |
| Single-player only | No multiplayer, no live leaderboard — local best score only |

---

## Credits

- **Design & development**: [Mustafa El-Helbawy](https://github.com/mustafa-elhelbawy)
- **Font**: [Orbitron](https://fonts.google.com/specimen/Orbitron) by Matt McInerney — SIL Open Font License 1.1
- **Word list**: [dwyl/english-words](https://github.com/dwyl/english-words) — The Unlicense

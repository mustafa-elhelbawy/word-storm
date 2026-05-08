# Word Storm — Task Index

26 tasks across 5 phases. Each task is one Claude Code session (45–120 min).

---

## Phase 1 — Environment Setup _(no GDScript yet)_

| ID | Title | Est. |
|----|-------|------|
| [T001](T001.md) | Create Godot 4 project: display 400×680 + Android export preset | 45 min |
| [T002](T002.md) | Create full folder structure + 8 autoload stubs | 20 min |
| [T003](T003.md) | Import Orbitron/Space Mono font → assets/fonts/ | 20 min |
| [T004](T004.md) | Create words_en.txt word list (50k+ entries) | 30 min |
| [T005](T005.md) | Write Palette.gd static colour class | 15 min |

**Phase 1 gate**: Project opens, displays 400×680 portrait, all 8 autoload stubs parse cleanly.

---

## Phase 2 — Core Tile System

| ID | Title | Est. | Depends on |
|----|-------|------|-----------|
| [T006](T006.md) | Build LetterTile.tscn (Area2D, CollisionShape2D, labels) | 45 min | T001–T005 |
| [T007](T007.md) | Write LetterTile.gd (fall, tap, state machine, signals) | 90 min | T006 |
| [T008](T008.md) | Build Column.tscn + Column.gd (spawn, fall speed, letter weights) | 120 min | T007 |
| [T009](T009.md) | Write GameManager.gd (state machine, lives, speed progression) | 90 min | T008 |

**Phase 2 gate**: Letters fall in 5 columns, pile up, losing 3 lives transitions to GameOver.

---

## Phase 3 — Word Logic

| ID | Title | Est. | Depends on |
|----|-------|------|-----------|
| [T010](T010.md) | Build WordTray.tscn + WordTray.gd (8-slot display, add/remove) | 90 min | T007, T009 |
| [T011](T011.md) | Write WordValidator.gd (Dictionary load, is_valid, signals) | 60 min | T004, T010 |
| [T012](T012.md) | Build GameScreen.tscn + wire Submit/Clear buttons | 90 min | T009–T011 |
| [T013](T013.md) | Add spawn constraints to Column.gd (Q→U rule, duplicate cap) | 45 min | T008, T009 |

**Phase 3 gate**: Full game loop — tap letters → spell → validate → score/reject → game over → restart.

---

## Phase 4 — Scoring, Effects, HUD

| ID | Title | Est. | Depends on |
|----|-------|------|-----------|
| [T014](T014.md) | Write ScoreManager.gd (points table, combo multiplier, best score) | 90 min | T011, T012 |
| [T015](T015.md) | Build HUD (score count-up tween, lives hearts dim) | 90 min | T014, T009 |
| [T016](T016.md) | Write ParticleManager.gd + TileBurst.tscn (column-coloured bursts) | 90 min | T012, T014, T005 |
| [T017](T017.md) | Combo popup tween + speed-up banner flash | 60 min | T015, T014, T009 |
| [T018](T018.md) | Write AudioManager.gd + wire all 6 SFX events | 60 min | T012, T007 |

**Phase 4 gate**: All juice events fire. Score/combo/lives animate correctly. Particles and audio play.

---

## Phase 5 — Screens, Save, Export

| ID | Title | Est. | Depends on |
|----|-------|------|-----------|
| [T019](T019.md) | Build StartScreen.tscn (logo, best score, star particles, play button) | 90 min | T009, T003, T005 |
| [T020](T020.md) | Build GameOver.tscn (score, best, ad slot, play again) | 75 min | T009, T014 |
| [T021](T021.md) | Build SettingsOverlay.tscn + write ThemeManager.gd | 90 min | T019, T005 |
| [T022](T022.md) | Write Main.tscn + Main.gd (scene switcher via state machine) | 45 min | T009, T019, T020 |
| [T023](T023.md) | Write SaveGame.gd (FileAccess, best_score, theme, sound, daily) | 75 min | T014, T021 |
| [T024](T024.md) | Source and add 6 × .ogg sound effect files | 60 min | T018 |
| [T025](T025.md) | Wire AdMob rewarded ad plugin to GameOver continue button | 120 min | T020, T001 |
| [T026](T026.md) | Export Android AAB (signed) + Web HTML5 for itch.io | 90 min | T001–T025 |

**Phase 5 gate**: Signed APK ≤ 30 MB installs and runs on device. Ad flow works. Web build runs in browser.

---

## Total estimated time

| Phase | Tasks | Time |
|-------|-------|------|
| Phase 1 — Environment | 5 | ~2.2 h |
| Phase 2 — Tile system | 4 | ~5.75 h |
| Phase 3 — Word logic | 4 | ~4.75 h |
| Phase 4 — Effects/HUD | 5 | ~6.5 h |
| Phase 5 — Screens/Export | 8 | ~10.75 h |
| **Total** | **26** | **~30 h** |

At 2 sessions/week (90 min each): **~10 weeks to ship.**

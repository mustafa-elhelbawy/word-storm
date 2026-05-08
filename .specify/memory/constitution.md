# Word Storm Constitution

## Core Principles

### I. GDScript + Godot 4 Only (NON-NEGOTIABLE)
The sole language is GDScript. The sole engine is Godot 4 (stable release, standard build — not .NET/C#). No third-party plugins, no GDNative extensions, no external libraries. Every feature must be achievable with Godot 4 built-ins. If a feature requires a plugin or external dependency, it is out of scope.

### II. Portrait Mobile — Touch Input Only (NON-NEGOTIABLE)
The game targets Android in portrait orientation exclusively. All player input must use `InputEventScreenTouch` and `InputEventScreenDrag`. No keyboard, mouse, or gamepad input in game logic. Landscape orientation will not be handled. The canonical viewport is 360 × 780 logical pixels; Godot's `canvas_items` stretch mode handles other screen sizes.

### III. Offline-First — No External Servers Required to Play (NON-NEGOTIABLE)
The core game loop must run fully offline. No API calls, no remote content fetching, no login/account requirement, and no server-side validation are permitted for any gameplay feature. Optional network calls (e.g. ad SDKs, analytics) must degrade gracefully to a no-op when offline — they must never block gameplay or cause a crash.

### IV. APK Under 30 MB (NON-NEGOTIABLE)
The exported signed release APK must not exceed 30 MB. All assets (textures, audio, fonts) must be optimised before import. Audio must use `.ogg` format. Textures must use compressed formats appropriate for the mobile renderer. The `specs/` and `docs/` directories must be excluded from the APK via `.gdignore`. No asset may be added without checking the current APK size estimate.

### V. Halal-Safe Ads Only (NON-NEGOTIABLE)
If ads are integrated, only ad networks and creatives that can be filtered to halal-safe content are permitted. Ad placements must not display: alcohol, gambling, dating/adult content, music with prohibited content, or financial products involving riba. Ad integration must include category-exclusion configuration. When in doubt, the ad placement is removed — revenue is never prioritised over content compliance.

### VI. Single-Player Only — No Multiplayer (NON-NEGOTIABLE)
The game is strictly single-player. No real-time multiplayer, no async multiplayer (turn-based challenges, ghost data), no leaderboards that require a live server. Local high-score persistence is permitted. Any feature that requires comparing a player's state against another live player's state is out of scope for v1 and must not be architected for.

### VII. Tight Scope — No Speculative Features
Features not described in the active specification must not be implemented. No "while I'm here" additions, no forward-compatibility shims, no placeholder UI for future screens. Three similar lines of GDScript are better than a premature abstraction. Every addition must trace back to an accepted user story.

## Performance Standards

| Metric | Target |
|--------|--------|
| Minimum frame rate | ≥ 60 fps sustained on mid-range Android (2019–2021, Adreno 618 / Mali-G76) |
| Draw calls per frame | ≤ 30 during active gameplay |
| APK size (release, signed) | ≤ 30 MB |
| Heap allocation in `_physics_process` | Zero — no new objects per frame |
| App cold-start to playable | ≤ 5 seconds |

## Development Constraints

- **Renderer**: `mobile` (never `forward_plus`) — required for mid-range Android performance.
- **Scripting**: GDScript only. All non-trivial blocks must include `# [JS equiv]` comments (developer background is JavaScript/TypeScript).
- **Audio format**: `.ogg` only — lowest latency on Android, no decoder initialisation delay.
- **Texture atlas**: All sprites per scene must share a single texture atlas — one draw call per atlas.
- **Autoloads**: Maximum four autoload singletons. Each must have a single, non-overlapping responsibility.
- **Build machine**: Headless CLI export (`godot --headless --export-release`) must work on Mac, Windows, and Linux without opening the editor.
- **Secrets**: Keystore credentials must never be committed. Use environment variables only.

## Governance

This constitution supersedes all other practices. Any proposed exception to a NON-NEGOTIABLE principle requires explicit written approval and must be documented as an amendment with a rationale and migration note. All spec, plan, and task reviews must verify compliance with these principles before proceeding.

**Version**: 1.0.0 | **Ratified**: 2026-05-09 | **Last Amended**: 2026-05-09

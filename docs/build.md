# Build Guide — Word Storm

Headless export steps for Android and Web. Requires Godot 4.3 CLI and Android SDK.

## Prerequisites

```bash
# Godot 4.3 CLI available on PATH (rename the binary to 'godot')
godot --version   # should print 4.3.x

# Android SDK + NDK (set in Godot Editor → Editor Settings → Export → Android)
# JAVA_HOME, ANDROID_SDK_ROOT must be set in the environment

# Signing keystore (release builds only)
# Set via environment variables — never commit to the repo:
#   GODOT_ANDROID_KEYSTORE_PATH
#   GODOT_ANDROID_KEYSTORE_USER
#   GODOT_ANDROID_KEYSTORE_PASSWORD
```

## Android — debug APK (sideload)

```bash
godot --headless --export-debug "Android" build/android/word-storm-debug.apk
```

## Android — release AAB (Play Store)

```bash
godot --headless --export-release "Android" build/android/word-storm.aab
```

## Web / HTML5 (itch.io)

```bash
godot --headless --export-release "Web" build/web/index.html
```

Output lands in `build/android/` and `build/web/` — both directories are gitignored.

## Notes

- `export_presets.cfg` is committed but contains no keystore paths. Signing credentials are injected at export time via the env vars above.
- `build/` output is gitignored — never commit `.apk`, `.aab`, or `.html` export artefacts.
- Run exports from the project root (where `project.godot` lives).

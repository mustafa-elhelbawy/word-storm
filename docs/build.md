# Build Guide — Word Storm

Headless export steps for Android and Web. Requires Godot 4.3 CLI and Android SDK.

## Prerequisites

```bash
# Godot 4.3 CLI available on PATH (rename the binary to 'godot')
godot --version   # should print 4.3.x

# Android SDK + NDK (set in Godot Editor → Editor Settings → Export → Android)
# JAVA_HOME, ANDROID_SDK_ROOT must be set in the environment

# Signing keystore (release builds only) — store OUTSIDE the git repo
keytool -genkey -v -keystore ~/keystores/word-storm.keystore \
  -alias word-storm -keyalg RSA -keysize 2048 -validity 10000
```

## Required Environment Variables

```bash
export WORD_STORM_KEYSTORE_PATH="/path/to/word-storm.keystore"
export WORD_STORM_KEY_ALIAS="word-storm"
export WORD_STORM_KEY_PASSWORD="your-key-password"
export WORD_STORM_STORE_PASSWORD="your-store-password"
export ADMOB_APP_ID="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"
export PROD_REWARDED_ID="ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
```

Set `TEST_MODE = false` in `scripts/autoloads/AdManager.gd` before release.

## Android — debug APK (sideload)

```bash
mkdir -p build/android
godot --headless --export-debug "Android APK (sideload)" build/android/WordStorm-debug.apk
```

## Android — release AAB (Play Store)

```bash
godot --headless --export-release "Android Release (AAB)" build/android/WordStorm.aab
```

## Web / HTML5 (itch.io)

```bash
mkdir -p build/web
godot --headless --export-release "Web HTML5" build/web/index.html
```

## APK Size Check (must be ≤ 30 MB)

```bash
APK_SIZE=$(stat -f%z build/android/WordStorm-debug.apk 2>/dev/null \
           || stat -c%s build/android/WordStorm-debug.apk)
if [ "$APK_SIZE" -gt 31457280 ]; then
  echo "ERROR: APK exceeds 30 MB ($APK_SIZE bytes)" >&2; exit 1
fi
echo "APK size: $(( APK_SIZE / 1024 / 1024 )) MB — OK"
```

## Pre-export Checklist

- [ ] `AdManager.gd`: `TEST_MODE = false`, `PROD_REWARDED_ID` set via env var
- [ ] 6 SFX files present: `ls assets/audio/sfx/*.ogg | wc -l` == 6
- [ ] Word list: `wc -l assets/data/words_en.txt` ≥ 50000
- [ ] No leaking prints: `grep -r 'print(' scripts/` shows nothing sensitive
- [ ] Keystore env vars set in current shell
- [ ] `build/` is gitignored

## Device Install & Smoke Test

```bash
adb install build/android/WordStorm-debug.apk
adb shell am start -n com.wordstorm.game/com.godot.game.GodotApp
```

Verify: cold start ≤ 5 s, full game loop (Start → Play → Game Over → Play Again), ad slot behaves.

## Web Local Test

```bash
python3 -m http.server 8080 --directory build/web
# Open http://localhost:8080
```

## Notes

- `export_presets.cfg` is committed but contains no keystore paths. Signing credentials are injected at export time via env vars above.
- `build/` output is gitignored — never commit `.apk`, `.aab`, or `.html` artefacts.
- Run exports from the project root (where `project.godot` lives).
- AdMob requires `custom_build = true` in the Android preset (adds Gradle build step).

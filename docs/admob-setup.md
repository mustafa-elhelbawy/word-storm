# AdMob Setup — Word Storm

Steps to configure AdMob for a new Google Play release.

## 1. Create an AdMob Account

Sign in at https://admob.google.com and create a new app entry for Word Storm (Android).

## 2. Get Your App ID and Ad Unit IDs

From the AdMob dashboard after adding the app:

- **App ID** — looks like `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`
- **Rewarded Ad Unit ID** — create one ad unit of type "Rewarded"; looks like `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`

## 3. Install the GodotAdMob Plugin

Follow the [godot-admob-android](https://github.com/Poing-Studios/godot-admob-android) plugin README:

```bash
# Place the plugin .aar and .gdap files in res://addons/admob/
# Enable the plugin in Project → Project Settings → Plugins
```

The Android export preset already has `gradle_build/use_custom_build=true` which triggers the Gradle build step required by the plugin.

## 4. Set Environment Variables (CI / local release build)

Never commit real IDs. Inject them at export time:

```bash
export ADMOB_APP_ID="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"
export PROD_REWARDED_ID="ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
```

Add these to your CI secrets (GitHub Actions → Settings → Secrets).

## 5. Flip TEST_MODE Before Release

In `scripts/autoloads/AdManager.gd`:

```gdscript
const TEST_MODE: bool = false   # ← change from true
```

## 6. Category Blocking (optional but recommended)

In the AdMob dashboard under **Block controls → Manage ad categories**, block:

| Category | Reason |
|---|---|
| Dating | Inappropriate for all-ages word game |
| Gambling | Not suitable for mobile casual audience |
| Politics | Avoid controversy |
| Religion | Avoid controversy |

This reduces fill rate marginally but improves user experience and app store review outcomes.

## 7. Test Ads

Keep `TEST_MODE = true` during development. The test ad unit `ca-app-pub-3940256099942544/5224354917` always returns a test rewarded ad on real devices. Never use real ad unit IDs on a device that hasn't been added to the AdMob test-device list.

## 8. GDPR / Consent (if distributing in EEA)

Integrate the [User Messaging Platform (UMP) SDK](https://developers.google.com/admob/android/privacy/gdpr) before requesting ads. This is outside the current scope but required for EEA distribution.

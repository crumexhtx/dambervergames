# Android export (Godot 4.3+)

## One-time setup

1. Install **Android Studio** (SDK + NDK + JDK 17).
2. In Godot: **Editor → Editor Settings → Export → Android**
   - Set JDK path, Android SDK path, debug keystore (Godot can create one).
3. **Project → Install Android Build Template** (optional, for custom builds).

## Using the preset in this repo

1. Copy [`export_presets.cfg.example`](../export_presets.cfg.example) to `export_presets.cfg` in the project root (gitignored).
2. Open **Project → Export → Android** and confirm paths/keystore.
3. Export:
   - Debug APK for device testing
   - Release AAB for Play Store (requires your release keystore)

CLI example (after presets exist):

```bash
godot --headless --path . --export-debug "Android" build/beaver-survivor-debug.apk
```

## Mobile checklist

- Portrait 720×1280, stretch `canvas_items` / expand
- Touch joystick + large DASH button (Settings → Large joystick)
- **Perf lite** toggle reduces FX when FPS dips (recommended on mid phones)
- Alive enemy cap remains **80** (wave director)
- Emulate touch from mouse enabled for desktop testing

## Performance tips on device

- Enable Settings → Perf lite if Wave 10 stutters
- Prefer the **Mobile** renderer (already set in `project.godot`)
- Avoid editor remote debug for FPS measurements; use a release/debug APK on hardware

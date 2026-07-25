# Host bridge (phone → PC project folder)

Android and iOS apps cannot write files into your Windows/macOS project directory. The **guardian bridge** is a small local HTTP server that receives a report when you tap **Save** in the app and writes:

```text
<your_project>/flutter_health_guard/report.html
<your_project>/flutter_health_guard/report.json
<your_project>/flutter_health_guard/guardian.log
```

![Bridge flow](images/04-bridge-flow.png)

## Important

- Starting the bridge **alone does not create a report**.
- Keep the bridge running, then in the app open the report and tap **Save**.
- Sync is **one-shot per Save**, not continuous.

## Quick start

From your **app project root** (the folder that contains `pubspec.yaml`):

**Terminal 1**

```bash
dart run flutter_health_guard:guardian_bridge --package com.example.your_app
```

Use your Android `applicationId` from `android/app/build.gradle` (e.g. `com.example.package_testing`).

**Terminal 2**

```bash
flutter run
```

In the app: **shield → Save**. Terminal 1 should show:

```text
[bridge] HTTP sync → D:\...\flutter_health_guard\report.html
```

Open that HTML file in a browser.

## How sync works

1. **HTTP push (primary)**  
   App POSTs JSON/HTML to `http://127.0.0.1:7421/report` (and on Android emulator also tries `10.0.2.2`).

2. **`adb reverse`**  
   Maps device `127.0.0.1:7421` → host `127.0.0.1:7421` so a physical phone can reach the bridge.

3. **`adb` pull (optional fallback)**  
   If you pass `--package`, the bridge periodically reads  
   `app_flutter/flutter_health_guard/*` via `run-as` and copies files to the project folder.

## Flags

| Flag | Default | Meaning |
|------|---------|---------|
| `--port` | `7421` | HTTP listen port |
| `--package` | _(none)_ | Android applicationId for `adb` pull fallback |

Example:

```bash
dart run flutter_health_guard:guardian_bridge --port 7421 --package com.example.package_testing
```

## adb / platform-tools

The bridge looks for `adb` in:

1. `PATH` (`where adb` / `which adb`)
2. `%ANDROID_HOME%\platform-tools\` / `$ANDROID_SDK_ROOT/platform-tools/`
3. `%LOCALAPPDATA%\Android\Sdk\platform-tools\` (typical Windows Android Studio install)

If you see `adb: NOT FOUND`:

1. Install **Android SDK Platform-Tools** via Android Studio SDK Manager, or  
2. Add `...\Android\Sdk\platform-tools` to your system `PATH`, then restart the terminal and bridge.

### Emulator vs physical device

| Target | Notes |
|--------|--------|
| Emulator | Can sync via `10.0.2.2` even when reverse fails |
| Physical phone | Needs working `adb reverse` (USB debugging on, device authorized) |

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Folder empty after starting bridge | Tap **Save** in the app; watch for `[bridge] HTTP sync` |
| `adb reverse: FAILED` | Start emulator / plug phone; run `adb devices`; restart bridge |
| Export dialog says “Saved on device only” | Bridge not reachable — check Terminal 1 is still running and reverse OK |
| Wrong project folder | Run bridge from the **app** project root, not from the package repo |
| Debug prints “Bridge not running” | Start bridge first, then Save again |

## Desktop reminder

On Windows/macOS/Linux, **Save** already writes into `<project>/flutter_health_guard/`. You do not need the bridge on desktop.

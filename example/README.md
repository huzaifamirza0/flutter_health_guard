# Flutter Health Guard — Example

Demo app for [`flutter_health_guard`](../README.md): draggable shield FAB, in-app health report, network/navigation samples, and one-click export.

## Screenshots

| FAB on the demo home | In-app health report |
|----------------------|----------------------|
| ![FAB](../doc/images/01-fab-overlay.png) | ![Report](../doc/images/02-in-app-report.png) |

| Export / sync dialog | HTML report (after Save) |
|----------------------|--------------------------|
| ![Export](../doc/images/03-export-dialog.png) | ![HTML](../doc/images/05-html-report.png) |

> Images are illustrative mockups that match the real UI (dark theme, green shield, report layout).

## What this example shows

- `Guardian.initialize()` in `main`
- `navigatorObservers: [Guardian.navigatorObserver]`
- `GuardianOverlay` in `MaterialApp.builder` (debug only)
- `GuardianWatch` rebuild tracking
- Real HTTP GET with `package:http`
- Navigation to a detail route
- A captured demo error
- **Save** on the report page → files under `flutter_health_guard/`

## Run

```bash
cd example
flutter pub get
flutter run
```

Use any device: Windows, macOS, Linux, Android, or iOS.

### Try the flow

1. Tap **Tap** a few times (rebuilds).  
2. Press **GET** (network).  
3. Press **Open** (navigation).  
4. Optionally **Throw** (crash capture).  
5. Tap the **green shield** → review the report.  
6. Tap **Save** (and **Copy** if you want JSON on the clipboard).  
7. Open `example/flutter_health_guard/report.html` (desktop) or use the [bridge](../doc/bridge.md) on a phone.

### Phone → PC project folder

**Terminal 1** (from `example/`):

```bash
dart run flutter_health_guard:guardian_bridge --package com.flutterguardian.example.guardian_example
```

Check `applicationId` in `android/app/build.gradle` if the package name differs.

**Terminal 2:** `flutter run` → shield → **Save** → watch for `[bridge] HTTP sync`.

![Bridge flow](../doc/images/04-bridge-flow.png)

## Dependency

```yaml
dependencies:
  flutter_health_guard:
    path: ../
```

## Notes

- Prefer a **desktop or mobile** target for the full demo (web has limited network/file support).
- More guides: [Getting started](../doc/getting-started.md) · [Bridge](../doc/bridge.md) · [Overlay](../doc/overlay-and-report.md)

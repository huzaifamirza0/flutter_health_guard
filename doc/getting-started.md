# Getting started

This guide takes you from zero to a health report in a few minutes.

## Prerequisites

- Flutter **3.27+** / Dart **3.6+**
- A Flutter app you can run in **debug** mode
- (Optional, for phone → PC files) Android `platform-tools` (`adb`)

## 1. Add the dependency

Until published under a unique pub.dev name, use git or path:

```yaml
dependencies:
  flutter_health_guard:
    git:
      url: https://github.com/huzaifamirza0/flutter_health_guard.git
      ref: main
```

```bash
flutter pub get
```

## 2. Initialize once

```dart
import 'package:flutter_health_guard/flutter_health_guard.dart';

Future<void> main() async {
  await Guardian.initialize();
  runApp(const MyApp());
}
```

Call `initialize` **before** `runApp` so startup time and early errors are captured.

## 3. Attach observer + overlay

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_health_guard/flutter_health_guard.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [Guardian.navigatorObserver],
      builder: (context, child) => GuardianOverlay(
        visible: kDebugMode,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomePage(),
    );
  }
}
```

| Piece | Why |
|-------|-----|
| `navigatorObserver` | Route push/pop timeline |
| `GuardianOverlay` | Draggable shield → in-app report |
| `visible: kDebugMode` | Keep release builds clean |

## 4. Use the app, then open the report

```bash
flutter run
```

1. Navigate, call APIs, interact with UI.
2. Tap the **green shield**.
3. Review scores and recommendations.
4. Tap **Save** when you want files on disk.

![FAB on demo app](images/01-fab-overlay.png)

![In-app report](images/02-in-app-report.png)

## 5. Where are the files?

| Where you run | Default output |
|---------------|----------------|
| Windows / macOS / Linux | `<project>/flutter_health_guard/` |
| Android / iOS device | App documents `…/flutter_health_guard/` |
| Android / iOS + bridge + Save | Also `<project>/flutter_health_guard/` on the PC |

Phone → PC steps: [bridge.md](bridge.md)

## 6. Optional: track rebuilds

```dart
GuardianWatch(
  name: 'CheckoutButton',
  child: CheckoutButton(...),
)
```

Only wrapped widgets appear under rebuild stats.

## Next

- [Overlay & report UI](overlay-and-report.md)
- [Bridge (phone → PC)](bridge.md)
- [Configuration](configuration.md)
- [API reference](api.md)
- [Example app](../example/README.md)

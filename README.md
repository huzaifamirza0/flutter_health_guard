# Flutter Guardian

> **The Lighthouse of Flutter** — analyze your app, score its health, and get actionable recommendations.

`flutter_guardian` automatically collects crashes, network traffic, performance, navigation, and device data during a session, then produces:

| Artifact | Purpose |
|----------|---------|
| `report.json` | **Source of truth** (CLI, HTML, and future dashboard all render this) |
| `report.html` | Self-contained interactive dashboard (open in any browser) |
| CLI summary | Instant scores in your terminal when the report is generated |

```
Flutter App
    │
    ▼
flutter_guardian collectors
    │
    ▼
Analyzer → Score Engine → Recommendations
    │
    ▼
report.json
    ├── HTML renderer (v0.1)
    ├── CLI summary (v0.1)
    └── Dashboard / guardian.dev (later)
```

## Quick start

```yaml
dependencies:
  flutter_guardian:
    path: ../flutter_guardian   # or pub.dev version later
```

```dart
import 'package:flutter_guardian/flutter_guardian.dart';

Future<void> main() async {
  await Guardian.initialize(
    config: const GuardianConfig(
      enableLogs: true,
      enableNetwork: true,
      enablePerformance: true,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [Guardian.navigatorObserver],
      home: const HomePage(),
    );
  }
}
```

Track rebuild-heavy widgets:

```dart
GuardianWatch(
  name: 'ProductCard',
  child: ProductCard(...),
)
```

Generate a report anytime:

```dart
await Guardian.generateReport();
// → .flutter_guardian/report.html
// → .flutter_guardian/report.json
```

## What v0.1 collects

- Exceptions & Flutter errors
- `debugPrint` / manual logs
- HTTP requests (`dart:io` via `HttpOverrides`)
- Navigation (route push/pop)
- App lifecycle
- Device / platform info
- Startup time (first frame)
- Frame timings (FPS / jank)
- Widget rebuilds (`GuardianWatch`)

## Scores

The score engine runs **before** any UI renderer:

- Performance
- Memory (proxy heuristics in v0.1)
- Network
- Stability
- UI
- Architecture
- Security
- **Overall** (weighted)

Recommendations explain *what* to fix and estimate impact (e.g. `+8% FPS`).

## Architecture roadmap

```
flutter_guardian
├── guardian_core          ← you are here (v0.1)
├── guardian_network       ← deeper Dio / cURL export
├── guardian_performance   ← memory / CPU / battery
├── guardian_storage       ← Hive / Isar / SQLite
├── guardian_dashboard     ← web UI
├── guardian_cli           ← `flutter_guardian analyze`
└── guardian_cloud         ← guardian.dev
```

## Example

```bash
cd example
flutter pub get
flutter run -d windows   # or chrome / android
# Tap around → Generate Guardian report
# Open .flutter_guardian/report.html
```

## License

MIT

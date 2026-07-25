# API reference

Import:

```dart
import 'package:flutter_health_guard/flutter_health_guard.dart';
```

Generate full dartdoc:

```bash
dart doc
```

## Guardian (facade)

### `Guardian.initialize({ GuardianConfig? config })`

Starts collectors. Call once before `runApp`.

### `Guardian.navigatorObserver`

`NavigatorObserver` — add to `MaterialApp.navigatorObservers` (or Cupertino).

### `Guardian.log(String message, { String level, String? tag })`

Structured log entry in the session store.

### `Guardian.recordNetwork(NetworkEvent event)`

Manual network event (e.g. Dio interceptor). Useful when traffic does not go through `HttpClient` / `package:http`.

### `Guardian.analyze()` → `GuardianReport?`

Runs the analyzer in memory. Does not write files.

### `Guardian.generateReport()` → `Future<ReportArtifacts?>`

Analyzes and writes `report.json` / `report.html` (and log) under the configured output directory.

### `Guardian.exportReport({ bool tryHostSync = true })` → `Future<ReportArtifacts?>`

Calls `generateReport()`, then on debug mobile tries to POST artifacts to `guardian_bridge`.  
`ReportArtifacts.hostSynced` is `true` when the PC bridge accepted the upload.

### `Guardian.dispose({ bool generateReport = true })`

Stops collectors; optionally writes a final report when `autoGenerateReport` is enabled.

### Paths

- `Guardian.reportDirectory` — resolved output folder (when known)
- `Guardian.lastReportHtmlPath` — last written HTML path

## Widgets

### `GuardianOverlay({ required Widget child, bool visible = true })`

Draggable FAB that opens the report. Use inside `MaterialApp.builder`.

### `GuardianReportPage({ VoidCallback? onClose })`

Full-screen report UI. `onClose` is used when the page is shown outside a normal pop (overlay fallback).

### `GuardianWatch({ required String name, required Widget child })`

Counts rebuilds for `name` in the session report.

## Models (high level)

| Type | Role |
|------|------|
| `GuardianReport` | Full analyzed session (`toJson()`) |
| `ReportArtifacts` | Paths + in-memory HTML/JSON + `hostSynced` |
| `GuardianConfig` | Collector / output toggles |
| `NetworkEvent` | Manual network recording |

## Executable

```bash
dart run flutter_health_guard:guardian_bridge [--port 7421] [--package <applicationId>]
```

See [bridge.md](bridge.md).

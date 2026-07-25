# Configuration

Pass an optional `GuardianConfig` into `Guardian.initialize`:

```dart
await Guardian.initialize(
  config: const GuardianConfig(
    enableNetwork: true,
    autoGenerateReport: true,
    reportUpdateInterval: Duration(seconds: 3),
    printCliSummary: true,
  ),
);
```

## Fields

| Field | Default | Description |
|-------|---------|-------------|
| `enableLogs` | `true` | Capture `debugPrint` + `Guardian.log` |
| `enableNetwork` | `true` | HTTP via `HttpOverrides` (IO only) |
| `enablePerformance` | `true` | Frame timings / FPS / jank |
| `enableNavigation` | `true` | Route events via observer |
| `enableCrashes` | `true` | Flutter + async errors |
| `enableLifecycle` | `true` | App lifecycle |
| `enableDeviceInfo` | `true` | Platform / OS / locale |
| `autoGenerateReport` | `true` | Write report after first frame and on an interval |
| `generateHtml` | `true` | Emit `report.html` |
| `generateJson` | `true` | Emit `report.json` |
| `printCliSummary` | `true` | Print summary the first time a report is written |
| `outputDirectory` | `null` | See [Output paths](#output-paths) |
| `reportUpdateInterval` | `3s` | How often on-disk report refreshes while running |
| `maxNetworkEvents` | `500` | Ring buffer cap |
| `maxLogEvents` | `1000` | Ring buffer cap |
| `maxNavigationEvents` | `200` | Ring buffer cap |
| `slowFrameThresholdMs` | `16.7` | Slow frame threshold |
| `jankFrameThresholdMs` | `33.0` | Jank frame threshold |

## Output paths

When `outputDirectory` is `null`:

| Platform | Directory |
|----------|-----------|
| Desktop | `<project>/flutter_health_guard/` |
| Android / iOS | App documents `…/flutter_health_guard/` |

- Absolute path → used as-is  
- Relative path → resolved next to the default base directory  

## Auto generate vs export

| API | Behavior |
|-----|----------|
| `autoGenerateReport` | Keeps refreshing **on-device / desktop** files on an interval |
| `Guardian.exportReport()` | One-shot write + **optional** bridge push to the PC project (mobile) |

The bridge is only contacted from `exportReport` (Save button), not on every auto refresh — so your PC folder is not spammed.

## Disable collectors you do not need

```dart
await Guardian.initialize(
  config: const GuardianConfig(
    enableNetwork: false,
    enableLogs: false,
    autoGenerateReport: false, // only write when you call generateReport / exportReport
  ),
);
```

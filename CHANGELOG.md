# Changelog

All notable changes to this project are documented in this file.

## 0.1.0

### Changed

- Package renamed to **`flutter_health_guard`** (pub.dev name `flutter_guardian` was already taken)
- Default report folder is now `<project>/flutter_health_guard/`
- Import: `package:flutter_health_guard/flutter_health_guard.dart`
- Bridge: `dart run flutter_health_guard:guardian_bridge`
- Public API still uses `Guardian` / `GuardianOverlay` / `GuardianConfig`

### Added

- `Guardian.initialize` / `analyze` / `generateReport` / `exportReport` / `dispose` API
- `GuardianConfig` for toggling collectors and report outputs
- Collectors: crashes, logs, device, lifecycle, navigation, performance, network (IO)
- `GuardianWatch` for opt-in widget rebuild tracking
- Analyzer with category scores and rule-based recommendations
- Self-contained HTML report, `report.json` source of truth, CLI summary
- **In-app UI:** `GuardianOverlay` (draggable FAB) + `GuardianReportPage`
- One-click export (Save) with optional host bridge sync (`hostSynced` on artifacts)
- `guardian_bridge` executable — phone → `<project>/flutter_health_guard/` via HTTP + `adb`
- Example app with overlay, network, navigation, and crash demo
- Documentation under `doc/` with screenshots
- Unit tests for analyzer, HTML reporter, report writer, and facade

### Known limitations

- Memory score is heuristic; web network/file output is stubbed
- Package name conflicts with an existing pub.dev package (install via path/git for now)

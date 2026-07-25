import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import 'analyzer/analyzer.dart';
import 'analyzer/session_store.dart';
import 'collectors/collector.dart';
import 'collectors/device_collector.dart';
import 'collectors/error_collector.dart';
import 'collectors/lifecycle_collector.dart';
import 'collectors/log_collector.dart';
import 'collectors/navigation_collector.dart';
import 'collectors/network_collector.dart';
import 'collectors/performance_collector.dart';
import 'config/guardian_config.dart';
import 'io/project_path.dart';
import 'models/events.dart';
import 'models/report.dart';
import 'reporters/report_writer.dart';
import 'sync/host_sync_export.dart';

export 'config/guardian_config.dart';
export 'models/events.dart';
export 'models/report.dart';
export 'reporters/report_writer.dart';
export 'ui/guardian_overlay.dart';
export 'ui/guardian_report_page.dart';
export 'widgets/guardian_watch.dart';

/// Flutter Health Guard — collect, analyze, score, and report.
///
/// Developer usage (recommended):
///
/// ```dart
/// Future<void> main() async {
///   await Guardian.initialize();
///   runApp(const MyApp());
/// }
/// ```
///
/// That's it. While the app runs, Guardian keeps updating the report.
/// Desktop → `<project>/flutter_health_guard/report.html`
/// Mobile → app documents `/flutter_health_guard/report.html` (see console banner)
class Guardian {
  Guardian._();

  static GuardianConfig? _config;
  static SessionStore? _store;
  static final List<GuardianCollector> _collectors = [];
  static final NavigationCollector _navigation = NavigationCollector();
  static Timer? _reportTimer;
  static bool _initialized = false;
  static bool _didPrintFirstSummary = false;
  static bool _didWarnBridgeMissing = false;
  static String? _resolvedOutputDir;
  static String? _lastHtmlPath;

  /// Whether [initialize] has been called successfully.
  static bool get isInitialized => _initialized;

  /// Active config, or `null` before [initialize].
  static GuardianConfig? get config => _config;

  /// Absolute folder where reports are written (after [initialize]).
  static String? get reportDirectory => _resolvedOutputDir;

  /// Last written `report.html` path, if any.
  static String? get lastReportHtmlPath => _lastHtmlPath;

  /// Attach to `MaterialApp(navigatorObservers: [Guardian.navigatorObserver])`.
  static NavigatorObserver get navigatorObserver => _navigation;

  /// Current in-memory session store, or `null` before [initialize].
  static SessionStore? get store => _store;

  /// Boots collectors and starts auto report updates (by default).
  ///
  /// Call once before [runApp]. Safe to call twice — the second call is ignored.
  static Future<void> initialize({
    GuardianConfig config = const GuardianConfig(),
  }) async {
    if (_initialized) {
      debugPrint('[Guardian] Already initialized — skipping.');
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();

    _resolvedOutputDir = await _resolveOutputDirectory(config.outputDirectory);
    _config = config.copyWith(outputDirectory: _resolvedOutputDir);
    _store = SessionStore(
      maxNetworkEvents: config.maxNetworkEvents,
      maxLogEvents: config.maxLogEvents,
      maxNavigationEvents: config.maxNavigationEvents,
    );
    _didPrintFirstSummary = false;
    _lastHtmlPath = null;
    _collectors.clear();

    if (config.enableCrashes) {
      _collectors.add(ErrorCollector());
    }
    if (config.enableLogs) {
      _collectors.add(LogCollector());
    }
    if (config.enableDeviceInfo) {
      _collectors.add(DeviceCollector());
    }
    if (config.enableLifecycle) {
      _collectors.add(LifecycleCollector());
    }
    if (config.enablePerformance) {
      _collectors.add(PerformanceCollector());
    }
    if (config.enableNavigation) {
      _collectors.add(_navigation);
    }
    if (config.enableNetwork && !kIsWeb) {
      _collectors.add(NetworkCollector());
    }

    for (final c in _collectors) {
      c.start(_store!, _config!);
    }

    _initialized = true;
    _printPathBanner();
    _printBridgeHintIfMobile();

    if (config.autoGenerateReport) {
      _startAutoReporting();
    }
  }

  static void _startAutoReporting() {
    // First write right after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      generateReport();
    });

    _reportTimer?.cancel();
    final interval =
        _config?.reportUpdateInterval ?? const Duration(seconds: 3);
    _reportTimer = Timer.periodic(interval, (_) {
      // ignore: discarded_futures
      generateReport();
    });
  }

  static void _printPathBanner() {
    final dir = _resolvedOutputDir;
    if (dir == null) return;
    final sep = p.separator;
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════╗');
    debugPrint('║  Flutter Health Guard is running                          ║');
    debugPrint('║  Reports auto-update every few seconds while app is open ║');
    debugPrint('╠══════════════════════════════════════════════════════════╣');
    debugPrint('║  On-device / local folder:');
    debugPrint('║  $dir');
    debugPrint('║  File: $dir${sep}report.html');
    debugPrint('╚══════════════════════════════════════════════════════════╝');
    debugPrint('');
  }

  static void _printBridgeHintIfMobile() {
    final mobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!mobile || kReleaseMode) return;
    debugPrint('');
    debugPrint('[Guardian] Want the report in your PC project folder?');
    debugPrint('[Guardian] In the project root, run this in a separate terminal:');
    debugPrint('[Guardian]   dart run flutter_health_guard:guardian_bridge');
    debugPrint('[Guardian] Then keep using the app — report.html syncs to:');
    debugPrint('[Guardian]   <project>/flutter_health_guard/report.html');
    debugPrint('');
  }

  /// Records a log line in the current session (also appears in the report).
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
  }) {
    _store?.addLog(LogEvent(
      message: message,
      level: level,
      timestamp: DateTime.now(),
      tag: tag ?? 'app',
    ));
  }

  /// Records a widget rebuild. Prefer wrapping with [GuardianWatch].
  static void recordWidgetRebuild(String name, {int buildMicros = 0}) {
    _store?.recordWidgetRebuild(name, buildMicros: buildMicros);
  }

  /// Records a network event manually (e.g. Dio interceptor bridge).
  static void recordNetwork(NetworkEvent event) {
    _store?.addNetwork(event);
  }

  /// Runs the analyzer and returns a [GuardianReport] without writing files.
  static GuardianReport? analyze() {
    final store = _store;
    if (store == null) return null;
    return GuardianAnalyzer().analyze(store);
  }

  /// Analyzes the session and writes/overwrites report files on disk.
  ///
  /// Safe to call repeatedly — each call refreshes `report.html` / `report.json`.
  static Future<ReportArtifacts?> generateReport() async {
    if (!_initialized || _store == null || _config == null) {
      debugPrint('[Guardian] Not initialized — cannot generate report.');
      return null;
    }

    try {
      final report = GuardianAnalyzer().analyze(_store!);
      final writeConfig = _config!.copyWith(
        printCliSummary: _config!.printCliSummary && !_didPrintFirstSummary,
        outputDirectory: _resolvedOutputDir,
      );
      final artifacts = await ReportWriter().write(report, writeConfig);
      _lastHtmlPath = artifacts.htmlPath;
      _didPrintFirstSummary = true;
      debugPrint(
        '[Guardian] Report updated → ${artifacts.htmlPath ?? artifacts.directory}',
      );
      return artifacts;
    } catch (e, st) {
      debugPrint('[Guardian] Failed to write report: $e');
      debugPrint('$st');
      return null;
    }
  }

  /// One-shot export: writes report files and tries to sync to the PC project
  /// folder via [guardian_bridge] (debug + mobile only).
  ///
  /// Use this from the report UI — not continuous.
  static Future<ReportArtifacts?> exportReport({
    bool tryHostSync = true,
  }) async {
    final artifacts = await generateReport();
    if (artifacts == null) return null;

    var synced = false;
    if (tryHostSync) {
      synced = await _syncReportToHostProject(artifacts);
      if (synced) {
        debugPrint(
          '[Guardian] Exported to project folder via bridge → '
          'flutter_health_guard/report.html',
        );
      }
    }
    return artifacts.copyWith(hostSynced: synced);
  }

  /// Returns `true` if the host bridge accepted the upload.
  static Future<bool> _syncReportToHostProject(ReportArtifacts artifacts) async {
    final mobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!mobile || kReleaseMode || kIsWeb) return false;

    final jsonText = artifacts.jsonContent;
    final htmlText = artifacts.htmlContent;
    if (jsonText == null || htmlText == null) return false;

    try {
      final ok = await HostSync.upload(
        json: jsonText,
        html: htmlText,
        log: artifacts.logContent ?? '',
      );

      if (!ok && !_didWarnBridgeMissing) {
        _didWarnBridgeMissing = true;
        debugPrint('');
        debugPrint('[Guardian] Bridge not running — saved on device only.');
        debugPrint('[Guardian] Optional PC sync: dart run flutter_health_guard:guardian_bridge');
        debugPrint('');
      }
      return ok;
    } catch (e) {
      debugPrint('[Guardian] Host sync skipped: $e');
      return false;
    }
  }

  /// Stops collectors, cancels auto-updates, and writes a final report.
  static Future<ReportArtifacts?> dispose({bool generateReport = true}) async {
    _reportTimer?.cancel();
    _reportTimer = null;

    ReportArtifacts? artifacts;
    if (generateReport && (_config?.autoGenerateReport ?? true)) {
      artifacts = await Guardian.generateReport();
    }

    for (final c in _collectors) {
      c.stop();
    }
    _collectors.clear();
    _initialized = false;
    return artifacts;
  }

  static Future<String> _resolveOutputDirectory(String? configured) async {
    if (configured == null || configured.trim().isEmpty) {
      return resolveDefaultReportDirectory();
    }

    final value = configured.trim();
    if (p.isAbsolute(value)) return value;

    // Relative custom paths still resolve against the default base parent.
    final base = await resolveDefaultReportDirectory();
    return p.join(p.dirname(base), value);
  }
}

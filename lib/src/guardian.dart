import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
import 'models/events.dart';
import 'models/report.dart';
import 'reporters/report_writer.dart';

export 'config/guardian_config.dart';
export 'models/events.dart';
export 'models/report.dart';
export 'reporters/report_writer.dart';
export 'widgets/guardian_watch.dart';

/// Flutter Guardian — collect, analyze, score, and report.
///
/// ```dart
/// await Guardian.initialize();
/// runApp(MyApp());
/// // ...
/// await Guardian.generateReport();
/// ```
class Guardian {
  Guardian._();

  static GuardianConfig? _config;
  static SessionStore? _store;
  static final List<GuardianCollector> _collectors = [];
  static final NavigationCollector _navigation = NavigationCollector();
  static bool _initialized = false;
  static bool _reportWritten = false;

  /// Whether [initialize] has been called successfully.
  static bool get isInitialized => _initialized;

  /// Active config (null before initialize).
  static GuardianConfig? get config => _config;

  /// Attach to `MaterialApp(navigatorObservers: [Guardian.navigatorObserver])`.
  static NavigatorObserver get navigatorObserver => _navigation;

  /// Current in-memory session (null before initialize).
  static SessionStore? get store => _store;

  /// Boot collectors. Call once before [runApp].
  static Future<void> initialize({
    GuardianConfig config = const GuardianConfig(),
  }) async {
    if (_initialized) {
      debugPrint('[Guardian] Already initialized — skipping.');
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();

    _config = config;
    _store = SessionStore(
      maxNetworkEvents: config.maxNetworkEvents,
      maxLogEvents: config.maxLogEvents,
      maxNavigationEvents: config.maxNavigationEvents,
    );
    _reportWritten = false;
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
      c.start(_store!, config);
    }

    _initialized = true;
    debugPrint(
      '[Guardian] Session ${_store!.sessionId} started → ${config.outputDirectory}',
    );
  }

  /// Manually log through Guardian.
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

  /// Record a widget rebuild (used by [GuardianWatch]).
  static void recordWidgetRebuild(String name, {int buildMicros = 0}) {
    _store?.recordWidgetRebuild(name, buildMicros: buildMicros);
  }

  /// Manually record a network event (e.g. Dio interceptor bridge).
  static void recordNetwork(NetworkEvent event) {
    _store?.addNetwork(event);
  }

  /// Analyze the current session without writing files.
  static GuardianReport? analyze() {
    final store = _store;
    if (store == null) return null;
    return GuardianAnalyzer().analyze(store);
  }

  /// Analyze + write JSON/HTML + print CLI summary.
  static Future<ReportArtifacts?> generateReport({bool force = false}) async {
    if (!_initialized || _store == null || _config == null) {
      debugPrint('[Guardian] Not initialized — cannot generate report.');
      return null;
    }
    if (_reportWritten && !force) {
      debugPrint('[Guardian] Report already written this session.');
      return null;
    }

    final report = GuardianAnalyzer().analyze(_store!);
    final artifacts = await ReportWriter().write(report, _config!);
    _reportWritten = true;
    return artifacts;
  }

  /// Stop collectors and optionally write the final report.
  static Future<ReportArtifacts?> dispose({bool generateReport = true}) async {
    ReportArtifacts? artifacts;
    final shouldWrite =
        generateReport && (_config?.autoGenerateReport ?? false);
    if (shouldWrite) {
      artifacts = await Guardian.generateReport();
    }

    for (final c in _collectors) {
      c.stop();
    }
    _collectors.clear();
    _initialized = false;
    return artifacts;
  }
}

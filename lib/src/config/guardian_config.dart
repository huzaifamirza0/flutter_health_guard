/// Configuration for [Guardian.initialize].
///
/// Default DX for app developers:
/// ```dart
/// await Guardian.initialize(); // that's it
/// runApp(MyApp());
/// ```
/// Reports are written automatically and keep updating while the app runs.
class GuardianConfig {
  /// Creates a Guardian configuration.
  const GuardianConfig({
    this.enableLogs = true,
    this.enableNetwork = true,
    this.enablePerformance = true,
    this.enableNavigation = true,
    this.enableCrashes = true,
    this.enableLifecycle = true,
    this.enableDeviceInfo = true,
    this.autoGenerateReport = true,
    this.generateHtml = true,
    this.generateJson = true,
    this.printCliSummary = true,
    this.outputDirectory,
    this.reportUpdateInterval = const Duration(seconds: 3),
    this.maxNetworkEvents = 500,
    this.maxLogEvents = 1000,
    this.maxNavigationEvents = 200,
    this.slowFrameThresholdMs = 16.7,
    this.jankFrameThresholdMs = 33.0,
  });

  /// Capture `debugPrint` and [Guardian.log] calls.
  final bool enableLogs;

  /// Intercept HTTP via `HttpOverrides` on IO platforms (no-op on web).
  final bool enableNetwork;

  /// Track frame timings, FPS estimate, and jank.
  final bool enablePerformance;

  /// Track route pushes/pops via [Guardian.navigatorObserver].
  final bool enableNavigation;

  /// Capture Flutter errors and uncaught async errors.
  final bool enableCrashes;

  /// Track app lifecycle (resumed, paused, etc.).
  final bool enableLifecycle;

  /// Collect device / platform metadata.
  final bool enableDeviceInfo;

  /// When `true` (default), Guardian writes a report after the first frame and
  /// keeps overwriting it on [reportUpdateInterval] while the app runs.
  final bool autoGenerateReport;

  /// Emit a self-contained HTML dashboard (`report.html`).
  final bool generateHtml;

  /// Emit `report.json` (source of truth for all renderers).
  final bool generateJson;

  /// Print a CLI-style summary the first time a report is written.
  final bool printCliSummary;

  /// Optional output folder.
  ///
  /// - `null` (default):
  ///   - desktop → `<project>/flutter_health_guard/`
  ///   - Android/iOS → app documents `/flutter_health_guard/`
  ///     (devices cannot write into your PC project folder)
  /// - absolute path: used as-is
  /// - relative path: resolved next to the default base directory
  final String? outputDirectory;

  /// How often to refresh the on-disk report while the app is running.
  final Duration reportUpdateInterval;

  /// Ring-buffer cap for captured HTTP events.
  final int maxNetworkEvents;

  /// Ring-buffer cap for log events.
  final int maxLogEvents;

  /// Ring-buffer cap for navigation events.
  final int maxNavigationEvents;

  /// Frames slower than this (ms) count as slow (~1 frame at 60fps).
  final double slowFrameThresholdMs;

  /// Frames slower than this (ms) count as jank (~2 frames at 60fps).
  final double jankFrameThresholdMs;

  /// Returns a copy with the given fields replaced.
  GuardianConfig copyWith({
    bool? enableLogs,
    bool? enableNetwork,
    bool? enablePerformance,
    bool? enableNavigation,
    bool? enableCrashes,
    bool? enableLifecycle,
    bool? enableDeviceInfo,
    bool? autoGenerateReport,
    bool? generateHtml,
    bool? generateJson,
    bool? printCliSummary,
    String? outputDirectory,
    Duration? reportUpdateInterval,
    int? maxNetworkEvents,
    int? maxLogEvents,
    int? maxNavigationEvents,
    double? slowFrameThresholdMs,
    double? jankFrameThresholdMs,
  }) {
    return GuardianConfig(
      enableLogs: enableLogs ?? this.enableLogs,
      enableNetwork: enableNetwork ?? this.enableNetwork,
      enablePerformance: enablePerformance ?? this.enablePerformance,
      enableNavigation: enableNavigation ?? this.enableNavigation,
      enableCrashes: enableCrashes ?? this.enableCrashes,
      enableLifecycle: enableLifecycle ?? this.enableLifecycle,
      enableDeviceInfo: enableDeviceInfo ?? this.enableDeviceInfo,
      autoGenerateReport: autoGenerateReport ?? this.autoGenerateReport,
      generateHtml: generateHtml ?? this.generateHtml,
      generateJson: generateJson ?? this.generateJson,
      printCliSummary: printCliSummary ?? this.printCliSummary,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      reportUpdateInterval: reportUpdateInterval ?? this.reportUpdateInterval,
      maxNetworkEvents: maxNetworkEvents ?? this.maxNetworkEvents,
      maxLogEvents: maxLogEvents ?? this.maxLogEvents,
      maxNavigationEvents: maxNavigationEvents ?? this.maxNavigationEvents,
      slowFrameThresholdMs:
          slowFrameThresholdMs ?? this.slowFrameThresholdMs,
      jankFrameThresholdMs:
          jankFrameThresholdMs ?? this.jankFrameThresholdMs,
    );
  }
}

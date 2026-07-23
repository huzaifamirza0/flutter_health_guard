/// Configuration for [Guardian.initialize].
class GuardianConfig {
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
    this.outputDirectory = '.flutter_guardian',
    this.maxNetworkEvents = 500,
    this.maxLogEvents = 1000,
    this.maxNavigationEvents = 200,
    this.slowFrameThresholdMs = 16.7,
    this.jankFrameThresholdMs = 33.0,
  });

  /// Capture [print]/debugPrint and custom log calls.
  final bool enableLogs;

  /// Intercept HTTP via [HttpOverrides].
  final bool enableNetwork;

  /// Track frame timings, FPS, and jank.
  final bool enablePerformance;

  /// Track route pushes/pops via [NavigatorObserver].
  final bool enableNavigation;

  /// Capture Flutter errors and uncaught async errors.
  final bool enableCrashes;

  /// Track app lifecycle (resumed, paused, etc.).
  final bool enableLifecycle;

  /// Collect device / platform / app metadata.
  final bool enableDeviceInfo;

  /// Write report files when [Guardian.dispose] / app detach happens.
  final bool autoGenerateReport;

  /// Emit a self-contained HTML dashboard.
  final bool generateHtml;

  /// Emit `report.json` (source of truth).
  final bool generateJson;

  /// Print a CLI-style summary to the console.
  final bool printCliSummary;

  /// Directory for report artifacts (relative or absolute).
  final String outputDirectory;

  final int maxNetworkEvents;
  final int maxLogEvents;
  final int maxNavigationEvents;

  /// Frames slower than this (ms) count as slow.
  final double slowFrameThresholdMs;

  /// Frames slower than this (ms) count as jank.
  final double jankFrameThresholdMs;

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

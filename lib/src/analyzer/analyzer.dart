import '../models/events.dart';
import '../models/report.dart';
import 'session_store.dart';

/// Turns raw collected data into scores + recommendations.
///
/// Scores are computed here — never inside HTML/CLI renderers.
class GuardianAnalyzer {
  GuardianReport analyze(SessionStore store) {
    final now = DateTime.now();
    final widgets = store.widgetStats.values.toList()
      ..sort((a, b) => b.rebuilds.compareTo(a.rebuilds));

    final recommendations = _buildRecommendations(store, widgets);
    final scores = _computeScores(store, widgets, recommendations);

    return GuardianReport(
      sessionId: store.sessionId,
      generatedAt: now,
      startedAt: store.startedAt,
      endedAt: now,
      scores: scores,
      recommendations: recommendations,
      crashes: List.unmodifiable(store.crashes),
      network: List.unmodifiable(store.network),
      navigation: List.unmodifiable(store.navigation),
      lifecycle: List.unmodifiable(store.lifecycle),
      logs: List.unmodifiable(store.logs),
      frameStats: store.frameStats,
      widgets: widgets,
      device: store.device,
      startupTimeMs: store.startupTimeMs,
      meta: {
        'package': 'flutter_guardian',
        'schemaVersion': '0.1.0',
      },
    );
  }

  GuardianScores _computeScores(
    SessionStore store,
    List<WidgetRebuildStat> widgets,
    List<Recommendation> recommendations,
  ) {
    final performance = _performanceScore(store);
    final memory = _memoryScore(store, widgets);
    final network = _networkScore(store);
    final stability = _stabilityScore(store);
    final ui = _uiScore(store, widgets);
    final architecture = _architectureScore(widgets, recommendations);
    final security = _securityScore(store);

    final overall = _weightedOverall(
      performance: performance,
      memory: memory,
      network: network,
      stability: stability,
      ui: ui,
      architecture: architecture,
      security: security,
    );

    return GuardianScores(
      overall: overall,
      performance: performance,
      memory: memory,
      network: network,
      stability: stability,
      ui: ui,
      architecture: architecture,
      security: security,
    );
  }

  int _weightedOverall({
    required int performance,
    required int memory,
    required int network,
    required int stability,
    required int ui,
    required int architecture,
    required int security,
  }) {
    // Stability & performance weigh more — crashes hurt most.
    final raw = performance * 0.22 +
        memory * 0.12 +
        network * 0.15 +
        stability * 0.25 +
        ui * 0.12 +
        architecture * 0.08 +
        security * 0.06;
    return raw.round().clamp(0, 100);
  }

  int _performanceScore(SessionStore store) {
    var score = 100.0;
    final fps = store.frameStats.averageFps;
    if (store.frameStats.totalFrames > 0) {
      if (fps < 60) score -= (60 - fps) * 1.2;
      score -= store.frameStats.jankRate * 40;
      if (store.frameStats.maxFrameMs > 50) score -= 10;
      if (store.frameStats.maxFrameMs > 100) score -= 10;
    }
    final startup = store.startupTimeMs;
    if (startup != null) {
      if (startup > 1500) score -= 5;
      if (startup > 2500) score -= 10;
      if (startup > 4000) score -= 15;
    }
    return score.round().clamp(0, 100);
  }

  int _memoryScore(SessionStore store, List<WidgetRebuildStat> widgets) {
    var score = 100.0;
    // Proxy: extreme rebuilds often correlate with memory pressure.
    for (final w in widgets.take(5)) {
      if (w.rebuilds > 100) score -= 5;
      if (w.rebuilds > 250) score -= 10;
    }
    return score.round().clamp(0, 100);
  }

  int _networkScore(SessionStore store) {
    if (store.network.isEmpty) return 100;
    var score = 100.0;
    final total = store.network.length;
    final failed = store.network.where((e) => !e.isSuccess).length;
    score -= (failed / total) * 50;

    final durations =
        store.network.map((e) => e.durationMs).whereType<int>().toList();
    if (durations.isNotEmpty) {
      final avg = durations.reduce((a, b) => a + b) / durations.length;
      if (avg > 500) score -= 5;
      if (avg > 1500) score -= 10;
      if (avg > 3000) score -= 15;
    }

    // Duplicate URL penalty
    final urls = <String, int>{};
    for (final e in store.network) {
      final key = '${e.method} ${e.url}';
      urls[key] = (urls[key] ?? 0) + 1;
    }
    final dupes = urls.values.where((c) => c >= 3).length;
    score -= dupes * 5;

    return score.round().clamp(0, 100);
  }

  int _stabilityScore(SessionStore store) {
    var score = 100.0;
    score -= store.crashes.length * 25;
    final errors =
        store.logs.where((l) => l.level == LogLevel.error).length;
    score -= (errors * 2).clamp(0, 20);
    return score.round().clamp(0, 100);
  }

  int _uiScore(SessionStore store, List<WidgetRebuildStat> widgets) {
    var score = 100.0;
    if (store.frameStats.totalFrames > 0) {
      score -= store.frameStats.jankRate * 30;
    }
    for (final w in widgets.take(3)) {
      if (w.rebuilds > 50) score -= 4;
      if (w.rebuilds > 150) score -= 8;
      if (w.averageBuildMs > 8) score -= 5;
    }
    return score.round().clamp(0, 100);
  }

  int _architectureScore(
    List<WidgetRebuildStat> widgets,
    List<Recommendation> recommendations,
  ) {
    var score = 100.0;
    final critical = recommendations
        .where((r) => r.severity == RecommendationSeverity.critical)
        .length;
    final warnings = recommendations
        .where((r) => r.severity == RecommendationSeverity.warning)
        .length;
    score -= critical * 12;
    score -= warnings * 4;
    if (widgets.any((w) => w.rebuilds > 200)) score -= 10;
    return score.round().clamp(0, 100);
  }

  int _securityScore(SessionStore store) {
    var score = 100.0;
    for (final e in store.network) {
      final uri = Uri.tryParse(e.url);
      if (uri != null && uri.scheme == 'http') {
        score -= 8;
      }
    }
    return score.round().clamp(0, 100);
  }

  List<Recommendation> _buildRecommendations(
    SessionStore store,
    List<WidgetRebuildStat> widgets,
  ) {
    final out = <Recommendation>[];

    for (final w in widgets) {
      if (w.rebuilds >= 100) {
        final estimated = ((w.rebuilds / 50) * 2).clamp(3, 20).round();
        out.add(Recommendation(
          id: 'widget-rebuild-${w.widgetName}',
          title: '${w.widgetName} rebuilt ${w.rebuilds} times',
          message:
              'High rebuild counts often cause dropped frames and wasted CPU.',
          severity: w.rebuilds >= 250
              ? RecommendationSeverity.critical
              : RecommendationSeverity.warning,
          category: 'ui',
          estimatedImprovement: '+$estimated% FPS',
          fixes: const [
            'Use const constructors where possible',
            'Extract widgets and wrap with RepaintBoundary',
            'Prefer Selector / Riverpod select / BlocSelector',
            'Avoid setState on large ancestor widgets',
          ],
        ));
      }
    }

    if (store.frameStats.jankFrames > 10) {
      out.add(Recommendation(
        id: 'jank-frames',
        title: '${store.frameStats.jankFrames} jank frames detected',
        message:
            'Frames exceeding ~33ms cause visible stutter. Average FPS: '
            '${store.frameStats.averageFps.toStringAsFixed(1)}.',
        severity: store.frameStats.jankFrames > 50
            ? RecommendationSeverity.critical
            : RecommendationSeverity.warning,
        category: 'performance',
        estimatedImprovement: '+8–15 FPS',
        fixes: const [
          'Profile with Flutter DevTools Performance tab',
          'Defer heavy work off the UI isolate',
          'Cache images and avoid decoding on the UI thread',
        ],
      ));
    }

    final startup = store.startupTimeMs;
    if (startup != null && startup > 2000) {
      out.add(Recommendation(
        id: 'slow-startup',
        title: 'Startup took ${startup}ms',
        message: 'Cold start above 2s hurts first impression and retention.',
        severity: startup > 4000
            ? RecommendationSeverity.critical
            : RecommendationSeverity.warning,
        category: 'performance',
        estimatedImprovement: '−${(startup * 0.3).round()}ms startup',
        fixes: const [
          'Lazy-initialize heavy SDKs (Firebase, analytics)',
          'Defer non-critical network calls until after first frame',
          'Reduce work in main() before runApp',
        ],
      ));
    }

    final urlCounts = <String, int>{};
    for (final e in store.network) {
      final key = '${e.method} ${e.url}';
      urlCounts[key] = (urlCounts[key] ?? 0) + 1;
    }
    for (final entry in urlCounts.entries) {
      if (entry.value >= 3) {
        out.add(Recommendation(
          id: 'dup-network-${entry.key.hashCode}',
          title: '${entry.value} duplicate requests: ${entry.key}',
          message:
              'Repeated identical requests waste bandwidth and battery.',
          severity: RecommendationSeverity.warning,
          category: 'network',
          estimatedImprovement: 'Fewer redundant calls',
          fixes: const [
            'Cache responses (Guardian Cache / Dio cache interceptor)',
            'Deduplicate in-flight requests',
            'Lift data fetching to a shared provider',
          ],
        ));
      }
    }

    for (final e in store.network) {
      final uri = Uri.tryParse(e.url);
      if (uri != null && uri.scheme == 'http') {
        out.add(Recommendation(
          id: 'insecure-http-${uri.host}',
          title: 'Insecure HTTP request to ${uri.host}',
          message: 'Cleartext traffic can be intercepted on public networks.',
          severity: RecommendationSeverity.warning,
          category: 'security',
          fixes: const [
            'Switch to HTTPS',
            'Enable network security config / ATS equivalents',
          ],
        ));
        break;
      }
    }

    for (final crash in store.crashes) {
      out.add(Recommendation(
        id: 'crash-${crash.timestamp.millisecondsSinceEpoch}',
        title: 'Crash: ${crash.type}',
        message: crash.message,
        severity: RecommendationSeverity.critical,
        category: 'stability',
        fixes: const [
          'Inspect the stack trace in the Crashes section',
          'Add null-safety / error boundaries around the failing path',
          'Reproduce with Flutter DevTools logging enabled',
        ],
      ));
    }

    if (store.crashes.isEmpty &&
        store.frameStats.jankFrames == 0 &&
        widgets.every((w) => w.rebuilds < 50)) {
      out.add(Recommendation(
        id: 'healthy-session',
        title: 'No major issues detected',
        message:
            'This session looks healthy. Keep monitoring across longer QA runs.',
        severity: RecommendationSeverity.info,
        category: 'general',
      ));
    }

    out.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return out;
  }
}

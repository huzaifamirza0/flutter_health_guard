import 'events.dart';

enum RecommendationSeverity { info, warning, critical }

class Recommendation {
  Recommendation({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.category = 'general',
    this.estimatedImprovement,
    this.fixes = const [],
  });

  final String id;
  final String title;
  final String message;
  final RecommendationSeverity severity;
  final String category;
  final String? estimatedImprovement;
  final List<String> fixes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'severity': severity.name,
        'category': category,
        if (estimatedImprovement != null)
          'estimatedImprovement': estimatedImprovement,
        'fixes': fixes,
      };
}

class CategoryScore {
  CategoryScore({
    required this.name,
    required this.score,
    this.details = const {},
  });

  final String name;
  final int score;
  final Map<String, dynamic> details;

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'details': details,
      };
}

class GuardianScores {
  GuardianScores({
    required this.overall,
    required this.performance,
    required this.memory,
    required this.network,
    required this.stability,
    required this.ui,
    this.architecture = 100,
    this.security = 100,
  });

  final int overall;
  final int performance;
  final int memory;
  final int network;
  final int stability;
  final int ui;
  final int architecture;
  final int security;

  List<CategoryScore> get categories => [
        CategoryScore(name: 'Performance', score: performance),
        CategoryScore(name: 'Memory', score: memory),
        CategoryScore(name: 'Network', score: network),
        CategoryScore(name: 'Stability', score: stability),
        CategoryScore(name: 'UI', score: ui),
        CategoryScore(name: 'Architecture', score: architecture),
        CategoryScore(name: 'Security', score: security),
      ];

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'performance': performance,
        'memory': memory,
        'network': network,
        'stability': stability,
        'ui': ui,
        'architecture': architecture,
        'security': security,
        'categories': categories.map((c) => c.toJson()).toList(),
      };
}

/// Source-of-truth report model. HTML / CLI / future dashboard all render this.
class GuardianReport {
  GuardianReport({
    required this.sessionId,
    required this.generatedAt,
    required this.startedAt,
    required this.endedAt,
    required this.scores,
    required this.recommendations,
    required this.crashes,
    required this.network,
    required this.navigation,
    required this.lifecycle,
    required this.logs,
    required this.frameStats,
    required this.widgets,
    this.device,
    this.startupTimeMs,
    this.meta = const {},
  });

  final String sessionId;
  final DateTime generatedAt;
  final DateTime startedAt;
  final DateTime endedAt;
  final GuardianScores scores;
  final List<Recommendation> recommendations;
  final List<CrashEvent> crashes;
  final List<NetworkEvent> network;
  final List<NavigationEvent> navigation;
  final List<LifecycleEvent> lifecycle;
  final List<LogEvent> logs;
  final FrameStats frameStats;
  final List<WidgetRebuildStat> widgets;
  final DeviceInfo? device;
  final int? startupTimeMs;
  final Map<String, dynamic> meta;

  Duration get sessionDuration => endedAt.difference(startedAt);

  Map<String, dynamic> toJson() => {
        'version': '0.1.0',
        'sessionId': sessionId,
        'generatedAt': generatedAt.toIso8601String(),
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'sessionDurationMs': sessionDuration.inMilliseconds,
        if (startupTimeMs != null) 'startupTimeMs': startupTimeMs,
        'scores': scores.toJson(),
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'summary': {
          'crashCount': crashes.length,
          'networkRequestCount': network.length,
          'networkSuccessRate': _networkSuccessRate,
          'navigationCount': navigation.length,
          'logCount': logs.length,
          'averageFps': frameStats.averageFps,
          'jankFrames': frameStats.jankFrames,
          'topRebuiltWidget': widgets.isEmpty ? null : widgets.first.widgetName,
        },
        'device': device?.toJson(),
        'performance': frameStats.toJson(),
        'crashes': crashes.map((e) => e.toJson()).toList(),
        'network': network.map((e) => e.toJson()).toList(),
        'navigation': navigation.map((e) => e.toJson()).toList(),
        'lifecycle': lifecycle.map((e) => e.toJson()).toList(),
        'widgets': widgets.map((e) => e.toJson()).toList(),
        'logs': logs.map((e) => e.toJson()).toList(),
        'meta': meta,
      };

  double get _networkSuccessRate {
    if (network.isEmpty) return 1.0;
    final ok = network.where((e) => e.isSuccess).length;
    return ok / network.length;
  }
}

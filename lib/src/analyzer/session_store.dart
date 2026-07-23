import 'dart:math';

import '../models/events.dart';

/// In-memory ring-buffer store for one Guardian session.
class SessionStore {
  SessionStore({
    required this.maxNetworkEvents,
    required this.maxLogEvents,
    required this.maxNavigationEvents,
  })  : sessionId = _generateSessionId(),
        startedAt = DateTime.now();

  final String sessionId;
  final DateTime startedAt;
  final int maxNetworkEvents;
  final int maxLogEvents;
  final int maxNavigationEvents;

  final List<LogEvent> logs = [];
  final List<CrashEvent> crashes = [];
  final List<NetworkEvent> network = [];
  final List<NavigationEvent> navigation = [];
  final List<LifecycleEvent> lifecycle = [];
  final Map<String, WidgetRebuildStat> widgetStats = {};
  final FrameStats frameStats = FrameStats();

  DeviceInfo? device;
  int? startupTimeMs;
  DateTime? firstFrameAt;

  void addLog(LogEvent event) {
    logs.add(event);
    _trim(logs, maxLogEvents);
  }

  void addCrash(CrashEvent event) => crashes.add(event);

  void addNetwork(NetworkEvent event) {
    network.add(event);
    _trim(network, maxNetworkEvents);
  }

  void addNavigation(NavigationEvent event) {
    navigation.add(event);
    _trim(navigation, maxNavigationEvents);
  }

  void addLifecycle(LifecycleEvent event) => lifecycle.add(event);

  void recordWidgetRebuild(String widgetName, {int buildMicros = 0}) {
    final existing = widgetStats.putIfAbsent(
      widgetName,
      () => WidgetRebuildStat(widgetName: widgetName),
    );
    existing.rebuilds++;
    existing.totalBuildMicros += buildMicros;
    if (buildMicros > existing.maxBuildMicros) {
      existing.maxBuildMicros = buildMicros;
    }
  }

  void markFirstFrame() {
    firstFrameAt ??= DateTime.now();
    startupTimeMs ??=
        firstFrameAt!.difference(startedAt).inMilliseconds;
  }

  static void _trim<T>(List<T> list, int max) {
    if (list.length > max) {
      list.removeRange(0, list.length - max);
    }
  }

  static String _generateSessionId() {
    final r = Random();
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final suffix = List.generate(4, (_) => r.nextInt(36).toRadixString(36))
        .join();
    return 'g_$ts$suffix';
  }
}

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../analyzer/session_store.dart';
import '../config/guardian_config.dart';
import 'collector.dart';

class PerformanceCollector implements GuardianCollector {
  SessionStore? _store;
  GuardianConfig? _config;
  bool _listening = false;

  @override
  void start(SessionStore store, GuardianConfig config) {
    _store = store;
    _config = config;
    _listening = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);

    // First-frame / startup timing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      store.markFirstFrame();
    });
  }

  @override
  void stop() {
    if (_listening) {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
      _listening = false;
    }
    _store = null;
    _config = null;
  }

  void _onTimings(List<FrameTiming> timings) {
    final store = _store;
    final config = _config;
    if (store == null || config == null) return;

    for (final t in timings) {
      final buildMicros = t.buildDuration.inMicroseconds;
      final rasterMicros = t.rasterDuration.inMicroseconds;
      final totalMs = (buildMicros + rasterMicros) / 1000.0;

      store.frameStats.totalFrames++;
      store.frameStats.totalBuildMicros += buildMicros;
      store.frameStats.totalRasterMicros += rasterMicros;
      if (totalMs > store.frameStats.maxFrameMs) {
        store.frameStats.maxFrameMs = totalMs;
      }
      if (totalMs > config.slowFrameThresholdMs) {
        store.frameStats.slowFrames++;
      }
      if (totalMs > config.jankFrameThresholdMs) {
        store.frameStats.jankFrames++;
      }
    }
  }
}

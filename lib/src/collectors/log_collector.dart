import 'package:flutter/foundation.dart';

import '../analyzer/session_store.dart';
import '../config/guardian_config.dart';
import '../models/events.dart';
import 'collector.dart';

class LogCollector implements GuardianCollector {
  DebugPrintCallback? _previous;

  @override
  void start(SessionStore store, GuardianConfig config) {
    _previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && message.isNotEmpty) {
        store.addLog(LogEvent(
          message: message,
          level: _inferLevel(message),
          timestamp: DateTime.now(),
          tag: 'debugPrint',
        ));
      }
      _previous?.call(message, wrapWidth: wrapWidth);
    };
  }

  @override
  void stop() {
    if (_previous != null) {
      debugPrint = _previous!;
    }
  }

  static LogLevel _inferLevel(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('error') || lower.contains('exception')) {
      return LogLevel.error;
    }
    if (lower.contains('warn')) return LogLevel.warning;
    return LogLevel.info;
  }
}

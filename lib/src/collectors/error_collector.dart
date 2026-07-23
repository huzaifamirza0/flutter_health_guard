import 'dart:ui' show ErrorCallback, PlatformDispatcher;

import 'package:flutter/foundation.dart';

import '../analyzer/session_store.dart';
import '../config/guardian_config.dart';
import '../models/events.dart';
import 'collector.dart';

class ErrorCollector implements GuardianCollector {
  FlutterExceptionHandler? _previousFlutterOnError;
  ErrorCallback? _previousPlatformOnError;

  @override
  void start(SessionStore store, GuardianConfig config) {
    _previousFlutterOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      store.addCrash(CrashEvent(
        type: details.exception.runtimeType.toString(),
        message: details.exceptionAsString(),
        timestamp: DateTime.now(),
        stackTrace: details.stack?.toString(),
        library: details.library,
        context: details.context?.toString(),
      ));
      store.addLog(LogEvent(
        message: details.exceptionAsString(),
        level: LogLevel.error,
        timestamp: DateTime.now(),
        tag: 'FlutterError',
      ));
      _previousFlutterOnError?.call(details);
    };

    _previousPlatformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      store.addCrash(CrashEvent(
        type: error.runtimeType.toString(),
        message: error.toString(),
        timestamp: DateTime.now(),
        stackTrace: stack.toString(),
        context: 'PlatformDispatcher',
      ));
      store.addLog(LogEvent(
        message: error.toString(),
        level: LogLevel.error,
        timestamp: DateTime.now(),
        tag: 'Uncaught',
      ));
      return _previousPlatformOnError?.call(error, stack) ?? true;
    };
  }

  @override
  void stop() {
    if (_previousFlutterOnError != null) {
      FlutterError.onError = _previousFlutterOnError;
    }
    PlatformDispatcher.instance.onError = _previousPlatformOnError;
  }
}

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../analyzer/session_store.dart';
import '../config/guardian_config.dart';
import '../models/events.dart';
import 'collector.dart';

class DeviceCollector implements GuardianCollector {
  @override
  void start(SessionStore store, GuardianConfig config) {
    store.device = DeviceInfo(
      platform: _platformName(),
      osVersion: Platform.operatingSystemVersion,
      locale: PlatformDispatcher.instance.locale.toLanguageTag(),
      numberOfProcessors: Platform.numberOfProcessors,
      isPhysicalDevice: !_isSimulatorHeuristic(),
    );
  }

  @override
  void stop() {}

  static String _platformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isFuchsia) return 'fuchsia';
    return defaultTargetPlatform.name;
  }

  static bool _isSimulatorHeuristic() {
    final os = Platform.operatingSystemVersion.toLowerCase();
    return os.contains('simulator') || os.contains('emulator');
  }
}

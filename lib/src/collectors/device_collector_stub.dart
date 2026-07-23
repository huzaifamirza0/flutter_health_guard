import 'package:flutter/foundation.dart';

import '../analyzer/session_store.dart';
import '../config/guardian_config.dart';
import '../models/events.dart';
import 'collector.dart';

class DeviceCollector implements GuardianCollector {
  @override
  void start(SessionStore store, GuardianConfig config) {
    store.device = DeviceInfo(
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      osVersion: kIsWeb ? 'web' : defaultTargetPlatform.name,
      locale: PlatformDispatcher.instance.locale.toLanguageTag(),
      isPhysicalDevice: !kIsWeb,
    );
  }

  @override
  void stop() {}
}

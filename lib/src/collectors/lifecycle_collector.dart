import 'package:flutter/widgets.dart';

import '../analyzer/session_store.dart';
import '../config/guardian_config.dart';
import '../models/events.dart';
import 'collector.dart';

class LifecycleCollector with WidgetsBindingObserver implements GuardianCollector {
  SessionStore? _store;

  @override
  void start(SessionStore store, GuardianConfig config) {
    _store = store;
    WidgetsBinding.instance.addObserver(this);
    store.addLifecycle(LifecycleEvent(
      state: 'resumed',
      timestamp: DateTime.now(),
    ));
  }

  @override
  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _store = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _store?.addLifecycle(LifecycleEvent(
      state: state.name,
      timestamp: DateTime.now(),
    ));
  }
}

import 'package:flutter/widgets.dart';

import '../analyzer/session_store.dart';
import '../config/guardian_config.dart';
import '../models/events.dart';
import 'collector.dart';

/// Attach via `MaterialApp(navigatorObservers: [Guardian.navigatorObserver])`.
class NavigationCollector extends NavigatorObserver implements GuardianCollector {
  SessionStore? _store;

  @override
  void start(SessionStore store, GuardianConfig config) {
    _store = store;
  }

  @override
  void stop() {
    _store = null;
  }

  void _record(String action, Route<dynamic>? route, Route<dynamic>? previous) {
    final store = _store;
    if (store == null || route == null) return;
    store.addNavigation(NavigationEvent(
      action: action,
      routeName: _nameOf(route),
      previousRouteName: previous == null ? null : _nameOf(previous),
      timestamp: DateTime.now(),
      arguments: route.settings.arguments?.toString(),
    ));
  }

  static String _nameOf(Route<dynamic> route) =>
      route.settings.name ?? route.runtimeType.toString();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('push', route, previousRoute);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('pop', route, previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _record('replace', newRoute, oldRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('remove', route, previousRoute);
    super.didRemove(route, previousRoute);
  }
}

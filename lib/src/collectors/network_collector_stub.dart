import '../analyzer/session_store.dart';
import '../config/guardian_config.dart';
import 'collector.dart';

/// No-op network collector used on web / unsupported platforms.
class NetworkCollector implements GuardianCollector {
  @override
  void start(SessionStore store, GuardianConfig config) {}

  @override
  void stop() {}
}

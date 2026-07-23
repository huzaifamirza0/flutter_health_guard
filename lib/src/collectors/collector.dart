import '../analyzer/session_store.dart';
import '../config/guardian_config.dart';

abstract class GuardianCollector {
  void start(SessionStore store, GuardianConfig config);
  void stop();
}

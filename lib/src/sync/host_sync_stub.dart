/// Web stub — host sync is unavailable.
class HostSync {
  HostSync._();

  static const int defaultPort = 7421;

  static Future<bool> upload({
    required String json,
    required String html,
    required String log,
    int port = defaultPort,
  }) async =>
      false;
}

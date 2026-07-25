import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Pushes a report to the PC project folder via [guardian_bridge].
///
/// Tries several host addresses:
/// - `127.0.0.1` — desktop, or phone with `adb reverse`
/// - `10.0.2.2` — Android emulator → host loopback (no reverse needed)
class HostSync {
  HostSync._();

  static const int defaultPort = 7421;

  /// Best-effort upload. Never throws to callers.
  static Future<bool> upload({
    required String json,
    required String html,
    required String log,
    int port = defaultPort,
  }) async {
    if (kIsWeb || kReleaseMode) return false;

    final hosts = <String>{
      '127.0.0.1',
      if (defaultTargetPlatform == TargetPlatform.android) '10.0.2.2',
    };

    final payload = utf8.encode(jsonEncode({
      'json': json,
      'html': html,
      'log': log,
    }));

    for (final host in hosts) {
      final ok = await _postOnce(
        Uri.parse('http://$host:$port/report'),
        payload,
      );
      if (ok) {
        debugPrint(
          '[Guardian] Synced report to PC via bridge ($host:$port)',
        );
        return true;
      }
    }
    return false;
  }

  static Future<bool> _postOnce(Uri uri, List<int> payload) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.add(payload);
      final response =
          await request.close().timeout(const Duration(seconds: 3));
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      await response.drain<void>();
      return ok;
    } catch (_) {
      return false;
    } finally {
      client?.close(force: true);
    }
  }
}

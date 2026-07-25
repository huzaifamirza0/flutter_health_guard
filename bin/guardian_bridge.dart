import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Host-side bridge: phone → your PC project folder.
///
/// Run from your Flutter app project root (keep this window open):
/// ```bash
/// dart run flutter_health_guard:guardian_bridge --package com.example.package_testing
/// ```
///
/// Then in the app: open Guardian report → tap the **Save** icon (Export).
///
/// Reports land in: `<project>/flutter_health_guard/report.html`
///
/// Two sync methods:
/// 1) HTTP push from the app (`adb reverse` or emulator `10.0.2.2`)
/// 2) Periodic `adb` pull from the device (when `--package` is set)
Future<void> main(List<String> args) async {
  final port = _readIntArg(args, '--port') ?? 7421;
  final packageName = _readStringArg(args, '--package');
  final outDir = Directory(
    p.join(Directory.current.path, 'flutter_health_guard'),
  );
  outDir.createSync(recursive: true);

  final adb = _findAdb();
  final reverseOk = await _tryAdbReverse(port, adb);

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);

  stdout.writeln('');
  stdout.writeln('╔══════════════════════════════════════════════════════════╗');
  stdout.writeln('║  Flutter Health Guard Bridge                                 ║');
  stdout.writeln('╠══════════════════════════════════════════════════════════╣');
  stdout.writeln('║  Listening: http://127.0.0.1:$port');
  stdout.writeln('║  Writing to:');
  stdout.writeln('║  ${outDir.path}');
  if (adb != null) {
    stdout.writeln('║  adb: $adb');
    stdout.writeln(
      reverseOk
          ? '║  adb reverse: OK (phone can reach this bridge)'
          : '║  adb reverse: FAILED (plug device / start emulator)',
    );
  } else {
    stdout.writeln('║  adb: NOT FOUND');
    stdout.writeln('║  Emulator can still sync via 10.0.2.2');
    stdout.writeln('║  Physical phone needs platform-tools on PATH');
  }
  if (packageName != null) {
    stdout.writeln('║  adb pull package: $packageName');
  } else {
    stdout.writeln('║  Tip: --package com.example.package_testing');
  }
  stdout.writeln('║');
  stdout.writeln('║  Bridge alone does NOT create a report.');
  stdout.writeln('║  In the running app: shield → Save (export).');
  stdout.writeln('║  Watch this terminal for: [bridge] HTTP sync');
  stdout.writeln('╚══════════════════════════════════════════════════════════╝');
  stdout.writeln('');
  stdout.writeln('[bridge] Waiting for Export from the app…');

  if (packageName != null && adb != null) {
    Timer.periodic(const Duration(seconds: 3), (_) {
      // ignore: discarded_futures
      _pullFromDevice(adb, packageName, outDir);
    });
    // ignore: discarded_futures
    _pullFromDevice(adb, packageName, outDir);
  } else if (packageName != null && adb == null) {
    stdout.writeln(
      '[bridge] Skipping adb pull — adb not found. HTTP sync only.',
    );
  }

  await for (final request in server) {
    try {
      await _handle(request, outDir);
    } catch (e, st) {
      stderr.writeln('[bridge] error: $e');
      stderr.writeln('$st');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('error: $e');
      await request.response.close();
    }
  }
}

int? _readIntArg(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i >= 0 && i + 1 < args.length) return int.tryParse(args[i + 1]);
  return null;
}

String? _readStringArg(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i >= 0 && i + 1 < args.length) return args[i + 1];
  return null;
}

/// Resolve `adb` from PATH or common Android SDK locations.
String? _findAdb() {
  final fromPath = _adbFromPath();
  if (fromPath != null) return fromPath;

  final env = Platform.environment;
  final home = env['ANDROID_HOME'] ?? env['ANDROID_SDK_ROOT'];
  final localAppData = env['LOCALAPPDATA'];
  final userProfile = env['USERPROFILE'] ?? env['HOME'];

  final candidates = <String>[
    if (home != null) p.join(home, 'platform-tools', _adbName),
    if (localAppData != null)
      p.join(localAppData, 'Android', 'Sdk', 'platform-tools', _adbName),
    if (userProfile != null)
      p.join(
        userProfile,
        'AppData',
        'Local',
        'Android',
        'Sdk',
        'platform-tools',
        _adbName,
      ),
    if (userProfile != null)
      p.join(userProfile, 'Android', 'Sdk', 'platform-tools', _adbName),
    if (Platform.isMacOS)
      p.join(
        userProfile ?? '',
        'Library',
        'Android',
        'sdk',
        'platform-tools',
        _adbName,
      ),
    if (Platform.isLinux)
      p.join(userProfile ?? '', 'Android', 'Sdk', 'platform-tools', _adbName),
  ];

  for (final candidate in candidates) {
    if (candidate.isEmpty) continue;
    if (File(candidate).existsSync()) return candidate;
  }
  return null;
}

String get _adbName => Platform.isWindows ? 'adb.exe' : 'adb';

String? _adbFromPath() {
  try {
    final result = Process.runSync(
      Platform.isWindows ? 'where' : 'which',
      ['adb'],
      runInShell: true,
    );
    if (result.exitCode != 0) return null;
    final text = (result.stdout as String?)?.trim() ?? '';
    if (text.isEmpty) return null;
    final first = text.split(RegExp(r'\r?\n')).first.trim();
    if (first.isNotEmpty && File(first).existsSync()) return first;
  } catch (_) {}
  return null;
}

Future<bool> _tryAdbReverse(int port, String? adb) async {
  if (adb == null) {
    stdout.writeln(
      '[bridge] adb not found — checked PATH and Android SDK folders.',
    );
    stdout.writeln(
      '[bridge] Install platform-tools, or use an emulator (10.0.2.2).',
    );
    return false;
  }

  try {
    final result = await Process.run(adb, [
      'reverse',
      'tcp:$port',
      'tcp:$port',
    ]);
    if (result.exitCode == 0) {
      stdout.writeln('[bridge] adb reverse tcp:$port ✓');
      return true;
    }
    stdout.writeln(
      '[bridge] adb reverse failed: ${'${result.stderr}'.trim()}',
    );
    stdout.writeln(
      '[bridge] Start an emulator or connect a device, then restart bridge.',
    );
    return false;
  } catch (e) {
    stdout.writeln('[bridge] adb reverse error: $e');
    return false;
  }
}

Future<void> _handle(HttpRequest request, Directory outDir) async {
  if (request.method == 'GET' && request.uri.path == '/health') {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'ok': true, 'dir': outDir.path}));
    await request.response.close();
    return;
  }

  if (request.method == 'POST' && request.uri.path == '/report') {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    _writePayload(outDir, data);
    final htmlPath = p.join(outDir.path, 'report.html');
    stdout.writeln(
      '[bridge] HTTP sync → $htmlPath (${DateTime.now().toIso8601String()})',
    );

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'ok': true, 'path': htmlPath}));
    await request.response.close();
    return;
  }

  request.response
    ..statusCode = HttpStatus.notFound
    ..write('Not found. POST /report');
  await request.response.close();
}

void _writePayload(Directory outDir, Map<String, dynamic> data) {
  final jsonText = data['json'] as String?;
  final htmlText = data['html'] as String?;
  final logText = data['log'] as String?;

  if (jsonText != null) {
    File(p.join(outDir.path, 'report.json')).writeAsStringSync(jsonText);
  }
  if (htmlText != null) {
    File(p.join(outDir.path, 'report.html')).writeAsStringSync(htmlText);
  }
  if (logText != null) {
    File(p.join(outDir.path, 'guardian.log')).writeAsStringSync(logText);
  }
}

String? _lastPullFingerprint;

Future<void> _pullFromDevice(
  String adb,
  String packageName,
  Directory outDir,
) async {
  try {
    var wrote = false;
    for (final name in ['report.html', 'report.json', 'guardian.log']) {
      final result = await Process.run(adb, [
        'shell',
        'run-as',
        packageName,
        'cat',
        'app_flutter/flutter_health_guard/$name',
      ]);
      if (result.exitCode != 0) continue;
      final text = result.stdout;
      if (text is! String || text.isEmpty) continue;

      if (name == 'report.html') {
        final fingerprint = '${text.length}:${text.hashCode}';
        if (fingerprint == _lastPullFingerprint) return;
        _lastPullFingerprint = fingerprint;
      }

      File(p.join(outDir.path, name)).writeAsStringSync(text);
      wrote = true;
    }

    if (wrote) {
      stdout.writeln(
        '[bridge] adb pull → ${p.join(outDir.path, 'report.html')} '
        '(${DateTime.now().toIso8601String()})',
      );
    }
  } catch (_) {
    // Device locked / app not installed yet — ignore until next tick.
  }
}

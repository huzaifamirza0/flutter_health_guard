import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves a writable report directory.
///
/// - **Desktop** (Windows / macOS / Linux): `<project>/flutter_health_guard`
/// - **Mobile** (Android / iOS): app documents — the phone cannot write into
///   your PC project folder, and `Directory.current` is often `/` (read-only).
Future<String> resolveDefaultReportDirectory() async {
  if (Platform.isAndroid || Platform.isIOS) {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'flutter_health_guard');
  }

  final cwd = Directory.current.absolute.path;

  // Never write to filesystem root (seen on some mobile / embedded shells).
  if (cwd == '/' ||
      cwd == r'\' ||
      RegExp(r'^[A-Za-z]:\\?$').hasMatch(cwd)) {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'flutter_health_guard');
  }

  return p.join(cwd, 'flutter_health_guard');
}

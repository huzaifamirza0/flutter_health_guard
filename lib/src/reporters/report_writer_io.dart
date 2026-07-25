import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../config/guardian_config.dart';
import '../models/report.dart';
import 'cli_reporter.dart';
import 'html_reporter.dart';

/// Paths produced by [ReportWriter] / [Guardian.generateReport].
class ReportArtifacts {
  /// Creates artifact path info.
  const ReportArtifacts({
    required this.directory,
    this.jsonPath,
    this.htmlPath,
    this.jsonContent,
    this.htmlContent,
    this.logContent,
    this.hostSynced = false,
  });

  /// Absolute output directory.
  final String directory;

  /// Absolute path to `report.json`, if written.
  final String? jsonPath;

  /// Absolute path to `report.html`, if written.
  final String? htmlPath;

  /// In-memory JSON (for host bridge sync).
  final String? jsonContent;

  /// In-memory HTML (for host bridge sync).
  final String? htmlContent;

  /// In-memory log (for host bridge sync).
  final String? logContent;

  /// True when [Guardian.exportReport] pushed files to the PC bridge.
  final bool hostSynced;

  ReportArtifacts copyWith({bool? hostSynced}) {
    return ReportArtifacts(
      directory: directory,
      jsonPath: jsonPath,
      htmlPath: htmlPath,
      jsonContent: jsonContent,
      htmlContent: htmlContent,
      logContent: logContent,
      hostSynced: hostSynced ?? this.hostSynced,
    );
  }
}

/// Writes report.json / report.html and prints the CLI summary.
class ReportWriter {
  Future<ReportArtifacts> write(
    GuardianReport report,
    GuardianConfig config,
  ) async {
    final raw = config.outputDirectory?.trim();
    if (raw == null || raw.isEmpty) {
      throw StateError('GuardianConfig.outputDirectory is empty');
    }
    final dir = Directory(raw).absolute;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    String? jsonPath;
    String? htmlPath;
    String? jsonContent;
    String? htmlContent;

    if (config.generateJson) {
      jsonContent =
          const JsonEncoder.withIndent('  ').convert(report.toJson());
      jsonPath = p.join(dir.path, 'report.json');
      File(jsonPath).writeAsStringSync(jsonContent);
    }

    if (config.generateHtml) {
      htmlContent = HtmlReporter().render(report);
      htmlPath = p.join(dir.path, 'report.html');
      File(htmlPath).writeAsStringSync(htmlContent);
    }

    final logContent = _buildLog(report);
    final logPath = p.join(dir.path, 'guardian.log');
    File(logPath).writeAsStringSync(logContent);

    debugPrint('[Guardian] Report written to: ${dir.path}');
    if (htmlPath != null) {
      debugPrint('[Guardian] Open in browser: $htmlPath');
    }

    if (config.printCliSummary) {
      CliReporter().printSummary(report, htmlPath: htmlPath);
    }

    return ReportArtifacts(
      directory: dir.path,
      jsonPath: jsonPath,
      htmlPath: htmlPath,
      jsonContent: jsonContent,
      htmlContent: htmlContent,
      logContent: logContent,
    );
  }

  String _buildLog(GuardianReport report) {
    final buf = StringBuffer()
      ..writeln('Flutter Health Guard ${report.meta['schemaVersion']}')
      ..writeln('Session: ${report.sessionId}')
      ..writeln('Generated: ${report.generatedAt.toIso8601String()}')
      ..writeln('Overall: ${report.scores.overall}/100')
      ..writeln('Crashes: ${report.crashes.length}')
      ..writeln('Network: ${report.network.length}')
      ..writeln('---');
    for (final r in report.recommendations) {
      buf.writeln('[${r.severity.name}] ${r.title}');
    }
    return buf.toString();
  }
}

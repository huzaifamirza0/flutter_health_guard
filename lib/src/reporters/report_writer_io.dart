import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/guardian_config.dart';
import '../models/report.dart';
import 'cli_reporter.dart';
import 'html_reporter.dart';

class ReportArtifacts {
  const ReportArtifacts({
    required this.directory,
    this.jsonPath,
    this.htmlPath,
  });

  final String directory;
  final String? jsonPath;
  final String? htmlPath;
}

/// Writes report.json / report.html and prints the CLI summary.
class ReportWriter {
  Future<ReportArtifacts> write(
    GuardianReport report,
    GuardianConfig config,
  ) async {
    final dir = Directory(config.outputDirectory);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    String? jsonPath;
    String? htmlPath;

    if (config.generateJson) {
      jsonPath = p.join(dir.path, 'report.json');
      File(jsonPath).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(report.toJson()),
      );
    }

    if (config.generateHtml) {
      htmlPath = p.join(dir.path, 'report.html');
      File(htmlPath).writeAsStringSync(HtmlReporter().render(report));
    }

    final logPath = p.join(dir.path, 'guardian.log');
    File(logPath).writeAsStringSync(_buildLog(report));

    if (config.printCliSummary) {
      CliReporter().printSummary(report, htmlPath: htmlPath);
    }

    return ReportArtifacts(
      directory: dir.path,
      jsonPath: jsonPath,
      htmlPath: htmlPath,
    );
  }

  String _buildLog(GuardianReport report) {
    final buf = StringBuffer()
      ..writeln('Flutter Guardian ${report.meta['schemaVersion']}')
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

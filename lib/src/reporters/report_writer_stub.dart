import '../config/guardian_config.dart';
import '../models/report.dart';
import 'cli_reporter.dart';

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

  final String directory;
  final String? jsonPath;
  final String? htmlPath;
  final String? jsonContent;
  final String? htmlContent;
  final String? logContent;
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

/// Web / non-IO stub — prints CLI summary only.
class ReportWriter {
  Future<ReportArtifacts> write(
    GuardianReport report,
    GuardianConfig config,
  ) async {
    if (config.printCliSummary) {
      CliReporter().printSummary(report);
    }
    return ReportArtifacts(
      directory: config.outputDirectory ?? 'flutter_health_guard',
    );
  }
}

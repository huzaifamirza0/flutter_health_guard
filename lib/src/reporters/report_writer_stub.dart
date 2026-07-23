import '../config/guardian_config.dart';
import '../models/report.dart';
import 'cli_reporter.dart';

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

/// Web / non-IO stub — prints CLI summary only.
class ReportWriter {
  Future<ReportArtifacts> write(
    GuardianReport report,
    GuardianConfig config,
  ) async {
    if (config.printCliSummary) {
      CliReporter().printSummary(report);
    }
    return ReportArtifacts(directory: config.outputDirectory);
  }
}

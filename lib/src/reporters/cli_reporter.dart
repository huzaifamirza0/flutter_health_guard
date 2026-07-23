import '../models/report.dart';

class CliReporter {
  void printSummary(GuardianReport report, {String? htmlPath}) {
    final s = report.scores;
    final top = report.recommendations.isEmpty
        ? null
        : report.recommendations.first;

    final lines = <String>[
      '',
      'Flutter Guardian',
      '────────────────────────────',
      '',
      'Overall Score',
      '${s.overall}/100',
      '',
      'Performance   ${s.performance}',
      'Memory        ${s.memory}',
      'Network       ${s.network}',
      'Stability     ${s.stability}',
      'UI            ${s.ui}',
      '',
    ];

    if (htmlPath != null) {
      lines.addAll([
        'Report generated:',
        htmlPath,
        '',
      ]);
    }

    if (top != null && top.id != 'healthy-session') {
      lines.addAll([
        'Top recommendation:',
        top.title,
        if (top.estimatedImprovement != null) ...[
          '',
          'Expected improvement:',
          top.estimatedImprovement!,
        ],
        '',
      ]);
    } else {
      lines.addAll([
        'No critical issues detected.',
        '',
      ]);
    }

    // ignore: avoid_print
    print(lines.join('\n'));
  }
}

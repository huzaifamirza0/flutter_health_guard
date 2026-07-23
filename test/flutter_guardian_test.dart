import 'dart:io';

import 'package:flutter_guardian/flutter_guardian.dart';
import 'package:flutter_guardian/src/analyzer/analyzer.dart';
import 'package:flutter_guardian/src/analyzer/session_store.dart';
import 'package:flutter_guardian/src/reporters/html_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuardianAnalyzer', () {
    test('produces scores and recommendations from session data', () {
      final store = SessionStore(
        maxNetworkEvents: 100,
        maxLogEvents: 100,
        maxNavigationEvents: 100,
      )..startupTimeMs = 3200;

      store.frameStats
        ..totalFrames = 120
        ..slowFrames = 20
        ..jankFrames = 15
        ..totalBuildMicros = 120 * 8000
        ..totalRasterMicros = 120 * 4000
        ..maxFrameMs = 42;

      store.recordWidgetRebuild('ProductCard', buildMicros: 2000);
      for (var i = 0; i < 150; i++) {
        store.recordWidgetRebuild('ProductCard', buildMicros: 1500);
      }

      store.addCrash(CrashEvent(
        type: 'StateError',
        message: 'boom',
        timestamp: DateTime.now(),
      ));

      store.addNetwork(NetworkEvent(
        method: 'GET',
        url: 'https://api.example.com/products',
        startTime: DateTime.now().subtract(const Duration(milliseconds: 200)),
        endTime: DateTime.now(),
        statusCode: 200,
        responseSizeBytes: 2048,
      ));
      store.addNetwork(NetworkEvent(
        method: 'GET',
        url: 'https://api.example.com/products',
        startTime: DateTime.now().subtract(const Duration(milliseconds: 180)),
        endTime: DateTime.now(),
        statusCode: 200,
      ));
      store.addNetwork(NetworkEvent(
        method: 'GET',
        url: 'https://api.example.com/products',
        startTime: DateTime.now().subtract(const Duration(milliseconds: 160)),
        endTime: DateTime.now(),
        statusCode: 200,
      ));

      final report = GuardianAnalyzer().analyze(store);

      expect(report.scores.overall, inInclusiveRange(0, 100));
      expect(report.scores.stability, lessThan(100));
      expect(report.recommendations, isNotEmpty);
      expect(
        report.recommendations.any((r) => r.category == 'ui'),
        isTrue,
      );
      expect(
        report.recommendations.any((r) => r.category == 'network'),
        isTrue,
      );
      expect(report.toJson()['version'], '0.1.0');
    });

    test('healthy session scores near perfect', () {
      final store = SessionStore(
        maxNetworkEvents: 50,
        maxLogEvents: 50,
        maxNavigationEvents: 50,
      )..startupTimeMs = 600;

      store.frameStats
        ..totalFrames = 60
        ..totalBuildMicros = 60 * 4000
        ..totalRasterMicros = 60 * 2000;

      final report = GuardianAnalyzer().analyze(store);
      expect(report.scores.overall, greaterThanOrEqualTo(90));
      expect(report.scores.stability, 100);
    });
  });

  group('HtmlReporter', () {
    test('embeds report json and guardian branding', () {
      final store = SessionStore(
        maxNetworkEvents: 10,
        maxLogEvents: 10,
        maxNavigationEvents: 10,
      );
      final report = GuardianAnalyzer().analyze(store);
      final html = HtmlReporter().render(report);

      expect(html, contains('Flutter Guardian'));
      expect(html, contains('const REPORT ='));
      expect(html, contains(report.sessionId));
      expect(html, isNot(contains('</script></script>')));
    });
  });

  group('ReportWriter', () {
    test('writes json and html artifacts', () async {
      final dir = Directory.systemTemp.createTempSync('guardian_test_');
      addTearDown(() {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });

      final store = SessionStore(
        maxNetworkEvents: 10,
        maxLogEvents: 10,
        maxNavigationEvents: 10,
      );
      final report = GuardianAnalyzer().analyze(store);
      final artifacts = await ReportWriter().write(
        report,
        GuardianConfig(
          outputDirectory: dir.path,
          printCliSummary: false,
        ),
      );

      expect(File(artifacts.jsonPath!).existsSync(), isTrue);
      expect(File(artifacts.htmlPath!).existsSync(), isTrue);
      expect(File('${dir.path}/guardian.log').existsSync(), isTrue);
    });
  });

  group('Guardian facade', () {
    tearDown(() async {
      if (Guardian.isInitialized) {
        await Guardian.dispose(generateReport: false);
      }
    });

    test('initialize and analyze', () async {
      await Guardian.initialize(
        config: const GuardianConfig(
          enableNetwork: false,
          autoGenerateReport: false,
          printCliSummary: false,
        ),
      );

      Guardian.log('hello');
      Guardian.recordWidgetRebuild('Demo', buildMicros: 500);

      final report = Guardian.analyze();
      expect(report, isNotNull);
      expect(report!.logs, isNotEmpty);
      expect(report.widgets, isNotEmpty);
    });
  });
}

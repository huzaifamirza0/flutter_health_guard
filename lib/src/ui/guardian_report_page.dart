import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../guardian.dart';

/// Full-screen in-app Guardian health report.
class GuardianReportPage extends StatefulWidget {
  const GuardianReportPage({super.key, this.onClose});

  /// Called when the user taps back/close (used when shown outside a Navigator).
  final VoidCallback? onClose;

  @override
  State<GuardianReportPage> createState() => _GuardianReportPageState();
}

class _GuardianReportPageState extends State<GuardianReportPage> {
  GuardianReport? _report;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() => _report = Guardian.analyze());
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    final nav = Navigator.maybeOf(context);
    if (nav?.canPop() ?? false) {
      nav!.pop();
    }
  }

  Future<void> _copyReportJson() async {
    final report = _report ?? Guardian.analyze();
    if (report == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report data yet')),
      );
      return;
    }
    final json = const JsonEncoder.withIndent('  ').convert(report.toJson());
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Full report JSON copied')),
    );
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final artifacts = await Guardian.exportReport();
      if (!mounted) return;
      _refresh();

      final path = artifacts?.htmlPath ?? artifacts?.directory ?? 'unknown';
      final mobile = defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
      final String message;
      if (artifacts == null) {
        message = 'Export failed. Is Guardian initialized?';
      } else if (artifacts.hostSynced) {
        message =
            'Synced to your PC project folder:\n'
            'flutter_health_guard/report.html\n\n'
            'Also saved on device:\n$path';
      } else if (!mobile) {
        message =
            'Report written to project folder:\n$path\n\n'
            'Open report.html in a browser.';
      } else {
        message =
            'Saved on device only:\n$path\n\n'
            'PC flutter_health_guard/ stays empty until bridge gets Export.\n\n'
            '1. Keep running in project root:\n'
            '   dart run flutter_health_guard:guardian_bridge '
            '--package com.example.package_testing\n'
            '2. Physical phone needs adb (platform-tools on PATH)\n'
            '3. Emulator can sync without adb reverse\n'
            '4. Tap Save again — bridge should print [bridge] HTTP sync';
      }

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          title: const Text('Export report', style: TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70, height: 1.4)),
          actions: [
            TextButton(
              onPressed: () async {
                final text = artifacts?.jsonContent;
                if (text != null) {
                  await Clipboard.setData(ClipboardData(text: text));
                } else {
                  await _copyReportJson();
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report JSON copied')),
                  );
                }
              },
              child: const Text('Copy JSON'),
            ),
            if (artifacts?.htmlPath != null)
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: artifacts!.htmlPath!));
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Path copied')),
                    );
                  }
                },
                child: const Text('Copy path'),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Color _scoreColor(int score) {
    if (score >= 90) return const Color(0xFF3ECF8E);
    if (score >= 70) return const Color(0xFFF5A524);
    return const Color(0xFFF31260);
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final theme = Theme.of(context);

    // When opened as a real route, system back pops this page only.
    // When [onClose] is set, we handle close ourselves.
    return PopScope(
      canPop: widget.onClose == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1419),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A2332),
          foregroundColor: Colors.white,
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: _close,
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Flutter Health Guard', style: TextStyle(fontSize: 13, letterSpacing: 1.2)),
              Text('Health Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Copy full report JSON',
              onPressed: _copyReportJson,
              icon: const Icon(Icons.copy_all),
            ),
            IconButton(
              tooltip: 'Export report file (one click)',
              onPressed: _exporting ? null : _export,
              icon: _exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_alt),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: report == null
            ? const Center(
                child: Text(
                  'No session data yet.\nUse the app, then refresh.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _OverallCard(
                    score: report.scores.overall,
                    color: _scoreColor(report.scores.overall),
                    sessionId: report.sessionId,
                    startupMs: report.startupTimeMs,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle('Scores'),
                  const SizedBox(height: 8),
                  ...report.scores.categories.map(
                    (c) => _ScoreBar(
                      name: c.name,
                      score: c.score,
                      color: _scoreColor(c.score),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    'Recommendations',
                    trailing: '${report.recommendations.length}',
                  ),
                  const SizedBox(height: 8),
                  if (report.recommendations.isEmpty)
                    const _EmptyHint('No recommendations yet.')
                  else
                    ...report.recommendations.map(_RecommendationTile.new),
                  const SizedBox(height: 20),
                  _SectionTitle('Session'),
                  const SizedBox(height: 8),
                  _StatGrid(
                    items: [
                      _Stat('Crashes', '${report.crashes.length}'),
                      _Stat('Requests', '${report.network.length}'),
                      _Stat(
                        'Avg FPS',
                        report.frameStats.averageFps.toStringAsFixed(1),
                      ),
                      _Stat(
                        'Startup',
                        report.startupTimeMs == null
                            ? '—'
                            : '${report.startupTimeMs} ms',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    'Network',
                    trailing: '${report.network.length}',
                  ),
                  const SizedBox(height: 8),
                  if (report.network.isEmpty)
                    const _EmptyHint('No network calls captured yet.')
                  else
                    ...report.network.reversed.take(20).map(_NetworkTile.new),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    'Crashes',
                    trailing: '${report.crashes.length}',
                  ),
                  const SizedBox(height: 8),
                  if (report.crashes.isEmpty)
                    const _EmptyHint('No crashes detected. ✓')
                  else
                    ...report.crashes.map(_CrashTile.new),
                  const SizedBox(height: 20),
                  _SectionTitle('Navigation'),
                  const SizedBox(height: 8),
                  if (report.navigation.isEmpty)
                    const _EmptyHint('Add Guardian.navigatorObserver to MaterialApp.')
                  else
                    ...report.navigation.map(
                      (n) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.route, color: Color(0xFF3ECF8E), size: 18),
                        title: Text(
                          n.routeName,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${n.action} · ${n.timestamp.toLocal().toString().substring(11, 19)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ),
                  if (report.device != null) ...[
                    const SizedBox(height: 20),
                    _SectionTitle('Device'),
                    const SizedBox(height: 8),
                    Text(
                      '${report.device!.platform} · ${report.device!.osVersion}\n'
                      'Locale ${report.device!.locale}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF243044),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({
    required this.score,
    required this.color,
    required this.sessionId,
    required this.startupMs,
  });

  final int score;
  final Color color;
  final String sessionId;
  final int? startupMs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3A4F)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFF2A3548),
                  color: color,
                ),
                Center(
                  child: Text(
                    '$score',
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall health',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Session $sessionId',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (startupMs != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Startup ${startupMs}ms',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.name,
    required this.score,
    required this.color,
  });

  final String name;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              Text(
                '$score',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFF2A3548),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile(this.rec);

  final Recommendation rec;

  Color get _sevColor {
    switch (rec.severity) {
      case RecommendationSeverity.critical:
        return const Color(0xFFF31260);
      case RecommendationSeverity.warning:
        return const Color(0xFFF5A524);
      case RecommendationSeverity.info:
        return const Color(0xFF66B3FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF243044),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D3A4F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _sevColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rec.severity.name.toUpperCase(),
                  style: TextStyle(color: _sevColor, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Text(rec.category, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rec.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(rec.message, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (rec.fixes.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...rec.fixes.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $f', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ),
            ),
          ],
          if (rec.estimatedImprovement != null) ...[
            const SizedBox(height: 8),
            Text(
              'Estimated: ${rec.estimatedImprovement}',
              style: const TextStyle(color: Color(0xFF3ECF8E), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});
  final List<_Stat> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: items
          .map(
            (s) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF243044),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    s.value,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NetworkTile extends StatelessWidget {
  const _NetworkTile(this.event);
  final NetworkEvent event;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final ok = e.isSuccess;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF243044),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ok ? const Color(0x333ECF8E) : const Color(0x33F31260),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${e.statusCode ?? 'ERR'}',
              style: TextStyle(
                color: ok ? const Color(0xFF3ECF8E) : const Color(0xFFF31260),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e.method} ${e.url}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                ),
                Text(
                  e.durationMs == null ? '—' : '${e.durationMs} ms',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrashTile extends StatelessWidget {
  const _CrashTile(this.event);
  final CrashEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF243044),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x55F31260)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.type, style: const TextStyle(color: Color(0xFFF31260), fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(event.message, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(color: Colors.white54)),
    );
  }
}

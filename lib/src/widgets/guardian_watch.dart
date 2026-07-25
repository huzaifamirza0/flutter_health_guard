import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../guardian.dart';

/// Opt-in rebuild tracker for a subtree.
///
/// Wrap widgets you suspect are rebuilding too often:
///
/// ```dart
/// GuardianWatch(
///   name: 'ProductCard',
///   child: ProductCard(...),
/// )
/// ```
///
/// Rebuild counts appear in `report.json` / the HTML **Widget Rebuilds** table
/// and can trigger recommendations when counts are high.
class GuardianWatch extends StatefulWidget {
  /// Creates a rebuild-watched wrapper.
  const GuardianWatch({
    super.key,
    required this.name,
    required this.child,
  });

  /// Label used in reports (keep stable and human-readable).
  final String name;

  /// The widget subtree to track.
  final Widget child;

  @override
  State<GuardianWatch> createState() => _GuardianWatchState();
}

class _GuardianWatchState extends State<GuardianWatch> {
  @override
  Widget build(BuildContext context) {
    final sw = Stopwatch()..start();
    final child = widget.child;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      sw.stop();
      Guardian.recordWidgetRebuild(
        widget.name,
        buildMicros: sw.elapsedMicroseconds,
      );
    });
    return child;
  }
}

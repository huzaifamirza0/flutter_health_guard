import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../guardian.dart';

/// Wrap widgets you want rebuild-tracked.
///
/// ```dart
/// GuardianWatch(
///   name: 'ProductCard',
///   child: ProductCard(...),
/// )
/// ```
class GuardianWatch extends StatefulWidget {
  const GuardianWatch({
    super.key,
    required this.name,
    required this.child,
  });

  final String name;
  final Widget child;

  @override
  State<GuardianWatch> createState() => _GuardianWatchState();
}

class _GuardianWatchState extends State<GuardianWatch> {
  @override
  Widget build(BuildContext context) {
    final sw = Stopwatch()..start();
    final child = widget.child;
    // Defer recording until after this frame's build completes.
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

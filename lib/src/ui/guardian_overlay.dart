import 'package:flutter/material.dart';

import 'guardian_report_page.dart';

/// Wraps your app and shows a **draggable** floating Guardian button.
///
/// Tap it to open the in-app health report.
///
/// Works inside `MaterialApp.builder` (which sits above the Navigator).
/// The report is pushed onto your app's [Navigator] so the system back
/// button closes the report instead of exiting the app.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => GuardianOverlay(
///     child: child ?? const SizedBox.shrink(),
///   ),
///   home: HomePage(),
/// )
/// ```
class GuardianOverlay extends StatefulWidget {
  const GuardianOverlay({
    super.key,
    required this.child,
    this.visible = true,
  });

  final Widget child;

  /// Set false to hide the floating button (e.g. in release builds).
  final bool visible;

  @override
  State<GuardianOverlay> createState() => _GuardianOverlayState();
}

class _GuardianOverlayState extends State<GuardianOverlay> {
  static const double _size = 56;

  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();
  late final OverlayEntry _rootEntry;

  Offset _offset = const Offset(-1, -1);
  bool _dragging = false;
  int _pointerMoveCount = 0;
  bool _reportOpen = false;
  OverlayEntry? _reportEntry;

  @override
  void initState() {
    super.initState();
    _rootEntry = OverlayEntry(
      maintainState: true,
      builder: (context) => _buildStack(context),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_offset.dx < 0) {
      final size = MediaQuery.sizeOf(context);
      final padding = MediaQuery.paddingOf(context);
      _offset = Offset(
        size.width - _size - 16,
        size.height - padding.bottom - _size - 24,
      );
      _rootEntry.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _reportEntry?.remove();
    _reportEntry = null;
    super.dispose();
  }

  /// [GuardianOverlay] sits above the [Navigator], so we walk descendants.
  NavigatorState? _findNavigator() {
    NavigatorState? found;
    void visitor(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is NavigatorState) {
        found = element.state as NavigatorState;
        return;
      }
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
    return found;
  }

  Future<void> _openReport() async {
    if (_reportOpen || _reportEntry != null) return;

    final navigator = _findNavigator();
    if (navigator != null) {
      _reportOpen = true;
      try {
        await navigator.push<void>(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (context) => GuardianReportPage(
              onClose: () {
                if (navigator.canPop()) navigator.pop();
              },
            ),
          ),
        );
      } finally {
        _reportOpen = false;
      }
      return;
    }

    // Fallback when no Navigator is present (rare).
    final overlay = _overlayKey.currentState;
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return BackButtonListener(
          onBackButtonPressed: () async {
            entry.remove();
            if (_reportEntry == entry) _reportEntry = null;
            return true;
          },
          child: Material(
            color: const Color(0xFF0F1419),
            child: GuardianReportPage(
              onClose: () {
                entry.remove();
                if (_reportEntry == entry) _reportEntry = null;
              },
            ),
          ),
        );
      },
    );
    _reportEntry = entry;
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(
      key: _overlayKey,
      initialEntries: <OverlayEntry>[_rootEntry],
    );
  }

  Widget _buildStack(BuildContext context) {
    if (!widget.visible) return widget.child;

    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final maxX = (size.width - _size - 8).clamp(8.0, size.width);
    final maxY =
        (size.height - _size - padding.bottom - 8).clamp(8.0, size.height);
    final dx = _offset.dx.clamp(8.0, maxX);
    final dy = _offset.dy.clamp(padding.top + 8, maxY);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          left: dx,
          top: dy,
          child: Listener(
            onPointerDown: (_) => _pointerMoveCount = 0,
            onPointerMove: (event) {
              _pointerMoveCount++;
              _dragging = true;
              _offset += event.delta;
              _rootEntry.markNeedsBuild();
            },
            onPointerUp: (_) {
              final wasDrag = _pointerMoveCount > 4;
              _dragging = false;
              _rootEntry.markNeedsBuild();
              if (!wasDrag) _openReport();
            },
            child: AnimatedScale(
              scale: _dragging ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: Material(
                color: Colors.transparent,
                elevation: 10,
                shape: const CircleBorder(),
                child: Container(
                  width: _size,
                  height: _size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3ECF8E), Color(0xFF1FA97A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3ECF8E).withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

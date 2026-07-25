/// Flutter Health Guard — the Lighthouse of Flutter.
///
/// Runtime SDK that collects crashes, network, performance, navigation, and
/// device data, then produces scored health reports with actionable
/// recommendations.
///
/// ## Getting started
///
/// ```dart
/// import 'package:flutter_health_guard/flutter_health_guard.dart';
///
/// Future<void> main() async {
///   await Guardian.initialize(
///     config: const GuardianConfig(
///       enableNetwork: true,
///       enablePerformance: true,
///     ),
///   );
///   runApp(const MyApp());
/// }
/// ```
///
/// See the package README for installation, platform notes, and limitations.
library;

export 'src/guardian.dart';

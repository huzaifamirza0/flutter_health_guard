/// Flutter Guardian — the Lighthouse of Flutter.
///
/// Collects crashes, network, performance, navigation, and device data,
/// then produces scored health reports with actionable recommendations.
///
/// ```dart
/// import 'package:flutter_guardian/flutter_guardian.dart';
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
library;

export 'src/guardian.dart';

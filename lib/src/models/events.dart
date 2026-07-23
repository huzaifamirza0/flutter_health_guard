// Shared event models collected during a Guardian session.

enum LogLevel { debug, info, warning, error }

class LogEvent {
  LogEvent({
    required this.message,
    required this.level,
    required this.timestamp,
    this.tag,
  });

  final String message;
  final LogLevel level;
  final DateTime timestamp;
  final String? tag;

  Map<String, dynamic> toJson() => {
        'message': message,
        'level': level.name,
        'timestamp': timestamp.toIso8601String(),
        if (tag != null) 'tag': tag,
      };
}

class CrashEvent {
  CrashEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.stackTrace,
    this.library,
    this.context,
  });

  final String type;
  final String message;
  final DateTime timestamp;
  final String? stackTrace;
  final String? library;
  final String? context;

  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        if (stackTrace != null) 'stackTrace': stackTrace,
        if (library != null) 'library': library,
        if (context != null) 'context': context,
      };
}

class NetworkEvent {
  NetworkEvent({
    required this.method,
    required this.url,
    required this.startTime,
    this.endTime,
    this.statusCode,
    this.requestHeaders,
    this.responseHeaders,
    this.requestBody,
    this.responseBody,
    this.error,
    this.requestSizeBytes,
    this.responseSizeBytes,
  });

  final String method;
  final String url;
  final DateTime startTime;
  DateTime? endTime;
  int? statusCode;
  Map<String, String>? requestHeaders;
  Map<String, String>? responseHeaders;
  String? requestBody;
  String? responseBody;
  String? error;
  int? requestSizeBytes;
  int? responseSizeBytes;

  int? get durationMs {
    if (endTime == null) return null;
    return endTime!.difference(startTime).inMilliseconds;
  }

  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 400;

  Map<String, dynamic> toJson() => {
        'method': method,
        'url': url,
        'startTime': startTime.toIso8601String(),
        if (endTime != null) 'endTime': endTime!.toIso8601String(),
        if (durationMs != null) 'durationMs': durationMs,
        if (statusCode != null) 'statusCode': statusCode,
        if (requestHeaders != null) 'requestHeaders': requestHeaders,
        if (responseHeaders != null) 'responseHeaders': responseHeaders,
        if (requestBody != null) 'requestBody': requestBody,
        if (responseBody != null) 'responseBody': responseBody,
        if (error != null) 'error': error,
        if (requestSizeBytes != null) 'requestSizeBytes': requestSizeBytes,
        if (responseSizeBytes != null) 'responseSizeBytes': responseSizeBytes,
        'success': isSuccess,
      };
}

class NavigationEvent {
  NavigationEvent({
    required this.action,
    required this.routeName,
    required this.timestamp,
    this.previousRouteName,
    this.arguments,
  });

  final String action; // push | pop | replace | remove
  final String routeName;
  final DateTime timestamp;
  final String? previousRouteName;
  final String? arguments;

  Map<String, dynamic> toJson() => {
        'action': action,
        'routeName': routeName,
        'timestamp': timestamp.toIso8601String(),
        if (previousRouteName != null) 'previousRouteName': previousRouteName,
        if (arguments != null) 'arguments': arguments,
      };
}

class LifecycleEvent {
  LifecycleEvent({
    required this.state,
    required this.timestamp,
  });

  final String state;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'state': state,
        'timestamp': timestamp.toIso8601String(),
      };
}

class FrameStats {
  FrameStats({
    this.totalFrames = 0,
    this.slowFrames = 0,
    this.jankFrames = 0,
    this.totalBuildMicros = 0,
    this.totalRasterMicros = 0,
    this.maxFrameMs = 0,
  });

  int totalFrames;
  int slowFrames;
  int jankFrames;
  int totalBuildMicros;
  int totalRasterMicros;
  double maxFrameMs;

  double get averageFps {
    if (totalFrames == 0) return 0;
    final avgFrameMs =
        (totalBuildMicros + totalRasterMicros) / totalFrames / 1000.0;
    if (avgFrameMs <= 0) return 60;
    return (1000.0 / avgFrameMs).clamp(0, 120);
  }

  double get jankRate {
    if (totalFrames == 0) return 0;
    return jankFrames / totalFrames;
  }

  Map<String, dynamic> toJson() => {
        'totalFrames': totalFrames,
        'slowFrames': slowFrames,
        'jankFrames': jankFrames,
        'averageFps': double.parse(averageFps.toStringAsFixed(1)),
        'jankRate': double.parse(jankRate.toStringAsFixed(4)),
        'maxFrameMs': double.parse(maxFrameMs.toStringAsFixed(2)),
        'averageBuildMs': totalFrames == 0
            ? 0
            : double.parse(
                (totalBuildMicros / totalFrames / 1000).toStringAsFixed(2)),
        'averageRasterMs': totalFrames == 0
            ? 0
            : double.parse(
                (totalRasterMicros / totalFrames / 1000).toStringAsFixed(2)),
      };
}

class DeviceInfo {
  DeviceInfo({
    required this.platform,
    required this.osVersion,
    required this.locale,
    this.numberOfProcessors,
    this.appName,
    this.packageName,
    this.appVersion,
    this.buildNumber,
    this.isPhysicalDevice,
  });

  final String platform;
  final String osVersion;
  final String locale;
  final int? numberOfProcessors;
  final String? appName;
  final String? packageName;
  final String? appVersion;
  final String? buildNumber;
  final bool? isPhysicalDevice;

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'osVersion': osVersion,
        'locale': locale,
        if (numberOfProcessors != null)
          'numberOfProcessors': numberOfProcessors,
        if (appName != null) 'appName': appName,
        if (packageName != null) 'packageName': packageName,
        if (appVersion != null) 'appVersion': appVersion,
        if (buildNumber != null) 'buildNumber': buildNumber,
        if (isPhysicalDevice != null) 'isPhysicalDevice': isPhysicalDevice,
      };
}

class WidgetRebuildStat {
  WidgetRebuildStat({
    required this.widgetName,
    this.rebuilds = 0,
    this.totalBuildMicros = 0,
    this.maxBuildMicros = 0,
  });

  final String widgetName;
  int rebuilds;
  int totalBuildMicros;
  int maxBuildMicros;

  double get averageBuildMs =>
      rebuilds == 0 ? 0 : totalBuildMicros / rebuilds / 1000.0;

  Map<String, dynamic> toJson() => {
        'widgetName': widgetName,
        'rebuilds': rebuilds,
        'averageBuildMs':
            double.parse(averageBuildMs.toStringAsFixed(2)),
        'maxBuildMs':
            double.parse((maxBuildMicros / 1000.0).toStringAsFixed(2)),
        'totalBuildMs':
            double.parse((totalBuildMicros / 1000.0).toStringAsFixed(2)),
      };
}

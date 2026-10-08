class DevicePermissionsDto {
  final bool? notifications;
  final bool? locationForeground;
  final bool? locationBackground;
  final bool? batteryOptimizationIgnored;
  final bool? deviceAdmin;
  final bool? fullScreenIntent;

  const DevicePermissionsDto({
    this.notifications,
    this.locationForeground,
    this.locationBackground,
    this.batteryOptimizationIgnored,
    this.deviceAdmin,
    this.fullScreenIntent,
  });

  factory DevicePermissionsDto.fromJson(Map<String, dynamic> json) {
    return DevicePermissionsDto(
      notifications: json['notifications'] as bool?,
      locationForeground: json['locationForeground'] as bool?,
      locationBackground: json['locationBackground'] as bool?,
      batteryOptimizationIgnored: json['batteryOptimizationIgnored'] as bool?,
      deviceAdmin: json['deviceAdmin'] as bool?,
      fullScreenIntent: json['fullScreenIntent'] as bool?,
    );
  }
}

class LastCommandDiagnosticsDto {
  final String type;
  final String status;
  final String? failureReason;
  final String at;

  const LastCommandDiagnosticsDto({
    required this.type,
    required this.status,
    this.failureReason,
    required this.at,
  });

  factory LastCommandDiagnosticsDto.fromJson(Map<String, dynamic> json) {
    return LastCommandDiagnosticsDto(
      type: json['type'] as String? ?? 'UNKNOWN',
      status: json['status'] as String? ?? 'UNKNOWN',
      failureReason: json['failureReason'] as String?,
      at: json['at'] as String? ?? '',
    );
  }
}

class DeviceDiagnosticsDto {
  final bool hasFcmToken;
  final bool hasDeviceToken;
  final String? lastSeenAt;
  final String? lastStatusAt;
  final String? lastLocationAt;
  final LastCommandDiagnosticsDto? lastCommand;
  final DevicePermissionsDto? permissions;
  final List<String> problems;

  const DeviceDiagnosticsDto({
    required this.hasFcmToken,
    required this.hasDeviceToken,
    this.lastSeenAt,
    this.lastStatusAt,
    this.lastLocationAt,
    this.lastCommand,
    this.permissions,
    required this.problems,
  });

  factory DeviceDiagnosticsDto.fromJson(Map<String, dynamic> json) {
    return DeviceDiagnosticsDto(
      hasFcmToken: json['hasFcmToken'] as bool? ?? false,
      hasDeviceToken: json['hasDeviceToken'] as bool? ?? false,
      lastSeenAt: json['lastSeenAt'] as String?,
      lastStatusAt: json['lastStatusAt'] as String?,
      lastLocationAt: json['lastLocationAt'] as String?,
      lastCommand: json['lastCommand'] != null && json['lastCommand'] is Map<String, dynamic>
          ? LastCommandDiagnosticsDto.fromJson(json['lastCommand'] as Map<String, dynamic>)
          : null,
      permissions: json['permissions'] != null && json['permissions'] is Map<String, dynamic>
          ? DevicePermissionsDto.fromJson(json['permissions'] as Map<String, dynamic>)
          : null,
      problems: (json['problems'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

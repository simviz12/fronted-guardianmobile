import 'package:guardian_mobile/features/locations/domain/entities/device_location.dart';

enum DeviceMode {
  protected,
  controller;

  String toContractString() {
    switch (this) {
      case DeviceMode.protected:
        return 'PROTECTED';
      case DeviceMode.controller:
        return 'CONTROLLER';
    }
  }

  static DeviceMode fromString(String value) {
    if (value.toUpperCase() == 'CONTROLLER') {
      return DeviceMode.controller;
    }
    return DeviceMode.protected;
  }
}

class Device {
  final String id;
  final String ownerId;
  final String installId;
  final String name;
  final String platform;
  final String? model;
  final String? osVersion;
  final String? appVersion;
  final DeviceMode mode;
  final String? fcmToken;
  final int? batteryLevel;
  final bool? isCharging;
  final DateTime? lastSeenAt;
  final bool isOnline;
  final bool adminEnabled;
  final LastLocationSummary? lastLocation;
  final String? networkType; // "wifi" | "mobile" | "none" | "unknown"
  final bool theftModeActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Device({
    required this.id,
    required this.ownerId,
    required this.installId,
    required this.name,
    required this.platform,
    this.model,
    this.osVersion,
    this.appVersion,
    required this.mode,
    this.fcmToken,
    this.batteryLevel,
    this.isCharging,
    this.lastSeenAt,
    required this.isOnline,
    this.adminEnabled = false,
    this.lastLocation,
    this.networkType,
    this.theftModeActive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Device copyWith({
    String? id,
    String? ownerId,
    String? installId,
    String? name,
    String? platform,
    String? model,
    String? osVersion,
    String? appVersion,
    DeviceMode? mode,
    String? fcmToken,
    int? batteryLevel,
    bool? isCharging,
    DateTime? lastSeenAt,
    bool? isOnline,
    bool? adminEnabled,
    LastLocationSummary? lastLocation,
    String? networkType,
    bool? theftModeActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Device(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      installId: installId ?? this.installId,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      model: model ?? this.model,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      mode: mode ?? this.mode,
      fcmToken: fcmToken ?? this.fcmToken,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isOnline: isOnline ?? this.isOnline,
      adminEnabled: adminEnabled ?? this.adminEnabled,
      lastLocation: lastLocation ?? this.lastLocation,
      networkType: networkType ?? this.networkType,
      theftModeActive: theftModeActive ?? this.theftModeActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LinkedDeviceResult {
  final Device device;
  final String deviceToken;

  const LinkedDeviceResult({
    required this.device,
    required this.deviceToken,
  });
}

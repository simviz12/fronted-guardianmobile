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
    required this.createdAt,
    required this.updatedAt,
  });
}

class LinkedDeviceResult {
  final Device device;
  final String deviceToken;

  const LinkedDeviceResult({
    required this.device,
    required this.deviceToken,
  });
}

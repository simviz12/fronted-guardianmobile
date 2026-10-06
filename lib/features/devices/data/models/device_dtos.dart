import '../../domain/entities/device.dart';

class DeviceDto {
  final String id;
  final String ownerId;
  final String installId;
  final String name;
  final String platform;
  final String? model;
  final String? osVersion;
  final String? appVersion;
  final String mode;
  final String? fcmToken;
  final int? batteryLevel;
  final bool? isCharging;
  final String? lastSeenAt;
  final bool isOnline;
  final String createdAt;
  final String updatedAt;

  const DeviceDto({
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) {
    return DeviceDto(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      installId: json['installId'] as String,
      name: json['name'] as String,
      platform: json['platform'] as String,
      model: json['model'] as String?,
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
      mode: json['mode'] as String,
      fcmToken: json['fcmToken'] as String?,
      batteryLevel: json['batteryLevel'] as int?,
      isCharging: json['isCharging'] as bool?,
      lastSeenAt: json['lastSeenAt'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'installId': installId,
      'name': name,
      'platform': platform,
      'model': model,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'mode': mode,
      'fcmToken': fcmToken,
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'lastSeenAt': lastSeenAt,
      'isOnline': isOnline,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Device toEntity() {
    return Device(
      id: id,
      ownerId: ownerId,
      installId: installId,
      name: name,
      platform: platform,
      model: model,
      osVersion: osVersion,
      appVersion: appVersion,
      mode: DeviceMode.fromString(mode),
      fcmToken: fcmToken,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      lastSeenAt: lastSeenAt != null ? DateTime.tryParse(lastSeenAt!) : null,
      isOnline: isOnline,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}

class LinkDeviceResponseDto {
  final DeviceDto device;
  final String deviceToken;

  const LinkDeviceResponseDto({
    required this.device,
    required this.deviceToken,
  });

  factory LinkDeviceResponseDto.fromJson(Map<String, dynamic> json) {
    return LinkDeviceResponseDto(
      device: DeviceDto.fromJson(json['device'] as Map<String, dynamic>),
      deviceToken: json['deviceToken'] as String,
    );
  }

  LinkedDeviceResult toEntity() {
    return LinkedDeviceResult(
      device: device.toEntity(),
      deviceToken: deviceToken,
    );
  }
}

class DevicesListResponseDto {
  final List<DeviceDto> devices;

  const DevicesListResponseDto({
    required this.devices,
  });

  factory DevicesListResponseDto.fromJson(Map<String, dynamic> json) {
    final list = json['devices'] as List<dynamic>? ?? [];
    return DevicesListResponseDto(
      devices: list.map((item) => DeviceDto.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  List<Device> toEntities() {
    return devices.map((d) => d.toEntity()).toList();
  }
}

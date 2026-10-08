import 'package:guardian_mobile/features/locations/domain/entities/device_location.dart';

sealed class RealtimeEvent {
  const RealtimeEvent();
}

class DeviceStatusEvent extends RealtimeEvent {
  final String deviceId;
  final bool isOnline;
  final int? batteryLevel;
  final bool? isCharging;
  final String? networkType;
  final DateTime lastSeenAt;

  const DeviceStatusEvent({
    required this.deviceId,
    required this.isOnline,
    this.batteryLevel,
    this.isCharging,
    this.networkType,
    required this.lastSeenAt,
  });

  factory DeviceStatusEvent.fromJson(Map<String, dynamic> json) {
    return DeviceStatusEvent(
      deviceId: json['deviceId'] as String,
      isOnline: json['isOnline'] as bool? ?? false,
      batteryLevel: json['batteryLevel'] as int?,
      isCharging: json['isCharging'] as bool?,
      networkType: json['networkType'] as String?,
      lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class DeviceLinkedEvent extends RealtimeEvent {
  final String deviceId;
  final String ownerId;

  const DeviceLinkedEvent({
    required this.deviceId,
    required this.ownerId,
  });

  factory DeviceLinkedEvent.fromJson(Map<String, dynamic> json) {
    return DeviceLinkedEvent(
      deviceId: json['deviceId'] as String,
      ownerId: json['ownerId'] as String,
    );
  }
}

class DeviceUnlinkedEvent extends RealtimeEvent {
  final String deviceId;
  final String ownerId;

  const DeviceUnlinkedEvent({
    required this.deviceId,
    required this.ownerId,
  });

  factory DeviceUnlinkedEvent.fromJson(Map<String, dynamic> json) {
    return DeviceUnlinkedEvent(
      deviceId: json['deviceId'] as String,
      ownerId: json['ownerId'] as String,
    );
  }
}

class CommandUpdatedEvent extends RealtimeEvent {
  final String commandId;
  final String deviceId;
  final String type;
  final String status;
  final String? failureReason;
  final DateTime updatedAt;

  const CommandUpdatedEvent({
    required this.commandId,
    required this.deviceId,
    required this.type,
    required this.status,
    this.failureReason,
    required this.updatedAt,
  });

  factory CommandUpdatedEvent.fromJson(Map<String, dynamic> json) {
    return CommandUpdatedEvent(
      commandId: json['commandId'] as String,
      deviceId: json['deviceId'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      failureReason: json['failureReason'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class LocationUpdatedEvent extends RealtimeEvent {
  final String deviceId;
  final DeviceLocation location;

  const LocationUpdatedEvent({
    required this.deviceId,
    required this.location,
  });

  factory LocationUpdatedEvent.fromJson(Map<String, dynamic> json) {
    final locData = json['location'] as Map<String, dynamic>;
    return LocationUpdatedEvent(
      deviceId: json['deviceId'] as String,
      location: DeviceLocation(
        id: locData['id'] as String,
        deviceId: locData['deviceId'] as String,
        latitude: (locData['latitude'] as num).toDouble(),
        longitude: (locData['longitude'] as num).toDouble(),
        accuracyMeters: (locData['accuracyMeters'] as num?)?.toDouble(),
        speedMps: (locData['speedMps'] as num?)?.toDouble(),
        recordedAt: DateTime.tryParse(locData['recordedAt'] as String? ?? '') ?? DateTime.now(),
        receivedAt: DateTime.tryParse(locData['receivedAt'] as String? ?? '') ?? DateTime.now(),
        source: LocationSource.fromString(locData['source'] as String? ?? 'PERIODIC'),
      ),
    );
  }
}

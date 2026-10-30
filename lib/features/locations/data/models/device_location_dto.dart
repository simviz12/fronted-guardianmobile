import '../../domain/entities/device_location.dart';

class DeviceLocationDto {
  final String id;
  final String deviceId;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final double? speedMps;
  final String recordedAt;
  final String? receivedAt;
  final String source;

  const DeviceLocationDto({
    required this.id,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.speedMps,
    required this.recordedAt,
    this.receivedAt,
    required this.source,
  });

  factory DeviceLocationDto.fromJson(Map<String, dynamic> json) {
    return DeviceLocationDto(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
      speedMps: (json['speedMps'] as num?)?.toDouble(),
      recordedAt: json['recordedAt'] as String,
      receivedAt: json['receivedAt'] as String?,
      source: json['source'] as String? ?? 'PERIODIC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      if (speedMps != null) 'speedMps': speedMps,
      'recordedAt': recordedAt,
      if (receivedAt != null) 'receivedAt': receivedAt,
      'source': source,
    };
  }

  DeviceLocation toEntity() {
    return DeviceLocation(
      id: id,
      deviceId: deviceId,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      speedMps: speedMps,
      recordedAt: DateTime.parse(recordedAt),
      receivedAt: receivedAt != null ? DateTime.tryParse(receivedAt!) : null,
      source: LocationSource.fromString(source),
    );
  }
}

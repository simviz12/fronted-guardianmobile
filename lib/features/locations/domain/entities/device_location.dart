enum LocationSource {
  locateCommand,
  periodic,
  theftMode;

  String toContractString() {
    switch (this) {
      case LocationSource.locateCommand:
        return 'LOCATE_COMMAND';
      case LocationSource.periodic:
        return 'PERIODIC';
      case LocationSource.theftMode:
        return 'THEFT_MODE';
    }
  }

  static LocationSource fromString(String value) {
    switch (value.toUpperCase()) {
      case 'LOCATE_COMMAND':
        return LocationSource.locateCommand;
      case 'PERIODIC':
        return LocationSource.periodic;
      case 'THEFT_MODE':
        return LocationSource.theftMode;
      default:
        return LocationSource.periodic;
    }
  }
}

class DeviceLocation {
  final String id;
  final String deviceId;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final double? speedMps;
  final DateTime recordedAt;
  final DateTime? receivedAt;
  final LocationSource source;

  const DeviceLocation({
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
}

class LastLocationSummary {
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime recordedAt;

  const LastLocationSummary({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    required this.recordedAt,
  });

  factory LastLocationSummary.fromJson(Map<String, dynamic> json) {
    return LastLocationSummary(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }
}

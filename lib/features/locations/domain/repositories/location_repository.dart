import '../entities/device_location.dart';

abstract class LocationRepository {
  Future<List<DeviceLocation>> getLocations({
    required String deviceId,
    DateTime? from,
    DateTime? to,
    int? limit,
  });

  Future<DeviceLocation> getLatestLocation({
    required String deviceId,
  });
}

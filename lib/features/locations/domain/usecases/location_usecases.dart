import '../entities/device_location.dart';
import '../repositories/location_repository.dart';

class GetLocationsUseCase {
  final LocationRepository _repository;

  GetLocationsUseCase(this._repository);

  Future<List<DeviceLocation>> call({
    required String deviceId,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) {
    return _repository.getLocations(
      deviceId: deviceId,
      from: from,
      to: to,
      limit: limit,
    );
  }
}

class GetLatestLocationUseCase {
  final LocationRepository _repository;

  GetLatestLocationUseCase(this._repository);

  Future<DeviceLocation> call({required String deviceId}) {
    return _repository.getLatestLocation(deviceId: deviceId);
  }
}

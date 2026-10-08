import '../../domain/entities/device_location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_remote_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource _remoteDataSource;

  LocationRepositoryImpl({required LocationRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<DeviceLocation>> getLocations({
    required String deviceId,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    final dtos = await _remoteDataSource.getLocations(
      deviceId: deviceId,
      from: from,
      to: to,
      limit: limit,
    );
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<DeviceLocation> getLatestLocation({
    required String deviceId,
  }) async {
    final dto = await _remoteDataSource.getLatestLocation(deviceId: deviceId);
    return dto.toEntity();
  }
}

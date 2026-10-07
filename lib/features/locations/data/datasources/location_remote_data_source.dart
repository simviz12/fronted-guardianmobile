import '../../../../core/network/dio_client.dart';
import '../models/device_location_dto.dart';

abstract class LocationRemoteDataSource {
  Future<List<DeviceLocationDto>> getLocations({
    required String deviceId,
    DateTime? from,
    DateTime? to,
    int? limit,
  });

  Future<DeviceLocationDto> getLatestLocation({
    required String deviceId,
  });
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final DioClient _client;

  LocationRemoteDataSourceImpl({required DioClient client}) : _client = client;

  @override
  Future<List<DeviceLocationDto>> getLocations({
    required String deviceId,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
    if (to != null) queryParams['to'] = to.toUtc().toIso8601String();
    if (limit != null) queryParams['limit'] = limit;

    final response = await _client.dio.get(
      '/devices/$deviceId/locations',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data;
    if (data is List) {
      return data
          .map((item) => DeviceLocationDto.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<DeviceLocationDto> getLatestLocation({
    required String deviceId,
  }) async {
    final response = await _client.dio.get('/devices/$deviceId/locations/latest');
    return DeviceLocationDto.fromJson(response.data as Map<String, dynamic>);
  }
}

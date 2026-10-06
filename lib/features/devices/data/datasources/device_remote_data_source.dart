import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/device_dtos.dart';

abstract class DeviceRemoteDataSource {
  Future<LinkDeviceResponseDto> linkDevice({
    required String installId,
    required String name,
    required String platform,
    String? model,
    String? osVersion,
    String? appVersion,
    required String mode,
    String? fcmToken,
  });

  Future<DevicesListResponseDto> listDevices();

  Future<DeviceDto> getDeviceById(String id);

  Future<DeviceDto> updateDevice({
    required String id,
    String? name,
    String? fcmToken,
  });

  Future<void> deleteDevice(String id);
}

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  final DioClient _client;

  DeviceRemoteDataSourceImpl({required DioClient client}) : _client = client;

  @override
  Future<LinkDeviceResponseDto> linkDevice({
    required String installId,
    required String name,
    required String platform,
    String? model,
    String? osVersion,
    String? appVersion,
    required String mode,
    String? fcmToken,
  }) async {
    try {
      final payload = <String, dynamic>{
        'installId': installId,
        'name': name,
        'platform': platform,
        'mode': mode,
      };
      if (model != null) payload['model'] = model;
      if (osVersion != null) payload['osVersion'] = osVersion;
      if (appVersion != null) payload['appVersion'] = appVersion;
      if (fcmToken != null) payload['fcmToken'] = fcmToken;

      final response = await _client.dio.post(
        '/devices',
        data: payload,
      );
      return LinkDeviceResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    }
  }

  @override
  Future<DevicesListResponseDto> listDevices() async {
    try {
      final response = await _client.dio.get('/devices');
      return DevicesListResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    }
  }

  @override
  Future<DeviceDto> getDeviceById(String id) async {
    try {
      final response = await _client.dio.get('/devices/$id');
      return DeviceDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    }
  }

  @override
  Future<DeviceDto> updateDevice({
    required String id,
    String? name,
    String? fcmToken,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name;
      if (fcmToken != null) payload['fcmToken'] = fcmToken;

      final response = await _client.dio.patch(
        '/devices/$id',
        data: payload,
      );
      return DeviceDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteDevice(String id) async {
    try {
      await _client.dio.delete('/devices/$id');
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    }
  }
}

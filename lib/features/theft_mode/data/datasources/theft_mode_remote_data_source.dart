import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../models/theft_mode_dto.dart';

abstract class TheftModeRemoteDataSource {
  Future<TheftModeConfigDto> activateTheftMode({
    required String deviceId,
    required String message,
    String? contactPhone,
    required int locationIntervalSeconds,
    required bool alarm,
    required bool lock,
  });

  Future<TheftModeConfigDto?> getActiveTheftMode(String deviceId);

  Future<List<TheftModeConfigDto>> getTheftModeHistory(String deviceId);

  Future<void> deactivateTheftMode({
    required String deviceId,
    required String password,
    bool force = false,
    String? twoFactorCode,
  });
}

class TheftModeRemoteDataSourceImpl implements TheftModeRemoteDataSource {
  final DioClient _client;

  TheftModeRemoteDataSourceImpl({required DioClient client}) : _client = client;

  @override
  Future<TheftModeConfigDto> activateTheftMode({
    required String deviceId,
    required String message,
    String? contactPhone,
    required int locationIntervalSeconds,
    required bool alarm,
    required bool lock,
  }) async {
    try {
      final body = <String, dynamic>{
        'message': message,
        'locationIntervalSeconds': locationIntervalSeconds,
        'alarm': alarm,
        'lock': lock,
      };
      if (contactPhone != null && contactPhone.trim().isNotEmpty) {
        body['contactPhone'] = contactPhone.trim();
      }

      final response = await _client.dio.post(
        '/devices/$deviceId/theft-mode',
        data: body,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['theftMode'] != null) {
        return TheftModeConfigDto.fromJson(data['theftMode'] as Map<String, dynamic>);
      }
      return TheftModeConfigDto.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<TheftModeConfigDto?> getActiveTheftMode(String deviceId) async {
    try {
      final response = await _client.dio.get('/devices/$deviceId/theft-mode');
      return TheftModeConfigDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<TheftModeConfigDto>> getTheftModeHistory(String deviceId) async {
    try {
      final response = await _client.dio.get('/devices/$deviceId/theft-mode/history');
      final data = response.data;
      if (data is List) {
        return data.map((e) => TheftModeConfigDto.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deactivateTheftMode({
    required String deviceId,
    required String password,
    bool force = false,
    String? twoFactorCode,
  }) async {
    try {
      final body = <String, dynamic>{'password': password};
      if (twoFactorCode != null && twoFactorCode.trim().isNotEmpty) {
        body['twoFactorCode'] = twoFactorCode.trim();
      }
      await _client.dio.delete(
        '/devices/$deviceId/theft-mode',
        queryParameters: {'force': force},
        data: body,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      String message = 'Error en el servidor.';
      List<String> details = [];

      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          if (data['message'] is List) {
            details = (data['message'] as List).map((i) => i.toString()).toList();
            message = details.isNotEmpty ? details.first : message;
          } else {
            message = data['message'].toString();
          }
        }
        if (data['error'] != null && details.isEmpty) {
          details.add(data['error'].toString());
        }
      }

      return ServerFailure(
        message: message,
        statusCode: statusCode,
        details: details,
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutFailure();
    }

    return NetworkFailure(message: e.message ?? 'Sin conexión al servidor.');
  }
}

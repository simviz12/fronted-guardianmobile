import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

abstract class WipeRemoteDataSource {
  Future<Map<String, dynamic>> wipeDevice({
    required String deviceId,
    required String password,
    String confirmationText = 'BORRAR',
  });
}

class WipeRemoteDataSourceImpl implements WipeRemoteDataSource {
  final DioClient _client;

  WipeRemoteDataSourceImpl({required DioClient client}) : _client = client;

  @override
  Future<Map<String, dynamic>> wipeDevice({
    required String deviceId,
    required String password,
    String confirmationText = 'BORRAR',
  }) async {
    try {
      final response = await _client.dio.post(
        '/devices/$deviceId/wipe',
        data: {
          'password': password,
          'confirmationText': confirmationText,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true};
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    }
  }
}

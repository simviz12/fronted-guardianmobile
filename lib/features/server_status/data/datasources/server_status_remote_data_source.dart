import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../models/server_status_dto.dart';

abstract interface class ServerStatusRemoteDataSource {
  Future<ServerStatusDto> getHealth();
}

class ServerStatusRemoteDataSourceImpl implements ServerStatusRemoteDataSource {
  final DioClient client;

  ServerStatusRemoteDataSourceImpl({required this.client});

  @override
  Future<ServerStatusDto> getHealth() async {
    try {
      final response = await client.dio.get<Map<String, dynamic>>('/health');
      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Respuesta vacía del servidor',
        );
      }
      return ServerStatusDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (e) {
      throw const NetworkFailure();
    }
  }
}

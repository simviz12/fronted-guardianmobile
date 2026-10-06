import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/command_dtos.dart';

abstract class CommandRemoteDataSource {
  Future<CommandDto> sendCommand({
    required String deviceId,
    required String type,
    Map<String, dynamic>? payload,
    int? ttl,
  });

  Future<CommandDto> getCommand(String commandId);

  Future<List<CommandDto>> listDeviceCommands(String deviceId);
}

class CommandRemoteDataSourceImpl implements CommandRemoteDataSource {
  final DioClient _client;

  CommandRemoteDataSourceImpl({required DioClient client}) : _client = client;

  @override
  Future<CommandDto> sendCommand({
    required String deviceId,
    required String type,
    Map<String, dynamic>? payload,
    int? ttl,
  }) async {
    try {
      final body = <String, dynamic>{
        'type': type,
      };
      if (payload != null) body['payload'] = payload;
      if (ttl != null) body['ttl'] = ttl;

      final response = await _client.dio.post(
        '/devices/$deviceId/commands',
        data: body,
      );
      return CommandDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    }
  }

  @override
  Future<CommandDto> getCommand(String commandId) async {
    try {
      final response = await _client.dio.get('/commands/$commandId');
      return CommandDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    }
  }

  @override
  Future<List<CommandDto>> listDeviceCommands(String deviceId) async {
    try {
      final response = await _client.dio.get('/devices/$deviceId/commands');
      final data = response.data;
      final List<dynamic> list;
      if (data is Map<String, dynamic> && data.containsKey('commands')) {
        list = data['commands'] as List<dynamic>;
      } else if (data is List<dynamic>) {
        list = data;
      } else {
        list = [];
      }
      return list.map((item) => CommandDto.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    }
  }
}

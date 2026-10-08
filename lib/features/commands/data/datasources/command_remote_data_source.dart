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

  Future<CommandPageDto> getDeviceCommandsHistory({
    required String deviceId,
    int? limit,
    String? cursor,
    String? status,
    String? type,
  });
}

class CommandPageDto {
  final List<CommandDto> items;
  final String? nextCursor;
  final bool hasMore;

  const CommandPageDto({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  factory CommandPageDto.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final listData = json['commands'] ?? json['items'] ?? json['data'] ?? [];
      final list = (listData as List<dynamic>)
          .map((item) => CommandDto.fromJson(item as Map<String, dynamic>))
          .toList();
      final nextCursor = json['nextCursor'] as String?;
      final hasMore = json['hasMore'] as bool? ?? (nextCursor != null);
      return CommandPageDto(items: list, nextCursor: nextCursor, hasMore: hasMore);
    } else if (json is List<dynamic>) {
      final list = json.map((item) => CommandDto.fromJson(item as Map<String, dynamic>)).toList();
      return CommandPageDto(items: list, nextCursor: null, hasMore: false);
    }
    return const CommandPageDto(items: [], nextCursor: null, hasMore: false);
  }
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

  @override
  Future<CommandPageDto> getDeviceCommandsHistory({
    required String deviceId,
    int? limit,
    String? cursor,
    String? status,
    String? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (cursor != null) queryParams['cursor'] = cursor;
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;

      final response = await _client.dio.get(
        '/devices/$deviceId/commands',
        queryParameters: queryParams,
      );
      return CommandPageDto.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    }
  }
}

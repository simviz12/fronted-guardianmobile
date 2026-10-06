import '../../domain/entities/command.dart';
import '../../domain/entities/command_page.dart';
import '../../domain/repositories/command_repository.dart';
import '../datasources/command_remote_data_source.dart';

class CommandRepositoryImpl implements CommandRepository {
  final CommandRemoteDataSource _remoteDataSource;

  CommandRepositoryImpl({required CommandRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Command> sendCommand({
    required String deviceId,
    required CommandType type,
    Map<String, dynamic>? payload,
    int? ttl,
  }) async {
    final dto = await _remoteDataSource.sendCommand(
      deviceId: deviceId,
      type: type.toContractString(),
      payload: payload,
      ttl: ttl,
    );
    return dto.toEntity();
  }

  @override
  Future<Command> getCommand(String commandId) async {
    final dto = await _remoteDataSource.getCommand(commandId);
    return dto.toEntity();
  }

  @override
  Future<List<Command>> listDeviceCommands(String deviceId) async {
    final dtos = await _remoteDataSource.listDeviceCommands(deviceId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<CommandPage> getDeviceCommandsHistory({
    required String deviceId,
    int? limit,
    String? cursor,
    CommandStatus? status,
    CommandType? type,
  }) async {
    final pageDto = await _remoteDataSource.getDeviceCommandsHistory(
      deviceId: deviceId,
      limit: limit,
      cursor: cursor,
      status: status?.toContractString(),
      type: type?.toContractString(),
    );
    return CommandPage(
      items: pageDto.items.map((dto) => dto.toEntity()).toList(),
      nextCursor: pageDto.nextCursor,
      hasMore: pageDto.hasMore,
    );
  }
}

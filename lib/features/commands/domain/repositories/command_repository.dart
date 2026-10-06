import '../entities/command.dart';
import '../entities/command_page.dart';

abstract class CommandRepository {
  Future<Command> sendCommand({
    required String deviceId,
    required CommandType type,
    Map<String, dynamic>? payload,
    int? ttl,
  });

  Future<Command> getCommand(String commandId);

  Future<List<Command>> listDeviceCommands(String deviceId);

  Future<CommandPage> getDeviceCommandsHistory({
    required String deviceId,
    int? limit,
    String? cursor,
    CommandStatus? status,
    CommandType? type,
  });
}

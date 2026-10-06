import '../entities/command.dart';

abstract class CommandRepository {
  Future<Command> sendCommand({
    required String deviceId,
    required CommandType type,
    Map<String, dynamic>? payload,
    int? ttl,
  });

  Future<Command> getCommand(String commandId);

  Future<List<Command>> listDeviceCommands(String deviceId);
}

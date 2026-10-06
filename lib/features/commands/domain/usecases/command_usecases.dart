import '../entities/command.dart';
import '../repositories/command_repository.dart';

class SendCommandUseCase {
  final CommandRepository _repository;

  SendCommandUseCase(this._repository);

  Future<Command> call({
    required String deviceId,
    required CommandType type,
    Map<String, dynamic>? payload,
    int? ttl,
  }) {
    return _repository.sendCommand(
      deviceId: deviceId,
      type: type,
      payload: payload,
      ttl: ttl,
    );
  }
}

class GetCommandUseCase {
  final CommandRepository _repository;

  GetCommandUseCase(this._repository);

  Future<Command> call(String commandId) {
    return _repository.getCommand(commandId);
  }
}

class ListDeviceCommandsUseCase {
  final CommandRepository _repository;

  ListDeviceCommandsUseCase(this._repository);

  Future<List<Command>> call(String deviceId) {
    return _repository.listDeviceCommands(deviceId);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/commands/domain/entities/command.dart';
import 'package:guardian_mobile/features/commands/domain/repositories/command_repository.dart';
import 'package:guardian_mobile/features/commands/domain/usecases/command_usecases.dart';

class MockCommandRepository implements CommandRepository {
  Command? commandToReturn;
  List<Command> commandListToReturn = [];

  @override
  Future<Command> sendCommand({
    required String deviceId,
    required CommandType type,
    Map<String, dynamic>? payload,
    int? ttl,
  }) async {
    return commandToReturn ??
        Command(
          id: 'cmd-123',
          deviceId: deviceId,
          type: type,
          status: CommandStatus.pending,
          payload: payload ?? {},
          issuedAt: DateTime.now(),
          ttl: ttl ?? 60,
        );
  }

  @override
  Future<Command> getCommand(String commandId) async {
    return commandToReturn ??
        Command(
          id: commandId,
          deviceId: 'dev-1',
          type: CommandType.ring,
          status: CommandStatus.pending,
          payload: {},
          issuedAt: DateTime.now(),
          ttl: 60,
        );
  }

  @override
  Future<List<Command>> listDeviceCommands(String deviceId) async {
    return commandListToReturn;
  }
}

void main() {
  late MockCommandRepository repository;
  late SendCommandUseCase sendCommandUseCase;
  late GetCommandUseCase getCommandUseCase;
  late ListDeviceCommandsUseCase listDeviceCommandsUseCase;

  setUp(() {
    repository = MockCommandRepository();
    sendCommandUseCase = SendCommandUseCase(repository);
    getCommandUseCase = GetCommandUseCase(repository);
    listDeviceCommandsUseCase = ListDeviceCommandsUseCase(repository);
  });

  test('SendCommandUseCase invokes repository.sendCommand and returns Command', () async {
    final command = await sendCommandUseCase(
      deviceId: 'dev-456',
      type: CommandType.ring,
      payload: {'durationSeconds': 30},
    );

    expect(command.deviceId, 'dev-456');
    expect(command.type, CommandType.ring);
    expect(command.status, CommandStatus.pending);
  });

  test('GetCommandUseCase invokes repository.getCommand and returns Command', () async {
    final now = DateTime.now();
    repository.commandToReturn = Command(
      id: 'cmd-999',
      deviceId: 'dev-456',
      type: CommandType.ring,
      status: CommandStatus.executed,
      payload: {'durationSeconds': 30},
      issuedAt: now,
      executedAt: now.add(const Duration(seconds: 1)),
      ttl: 60,
    );

    final command = await getCommandUseCase('cmd-999');

    expect(command.id, 'cmd-999');
    expect(command.status, CommandStatus.executed);
    expect(command.executedAt, isNotNull);
  });

  test('ListDeviceCommandsUseCase invokes repository.listDeviceCommands', () async {
    repository.commandListToReturn = [
      Command(
        id: 'cmd-1',
        deviceId: 'dev-456',
        type: CommandType.ring,
        status: CommandStatus.executed,
        payload: {},
        issuedAt: DateTime.now(),
        ttl: 60,
      ),
    ];

    final commands = await listDeviceCommandsUseCase('dev-456');

    expect(commands.length, 1);
    expect(commands.first.id, 'cmd-1');
  });
}

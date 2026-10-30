import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/commands/domain/entities/command.dart';
import 'package:guardian_mobile/features/commands/presentation/widgets/command_live_status_stepper.dart';

void main() {
  Widget buildWidget(Command command) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: CommandLiveStatusStepper(command: command),
        ),
      ),
    );
  }

  testWidgets('renders all steps with pending state', (tester) async {
    final command = Command(
      id: 'cmd-1',
      deviceId: 'dev-1',
      type: CommandType.ring,
      status: CommandStatus.pending,
      payload: {'durationSeconds': 30},
      issuedAt: DateTime.now(),
      ttl: 60,
    );

    await tester.pumpWidget(buildWidget(command));

    expect(find.text('Enviando orden al dispositivo...'), findsOneWidget);
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('Recibido'), findsOneWidget);
    expect(find.text('Sonando'), findsOneWidget);
  });

  testWidgets('renders delivered state with confirmation message', (tester) async {
    final command = Command(
      id: 'cmd-2',
      deviceId: 'dev-1',
      type: CommandType.ring,
      status: CommandStatus.delivered,
      payload: {'durationSeconds': 30},
      issuedAt: DateTime.now(),
      deliveredAt: DateTime.now(),
      ttl: 60,
    );

    await tester.pumpWidget(buildWidget(command));

    expect(find.text('Orden recibida en el celular'), findsOneWidget);
  });

  testWidgets('renders executed state with completion indicator', (tester) async {
    final command = Command(
      id: 'cmd-3',
      deviceId: 'dev-1',
      type: CommandType.ring,
      status: CommandStatus.executed,
      payload: {'durationSeconds': 30},
      issuedAt: DateTime.now(),
      deliveredAt: DateTime.now(),
      executedAt: DateTime.now(),
      ttl: 60,
    );

    await tester.pumpWidget(buildWidget(command));

    expect(find.text('¡Sonando a máximo volumen!'), findsOneWidget);
  });

  testWidgets('renders failed state with error message', (tester) async {
    final command = Command(
      id: 'cmd-4',
      deviceId: 'dev-1',
      type: CommandType.ring,
      status: CommandStatus.failed,
      payload: {'durationSeconds': 30},
      issuedAt: DateTime.now(),
      failureReason: 'Dispositivo sin permisos de audio',
      ttl: 60,
    );

    await tester.pumpWidget(buildWidget(command));

    expect(find.text('La orden no pudo ejecutarse'), findsOneWidget);
    expect(find.text('Motivo: Dispositivo sin permisos de audio'), findsOneWidget);
    expect(find.text('Falló'), findsOneWidget);
  });

  testWidgets('renders expired state with ttl expiration warning', (tester) async {
    final command = Command(
      id: 'cmd-5',
      deviceId: 'dev-1',
      type: CommandType.ring,
      status: CommandStatus.expired,
      payload: {'durationSeconds': 30},
      issuedAt: DateTime.now(),
      ttl: 60,
    );

    await tester.pumpWidget(buildWidget(command));

    expect(find.text('Orden expirada (sin respuesta)'), findsOneWidget);
    expect(find.text('Expiró'), findsOneWidget);
  });
}

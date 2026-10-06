import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/commands/domain/entities/command.dart';
import 'package:guardian_mobile/features/commands/domain/repositories/command_repository.dart';
import 'package:guardian_mobile/features/commands/presentation/pages/device_detail_page.dart';
import 'package:guardian_mobile/features/commands/presentation/providers/command_provider.dart';
import 'package:guardian_mobile/features/devices/domain/entities/device.dart';
import 'package:mocktail/mocktail.dart';

class MockCommandRepository extends Mock implements CommandRepository {}

void main() {
  late MockCommandRepository mockCommandRepository;

  final protectedDevice = Device(
    id: 'dev-1',
    ownerId: 'owner-1',
    installId: 'inst-1',
    name: 'Pixel 8 Protegido',
    platform: 'android',
    mode: DeviceMode.protected,
    batteryLevel: 85,
    isCharging: false,
    isOnline: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final controllerDevice = Device(
    id: 'dev-2',
    ownerId: 'owner-1',
    installId: 'inst-2',
    name: 'Tablet Controlador',
    platform: 'android',
    mode: DeviceMode.controller,
    batteryLevel: null,
    isCharging: null,
    isOnline: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockCommandRepository = MockCommandRepository();
  });

  Widget buildWidget(Device device) {
    return ProviderScope(
      overrides: [
        commandRepositoryProvider.overrideWithValue(mockCommandRepository),
      ],
      child: MaterialApp(
        home: DeviceDetailPage(device: device),
      ),
    );
  }

  testWidgets('DeviceDetailPage renders header and action tiles', (tester) async {
    await tester.pumpWidget(buildWidget(protectedDevice));

    expect(find.text('Pixel 8 Protegido'), findsWidgets);
    expect(find.text('Hacer sonar'), findsOneWidget);
    expect(find.text('Vibrar'), findsOneWidget);
    expect(find.text('Mensaje'), findsOneWidget);
    expect(find.text('Bloquear'), findsOneWidget);
    expect(find.text('Localizar'), findsOneWidget);
    expect(find.text('Próximamente'), findsNWidgets(2));
  });

  testWidgets('DeviceDetailPage shows confirmation dialog and sends ring command', (tester) async {
    when(() => mockCommandRepository.sendCommand(
          deviceId: 'dev-1',
          type: CommandType.ring,
          payload: any(named: 'payload'),
          ttl: any(named: 'ttl'),
        )).thenAnswer((_) async => Command(
          id: 'cmd-1',
          deviceId: 'dev-1',
          type: CommandType.ring,
          status: CommandStatus.pending,
          payload: {'durationSeconds': 30},
          issuedAt: DateTime.now(),
          ttl: 60,
        ));

    when(() => mockCommandRepository.getCommand('cmd-1')).thenAnswer(
      (_) async => Command(
        id: 'cmd-1',
        deviceId: 'dev-1',
        type: CommandType.ring,
        status: CommandStatus.executed,
        payload: {'durationSeconds': 30},
        issuedAt: DateTime.now(),
        deliveredAt: DateTime.now(),
        executedAt: DateTime.now(),
        ttl: 60,
      ),
    );

    await tester.pumpWidget(buildWidget(protectedDevice));

    // Tap on "Hacer sonar" tile
    await tester.tap(find.text('Hacer sonar'));
    await tester.pumpAndSettle();

    // Verify confirmation modal
    expect(find.text('¿Hacer sonar alarma?'), findsOneWidget);
    expect(find.text('Hacer Sonar'), findsOneWidget);

    // Confirm action
    await tester.tap(find.text('Hacer Sonar'));
    await tester.pump();

    verify(() => mockCommandRepository.sendCommand(
          deviceId: 'dev-1',
          type: CommandType.ring,
          payload: any(named: 'payload'),
          ttl: any(named: 'ttl'),
        )).called(1);
  });

  testWidgets('DeviceDetailPage disables Ring action for non-protected devices', (tester) async {
    await tester.pumpWidget(buildWidget(controllerDevice));

    expect(find.text('Tablet Controlador'), findsWidgets);
    expect(find.text('Solo disponible para dispositivos en modo Protegido'), findsWidgets);

    await tester.tap(find.text('Hacer sonar'));
    await tester.pump();

    // Dialog should NOT appear
    expect(find.text('¿Hacer sonar alarma?'), findsNothing);
  });
}

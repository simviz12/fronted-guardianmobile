import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/commands/domain/entities/command.dart';
import 'package:guardian_mobile/features/commands/domain/entities/command_page.dart';
import 'package:guardian_mobile/features/commands/domain/repositories/command_repository.dart';
import 'package:guardian_mobile/features/commands/presentation/pages/command_history_page.dart';
import 'package:guardian_mobile/features/commands/presentation/providers/command_provider.dart';
import 'package:guardian_mobile/features/devices/domain/entities/device.dart';
import 'package:mocktail/mocktail.dart';

class MockCommandRepository extends Mock implements CommandRepository {}

void main() {
  late MockCommandRepository mockCommandRepository;

  final testDevice = Device(
    id: 'dev-hist-1',
    ownerId: 'owner-1',
    installId: 'inst-1',
    name: 'Pixel 8 de Pruebas',
    platform: 'android',
    mode: DeviceMode.protected,
    batteryLevel: 90,
    isCharging: false,
    isOnline: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockCommandRepository = MockCommandRepository();
  });

  Widget buildWidget() {
    return ProviderScope(
      overrides: [
        commandRepositoryProvider.overrideWithValue(mockCommandRepository),
      ],
      child: MaterialApp(
        home: CommandHistoryPage(device: testDevice),
      ),
    );
  }

  testWidgets('CommandHistoryPage renders empty state when no commands exist', (tester) async {
    when(() => mockCommandRepository.getDeviceCommandsHistory(
          deviceId: 'dev-hist-1',
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
          status: any(named: 'status'),
          type: any(named: 'type'),
        )).thenAnswer((_) async => const CommandPage(
          items: [],
          nextCursor: null,
          hasMore: false,
        ));

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Historial de Órdenes'), findsOneWidget);
    expect(find.text('Sin órdenes registradas'), findsOneWidget);
    expect(find.text('Aún no has emitido ningún comando para este dispositivo.'), findsOneWidget);
  });

  testWidgets('CommandHistoryPage renders command rows with status chips', (tester) async {
    final commands = [
      Command(
        id: 'cmd-ring-1',
        deviceId: 'dev-hist-1',
        type: CommandType.ring,
        status: CommandStatus.executed,
        payload: {'durationSeconds': 30},
        issuedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ttl: 60,
      ),
      Command(
        id: 'cmd-msg-1',
        deviceId: 'dev-hist-1',
        type: CommandType.message,
        status: CommandStatus.delivered,
        payload: {'text': 'Llamar urgente', 'contactPhone': '+573001234567'},
        issuedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        ttl: 300,
      ),
      Command(
        id: 'cmd-vib-1',
        deviceId: 'dev-hist-1',
        type: CommandType.vibrate,
        status: CommandStatus.failed,
        payload: {'durationSeconds': 10},
        failureReason: 'Dispositivo sin motor de vibración',
        issuedAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ttl: 60,
      ),
    ];

    when(() => mockCommandRepository.getDeviceCommandsHistory(
          deviceId: 'dev-hist-1',
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
          status: any(named: 'status'),
          type: any(named: 'type'),
        )).thenAnswer((_) async => CommandPage(
          items: commands,
          nextCursor: null,
          hasMore: false,
        ));

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Alarma Sonora'), findsOneWidget);
    expect(find.text('Mensaje en Pantalla'), findsOneWidget);
    expect(find.text('Vibración Remota'), findsOneWidget);
    expect(find.text('Ejecutado'), findsOneWidget);
    expect(find.text('Entregado'), findsOneWidget);
    expect(find.text('Falló'), findsOneWidget);
    expect(find.text('Motivo de fallo: Dispositivo sin motor de vibración'), findsOneWidget);
  });
}

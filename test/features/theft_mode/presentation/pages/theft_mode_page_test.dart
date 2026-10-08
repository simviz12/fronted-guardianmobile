import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/devices/domain/entities/device.dart';
import 'package:guardian_mobile/features/devices/presentation/providers/devices_provider.dart';
import 'package:guardian_mobile/features/locations/presentation/providers/device_map_provider.dart';
import 'package:guardian_mobile/features/theft_mode/domain/entities/theft_mode_config.dart';
import 'package:guardian_mobile/features/theft_mode/domain/repositories/theft_mode_repository.dart';
import 'package:guardian_mobile/features/theft_mode/presentation/pages/theft_mode_page.dart';
import 'package:guardian_mobile/features/theft_mode/presentation/providers/theft_mode_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockTheftModeRepository extends Mock implements TheftModeRepository {}

void main() {
  late MockTheftModeRepository mockTheftRepo;

  final testDevice = Device(
    id: 'dev-1',
    ownerId: 'user-1',
    installId: 'inst-1',
    name: 'Pixel 8 de Pruebas',
    platform: 'android',
    model: 'Pixel 8',
    osVersion: '14',
    appVersion: '1.0.0',
    mode: DeviceMode.protected,
    batteryLevel: 80,
    isCharging: false,
    isOnline: true,
    adminEnabled: true,
    theftModeActive: false,
    createdAt: DateTime.parse('2026-10-06T00:00:00Z'),
    updatedAt: DateTime.parse('2026-10-06T00:00:00Z'),
  );

  final activeTheftConfig = TheftModeConfig(
    id: 'theft-1',
    deviceId: 'dev-1',
    message: 'Teléfono extraviado. Llamar urgente.',
    contactPhone: '+525512345678',
    locationIntervalSeconds: 60,
    alarm: true,
    lock: true,
    activatedAt: DateTime.parse('2026-10-07T12:00:00Z'),
    deactivatedAt: null,
  );

  setUp(() {
    mockTheftRepo = MockTheftModeRepository();
  });

  Widget buildTheftModePage({TheftModeConfig? initialActive}) {
    when(() => mockTheftRepo.getActiveTheftMode('dev-1'))
        .thenAnswer((_) async => initialActive);

    return ProviderScope(
      overrides: [
        theftModeRepositoryProvider.overrideWithValue(mockTheftRepo),
        devicesNotifierProvider.overrideWith((ref) => DevicesNotifier(ref)),
        deviceMapProvider('dev-1').overrideWith((ref) => DeviceMapNotifier(ref, 'dev-1')),
      ],
      child: MaterialApp(
        home: TheftModePage(device: testDevice),
      ),
    );
  }

  testWidgets('TheftModePage renders inactive form with all inputs and toggles', (tester) async {
    await tester.pumpWidget(buildTheftModePage(initialActive: null));
    await tester.pumpAndSettle();

    expect(find.text('Pixel 8 de Pruebas'), findsOneWidget);
    expect(find.text('INACTIVO'), findsOneWidget);
    expect(find.text('Mensaje para mostrar en pantalla'), findsOneWidget);
    expect(find.text('Teléfono de contacto alternativo (Opcional)'), findsOneWidget);
    expect(find.text('Frecuencia de rastreo de emergencia'), findsOneWidget);
    expect(find.text('Activar alarma sonora'), findsOneWidget);
    expect(find.text('Bloquear pantalla inmediatamente'), findsOneWidget);
    expect(find.text('Activar Modo Robo'), findsOneWidget);
  });

  testWidgets('TheftModePage renders active banner and live measures when theft mode is active', (tester) async {
    await tester.pumpWidget(buildTheftModePage(initialActive: activeTheftConfig));
    await tester.pumpAndSettle();

    expect(find.text('ACTIVO'), findsOneWidget);
    expect(find.text('MODO ROBO / EXTRAVÍO ACTIVADO'), findsOneWidget);
    expect(find.text('Telemetría en Vivo'), findsOneWidget);
    expect(find.text('Pantalla Bloqueada Activa'), findsOneWidget);
    expect(find.text('“Teléfono extraviado. Llamar urgente.”'), findsOneWidget);
    expect(find.text('Contacto: +525512345678'), findsOneWidget);
    expect(find.text('Desactivar Modo Robo'), findsOneWidget);
  });

  testWidgets('TheftModePage shows password dialog when Desactivar is tapped', (tester) async {
    await tester.pumpWidget(buildTheftModePage(initialActive: activeTheftConfig));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Desactivar Modo Robo'));
    await tester.pumpAndSettle();

    expect(find.text('Contraseña de la cuenta'), findsOneWidget);
    expect(find.text('Desactivar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}

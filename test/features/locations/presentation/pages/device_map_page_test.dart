import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/commands/presentation/providers/command_provider.dart';
import 'package:guardian_mobile/features/devices/domain/entities/device.dart';
import 'package:guardian_mobile/features/locations/domain/entities/device_location.dart';
import 'package:guardian_mobile/features/locations/domain/repositories/location_repository.dart';
import 'package:guardian_mobile/features/locations/presentation/pages/device_map_page.dart';
import 'package:guardian_mobile/features/locations/presentation/providers/device_map_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late MockLocationRepository mockLocationRepository;

  final testDevice = Device(
    id: 'dev-1',
    ownerId: 'owner-1',
    installId: 'inst-1',
    name: 'Pixel 8 GPS',
    platform: 'android',
    mode: DeviceMode.protected,
    batteryLevel: 90,
    isOnline: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleLocation = DeviceLocation(
    id: 'loc-1',
    deviceId: 'dev-1',
    latitude: 4.60971,
    longitude: -74.08175,
    accuracyMeters: 5.2,
    speedMps: 0.5,
    recordedAt: DateTime.now(),
    source: LocationSource.locateCommand,
  );

  setUp(() {
    mockLocationRepository = MockLocationRepository();
  });

  Widget buildWidget({DeviceLocation? latestLocation, List<DeviceLocation>? history}) {
    when(() => mockLocationRepository.getLatestLocation(deviceId: 'dev-1'))
        .thenAnswer((_) async {
      if (latestLocation != null) return latestLocation;
      throw Exception('NO_LOCATION_YET');
    });

    when(() => mockLocationRepository.getLocations(
          deviceId: 'dev-1',
          from: any(named: 'from'),
          to: any(named: 'to'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => history ?? []);

    return ProviderScope(
      overrides: [
        locationRepositoryProvider.overrideWithValue(mockLocationRepository),
      ],
      child: MaterialApp(
        home: DeviceMapPage(device: testDevice),
      ),
    );
  }

  testWidgets('DeviceMapPage renders header, controls and empty state when no locations', (tester) async {
    await tester.pumpWidget(buildWidget(latestLocation: null, history: []));
    await tester.pumpAndSettle();

    expect(find.text('Pixel 8 GPS'), findsOneWidget);
    expect(find.text('MAPA DE RASTREO E HISTORIAL'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Ayer'), findsOneWidget);
    expect(find.text('Últimos 7 días'), findsOneWidget);
    expect(find.text('Pedir ubicación ahora'), findsOneWidget);
    expect(find.text('Aún no hay ubicaciones registradas para este periodo.'), findsOneWidget);
  });

  testWidgets('DeviceMapPage renders latest location coordinates and accuracy badge', (tester) async {
    await tester.pumpWidget(buildWidget(latestLocation: sampleLocation, history: [sampleLocation]));
    await tester.pumpAndSettle();

    expect(find.text('4.60971, -74.08175'), findsOneWidget);
    expect(find.text('±5m'), findsOneWidget);
    expect(find.text('1 puntos en historial'), findsOneWidget);
  });
}

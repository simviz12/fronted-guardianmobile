import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/core/error/failures.dart';
import 'package:guardian_mobile/features/auth/domain/entities/user.dart';
import 'package:guardian_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:guardian_mobile/features/devices/domain/entities/device.dart';
import 'package:guardian_mobile/features/devices/domain/repositories/device_repository.dart';
import 'package:guardian_mobile/features/devices/presentation/pages/dashboard_page.dart';
import 'package:guardian_mobile/features/devices/presentation/providers/devices_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockDeviceRepository extends Mock implements DeviceRepository {}

void main() {
  late MockDeviceRepository mockDeviceRepository;

  final testUser = const User(
    id: 'user-1',
    email: 'carlos@example.com',
    displayName: 'Carlos Developer',
  );

  final thisPhone = Device(
    id: 'dev-phone-1',
    ownerId: 'user-1',
    installId: 'inst-1',
    name: 'Pixel 8 de Carlos',
    platform: 'android',
    model: 'Pixel 8',
    osVersion: '14',
    appVersion: '1.0.0',
    mode: DeviceMode.protected,
    batteryLevel: 78,
    isCharging: true,
    isOnline: true,
    createdAt: DateTime.parse('2026-10-06T00:00:00Z'),
    updatedAt: DateTime.parse('2026-10-06T00:00:00Z'),
  );

  final otherDevice = Device(
    id: 'dev-phone-2',
    ownerId: 'user-1',
    installId: 'inst-2',
    name: 'Galaxy Tab S9',
    platform: 'android',
    model: 'SM-X710',
    osVersion: '14',
    appVersion: '1.0.0',
    mode: DeviceMode.controller,
    batteryLevel: null,
    isCharging: null,
    isOnline: false,
    createdAt: DateTime.parse('2026-10-06T00:00:00Z'),
    updatedAt: DateTime.parse('2026-10-06T00:00:00Z'),
  );

  setUp(() {
    mockDeviceRepository = MockDeviceRepository();
  });

  Widget buildDashboardPage() {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          (ref) => _StaticAuthNotifier(
            AuthState.authenticated(testUser),
          ),
        ),
        deviceRepositoryProvider.overrideWithValue(mockDeviceRepository),
      ],
      child: const MaterialApp(
        home: DashboardPage(),
      ),
    );
  }

  testWidgets('DashboardPage shows empty state when user has no linked devices', (tester) async {
    when(() => mockDeviceRepository.listDevices()).thenAnswer((_) async => []);
    when(() => mockDeviceRepository.getThisPhoneDeviceId()).thenAnswer((_) async => null);

    await tester.pumpWidget(buildDashboardPage());
    await tester.pumpAndSettle();

    expect(find.text('Sin dispositivos vinculados'), findsOneWidget);
    expect(find.text('Vincular este Celular'), findsOneWidget);
    expect(find.text('Vincular Celular'), findsOneWidget);
  });

  testWidgets('DashboardPage shows this phone card and list of other devices with exact telemetries', (tester) async {
    when(() => mockDeviceRepository.listDevices()).thenAnswer((_) async => [thisPhone, otherDevice]);
    when(() => mockDeviceRepository.getThisPhoneDeviceId()).thenAnswer((_) async => 'dev-phone-1');

    await tester.pumpWidget(buildDashboardPage());
    await tester.pumpAndSettle();

    expect(find.text('Pixel 8 de Carlos'), findsOneWidget);
    expect(find.text('ESTE TELÉFONO • DISPOSITIVO PRINCIPAL'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('Protegido'), findsOneWidget);
    expect(find.text('En línea'), findsOneWidget);

    expect(find.text('Galaxy Tab S9'), findsOneWidget);
    expect(find.text('Controlador'), findsOneWidget);
    expect(find.text('Desconectado'), findsOneWidget);
    expect(find.text('Sin datos'), findsNWidgets(1)); // Galaxy Tab has null battery
  });

  testWidgets('DashboardPage shows error state with retry button on network failure', (tester) async {
    when(() => mockDeviceRepository.listDevices()).thenThrow(const NetworkFailure());
    when(() => mockDeviceRepository.getThisPhoneDeviceId()).thenAnswer((_) async => null);

    await tester.pumpWidget(buildDashboardPage());
    await tester.pumpAndSettle();

    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}

class _StaticAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _StaticAuthNotifier(super.state);

  @override
  void clearError() {}

  @override
  Future<bool> login({required String email, required String password}) async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> register({required String email, required String password, required String displayName}) async => true;

  @override
  Future<void> restoreSession() async {}

  @override
  void cancelTwoFactorLogin() {}

  @override
  void updateUser(User user) {}

  @override
  Future<bool> verifyTwoFactorLogin({required String code}) async => true;
}

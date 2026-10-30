import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/devices/data/datasources/device_identity_service.dart';
import 'package:guardian_mobile/features/devices/domain/entities/device.dart';
import 'package:guardian_mobile/features/devices/domain/repositories/device_repository.dart';
import 'package:guardian_mobile/features/devices/presentation/pages/link_device_page.dart';
import 'package:guardian_mobile/features/devices/presentation/providers/devices_provider.dart';
import 'package:guardian_mobile/core/network/fcm_notification_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDeviceRepository extends Mock implements DeviceRepository {}
class MockFcmNotificationService extends Mock implements FcmNotificationService {}

void main() {
  late MockDeviceRepository mockDeviceRepository;
  late MockFcmNotificationService mockFcmService;

  const sampleInstallInfo = DeviceInstallInfo(
    installId: 'test-install-123',
    suggestedName: 'Pixel 8 Pro',
    platform: 'android',
    model: 'Pixel 8 Pro',
    osVersion: '14',
    appVersion: '1.0.0',
  );

  setUpAll(() {
    registerFallbackValue(DeviceMode.protected);
  });

  setUp(() {
    mockDeviceRepository = MockDeviceRepository();
    mockFcmService = MockFcmNotificationService();
    when(() => mockFcmService.getFcmToken()).thenAnswer((_) async => 'fake-fcm-token');
  });

  Widget buildLinkDevicePage() {
    return ProviderScope(
      overrides: [
        deviceInstallInfoProvider.overrideWith((ref) async => sampleInstallInfo),
        deviceRepositoryProvider.overrideWithValue(mockDeviceRepository),
        fcmNotificationServiceProvider.overrideWithValue(mockFcmService),
      ],
      child: const MaterialApp(
        home: LinkDevicePage(),
      ),
    );
  }

  testWidgets('LinkDevicePage renders pre-filled suggested name, mode options and submits', (tester) async {
    final linkedResult = LinkedDeviceResult(
      device: Device(
        id: 'new-dev-1',
        ownerId: 'owner-1',
        installId: 'test-install-123',
        name: 'Pixel 8 Pro',
        platform: 'android',
        mode: DeviceMode.protected,
        isOnline: true,
        createdAt: DateTime.parse('2026-10-06T00:00:00Z'),
        updatedAt: DateTime.parse('2026-10-06T00:00:00Z'),
      ),
      deviceToken: 'token-xyz',
    );

    when(
      () => mockDeviceRepository.linkCurrentDevice(
        name: any(named: 'name'),
        mode: any(named: 'mode'),
        fcmToken: any(named: 'fcmToken'),
      ),
    ).thenAnswer((_) async => linkedResult);

    when(() => mockDeviceRepository.listDevices()).thenAnswer((_) async => [linkedResult.device]);
    when(() => mockDeviceRepository.getThisPhoneDeviceId()).thenAnswer((_) async => 'new-dev-1');

    await tester.pumpWidget(buildLinkDevicePage());
    await tester.pumpAndSettle();

    expect(find.text('Vincular este Celular'), findsOneWidget);
    expect(find.text('Pixel 8 Pro'), findsOneWidget);
    expect(find.text('Dispositivo protegido'), findsOneWidget);
    expect(find.text('Controlador'), findsOneWidget);

    await tester.tap(find.text('Completar Vinculación'));
    await tester.pumpAndSettle();

    verify(
      () => mockDeviceRepository.linkCurrentDevice(
        name: 'Pixel 8 Pro',
        mode: DeviceMode.protected,
        fcmToken: 'fake-fcm-token',
      ),
    ).called(1);
  });
}

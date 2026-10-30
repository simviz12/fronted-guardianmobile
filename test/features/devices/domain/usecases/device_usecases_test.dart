import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/devices/domain/entities/device.dart';
import 'package:guardian_mobile/features/devices/domain/repositories/device_repository.dart';
import 'package:guardian_mobile/features/devices/domain/usecases/device_usecases.dart';
import 'package:mocktail/mocktail.dart';

class MockDeviceRepository extends Mock implements DeviceRepository {}

void main() {
  late MockDeviceRepository repository;

  setUpAll(() {
    registerFallbackValue(DeviceMode.protected);
  });

  final testDevice = Device(
    id: 'device-123',
    ownerId: 'owner-456',
    installId: 'install-uuid-789',
    name: 'Pixel 8 de Gabriel',
    platform: 'android',
    model: 'Pixel 8',
    osVersion: '14',
    appVersion: '1.0.0',
    mode: DeviceMode.protected,
    batteryLevel: 85,
    isCharging: true,
    isOnline: true,
    createdAt: DateTime.parse('2026-10-06T00:00:00Z'),
    updatedAt: DateTime.parse('2026-10-06T00:00:00Z'),
  );

  setUp(() {
    repository = MockDeviceRepository();
  });

  group('Device Use Cases', () {
    test('LinkCurrentDeviceUseCase calls repository.linkCurrentDevice', () async {
      final useCase = LinkCurrentDeviceUseCase(repository);
      final expectedResult = LinkedDeviceResult(
        device: testDevice,
        deviceToken: 'token-abc',
      );

      when(
        () => repository.linkCurrentDevice(
          name: any(named: 'name'),
          mode: any(named: 'mode'),
          fcmToken: any(named: 'fcmToken'),
        ),
      ).thenAnswer((_) async => expectedResult);

      final result = await useCase(
        name: 'Pixel 8 de Gabriel',
        mode: DeviceMode.protected,
      );

      expect(result.device.id, 'device-123');
      expect(result.deviceToken, 'token-abc');
      verify(
        () => repository.linkCurrentDevice(
          name: 'Pixel 8 de Gabriel',
          mode: DeviceMode.protected,
          fcmToken: null,
        ),
      ).called(1);
    });

    test('ListDevicesUseCase calls repository.listDevices', () async {
      final useCase = ListDevicesUseCase(repository);

      when(() => repository.listDevices()).thenAnswer((_) async => [testDevice]);

      final result = await useCase();

      expect(result.length, 1);
      expect(result.first.name, 'Pixel 8 de Gabriel');
      verify(() => repository.listDevices()).called(1);
    });

    test('RenameDeviceUseCase calls repository.renameDevice', () async {
      final useCase = RenameDeviceUseCase(repository);
      final renamed = Device(
        id: testDevice.id,
        ownerId: testDevice.ownerId,
        installId: testDevice.installId,
        name: 'Nuevo Nombre',
        platform: testDevice.platform,
        mode: testDevice.mode,
        isOnline: testDevice.isOnline,
        createdAt: testDevice.createdAt,
        updatedAt: testDevice.updatedAt,
      );

      when(
        () => repository.renameDevice(
          id: 'device-123',
          name: 'Nuevo Nombre',
        ),
      ).thenAnswer((_) async => renamed);

      final result = await useCase(id: 'device-123', name: 'Nuevo Nombre');

      expect(result.name, 'Nuevo Nombre');
      verify(
        () => repository.renameDevice(
          id: 'device-123',
          name: 'Nuevo Nombre',
          fcmToken: null,
        ),
      ).called(1);
    });

    test('UnlinkDeviceUseCase calls repository.unlinkDevice', () async {
      final useCase = UnlinkDeviceUseCase(repository);

      when(() => repository.unlinkDevice('device-123')).thenAnswer((_) async {});

      await useCase('device-123');

      verify(() => repository.unlinkDevice('device-123')).called(1);
    });

    test('GetThisPhoneDeviceIdUseCase calls repository.getThisPhoneDeviceId', () async {
      final useCase = GetThisPhoneDeviceIdUseCase(repository);

      when(() => repository.getThisPhoneDeviceId()).thenAnswer((_) async => 'device-123');

      final result = await useCase();

      expect(result, 'device-123');
      verify(() => repository.getThisPhoneDeviceId()).called(1);
    });
  });
}

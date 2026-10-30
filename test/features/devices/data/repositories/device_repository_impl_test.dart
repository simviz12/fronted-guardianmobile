import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/devices/data/datasources/device_identity_service.dart';
import 'package:guardian_mobile/features/devices/data/datasources/device_remote_data_source.dart';
import 'package:guardian_mobile/features/devices/data/models/device_dtos.dart';
import 'package:guardian_mobile/features/devices/data/repositories/device_repository_impl.dart';
import 'package:guardian_mobile/features/devices/domain/entities/device.dart';
import 'package:mocktail/mocktail.dart';

class MockDeviceRemoteDataSource extends Mock implements DeviceRemoteDataSource {}
class MockDeviceIdentityService extends Mock implements DeviceIdentityService {}

void main() {
  late MockDeviceRemoteDataSource mockRemoteDataSource;
  late MockDeviceIdentityService mockIdentityService;
  late DeviceRepositoryImpl repository;

  const testDeviceDto = DeviceDto(
    id: 'device-123',
    ownerId: 'owner-456',
    installId: 'install-uuid-789',
    name: 'Pixel 8',
    platform: 'android',
    model: 'Pixel 8',
    osVersion: '14',
    appVersion: '1.0.0',
    mode: 'PROTECTED',
    batteryLevel: 90,
    isCharging: false,
    isOnline: true,
    createdAt: '2026-10-06T00:00:00Z',
    updatedAt: '2026-10-06T00:00:00Z',
  );

  setUp(() {
    mockRemoteDataSource = MockDeviceRemoteDataSource();
    mockIdentityService = MockDeviceIdentityService();
    repository = DeviceRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      identityService: mockIdentityService,
    );
  });

  group('DeviceRepositoryImpl', () {
    test('linkCurrentDevice fetches identity info, calls remote, saves token and this phone id', () async {
      const installInfo = DeviceInstallInfo(
        installId: 'install-uuid-789',
        suggestedName: 'Pixel 8',
        platform: 'android',
        model: 'Pixel 8',
        osVersion: '14',
        appVersion: '1.0.0',
      );

      const responseDto = LinkDeviceResponseDto(
        device: testDeviceDto,
        deviceToken: 'secret-device-token-123',
      );

      when(() => mockIdentityService.getInstallInfo()).thenAnswer((_) async => installInfo);
      when(
        () => mockRemoteDataSource.linkDevice(
          installId: 'install-uuid-789',
          name: 'Pixel 8',
          platform: 'android',
          model: 'Pixel 8',
          osVersion: '14',
          appVersion: '1.0.0',
          mode: 'PROTECTED',
          fcmToken: null,
        ),
      ).thenAnswer((_) async => responseDto);

      when(
        () => mockIdentityService.saveDeviceToken(
          deviceId: 'device-123',
          token: 'secret-device-token-123',
        ),
      ).thenAnswer((_) async {});

      when(() => mockIdentityService.saveThisPhoneDeviceId('device-123'))
          .thenAnswer((_) async {});

      final result = await repository.linkCurrentDevice(
        name: 'Pixel 8',
        mode: DeviceMode.protected,
      );

      expect(result.device.id, 'device-123');
      expect(result.deviceToken, 'secret-device-token-123');
      verify(
        () => mockIdentityService.saveDeviceToken(
          deviceId: 'device-123',
          token: 'secret-device-token-123',
        ),
      ).called(1);
      verify(() => mockIdentityService.saveThisPhoneDeviceId('device-123')).called(1);
    });

    test('listDevices calls remote and returns entity list', () async {
      const listResponse = DevicesListResponseDto(devices: [testDeviceDto]);
      when(() => mockRemoteDataSource.listDevices()).thenAnswer((_) async => listResponse);

      final result = await repository.listDevices();

      expect(result.length, 1);
      expect(result.first.name, 'Pixel 8');
      expect(result.first.mode, DeviceMode.protected);
    });

    test('unlinkDevice cleans up stored deviceToken and identity if it is this phone', () async {
      when(() => mockRemoteDataSource.deleteDevice('device-123')).thenAnswer((_) async {});
      when(() => mockIdentityService.getThisPhoneDeviceId()).thenAnswer((_) async => 'device-123');
      when(() => mockIdentityService.clearDeviceToken('device-123')).thenAnswer((_) async {});
      when(() => mockIdentityService.clearThisPhoneIdentity()).thenAnswer((_) async {});

      await repository.unlinkDevice('device-123');

      verify(() => mockRemoteDataSource.deleteDevice('device-123')).called(1);
      verify(() => mockIdentityService.clearDeviceToken('device-123')).called(1);
      verify(() => mockIdentityService.clearThisPhoneIdentity()).called(1);
    });
  });
}

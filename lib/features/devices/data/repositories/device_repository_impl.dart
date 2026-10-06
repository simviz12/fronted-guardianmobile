import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/device_identity_service.dart';
import '../datasources/device_remote_data_source.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceRemoteDataSource _remoteDataSource;
  final DeviceIdentityService _identityService;

  DeviceRepositoryImpl({
    required DeviceRemoteDataSource remoteDataSource,
    required DeviceIdentityService identityService,
  })  : _remoteDataSource = remoteDataSource,
        _identityService = identityService;

  @override
  Future<LinkedDeviceResult> linkCurrentDevice({
    required String name,
    required DeviceMode mode,
    String? fcmToken,
  }) async {
    final info = await _identityService.getInstallInfo();
    final responseDto = await _remoteDataSource.linkDevice(
      installId: info.installId,
      name: name,
      platform: info.platform,
      model: info.model,
      osVersion: info.osVersion,
      appVersion: info.appVersion,
      mode: mode.toContractString(),
      fcmToken: fcmToken,
    );

    final result = responseDto.toEntity();

    // Store deviceToken securely (key per device) & remember this phone
    await _identityService.saveDeviceToken(
      deviceId: result.device.id,
      token: result.deviceToken,
    );
    await _identityService.saveThisPhoneDeviceId(result.device.id);

    return result;
  }

  @override
  Future<List<Device>> listDevices() async {
    final responseDto = await _remoteDataSource.listDevices();
    return responseDto.toEntities();
  }

  @override
  Future<Device> getDeviceById(String id) async {
    final dto = await _remoteDataSource.getDeviceById(id);
    return dto.toEntity();
  }

  @override
  Future<Device> renameDevice({
    required String id,
    required String name,
    String? fcmToken,
  }) async {
    final dto = await _remoteDataSource.updateDevice(
      id: id,
      name: name,
      fcmToken: fcmToken,
    );
    return dto.toEntity();
  }

  @override
  Future<void> unlinkDevice(String id) async {
    await _remoteDataSource.deleteDevice(id);

    // If unlinked device is this phone, clear its stored deviceToken and identity
    final thisPhoneId = await _identityService.getThisPhoneDeviceId();
    if (thisPhoneId == id) {
      await _identityService.clearDeviceToken(id);
      await _identityService.clearThisPhoneIdentity();
    } else {
      await _identityService.clearDeviceToken(id);
    }
  }

  @override
  Future<String?> getThisPhoneDeviceId() {
    return _identityService.getThisPhoneDeviceId();
  }

  @override
  Future<String?> getDeviceToken(String deviceId) {
    return _identityService.getDeviceToken(deviceId);
  }
}

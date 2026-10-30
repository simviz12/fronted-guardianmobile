import '../../../../core/config/api_config.dart';
import '../../../../core/network/native_bridge_service.dart';
import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/device_identity_service.dart';
import '../datasources/device_remote_data_source.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceRemoteDataSource _remoteDataSource;
  final DeviceIdentityService _identityService;
  final NativeBridgeService _nativeBridgeService;

  DeviceRepositoryImpl({
    required DeviceRemoteDataSource remoteDataSource,
    required DeviceIdentityService identityService,
    NativeBridgeService? nativeBridgeService,
  })  : _remoteDataSource = remoteDataSource,
        _identityService = identityService,
        _nativeBridgeService = nativeBridgeService ?? NativeBridgeServiceImpl();

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

    // Sync to native Android EncryptedSharedPreferences for background daemon
    await _nativeBridgeService.saveDeviceCredentials(
      apiBaseUrl: ApiConfig.baseUrl,
      deviceId: result.device.id,
      deviceToken: result.deviceToken,
    );

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
  Future<void> updateFcmToken({
    required String id,
    required String fcmToken,
  }) async {
    await _remoteDataSource.updateDevice(
      id: id,
      fcmToken: fcmToken,
    );
  }

  @override
  Future<void> unlinkDevice(String id) async {
    await _remoteDataSource.deleteDevice(id);

    // If unlinked device is this phone, clear its stored deviceToken, identity and native credentials
    final thisPhoneId = await _identityService.getThisPhoneDeviceId();
    if (thisPhoneId == id) {
      await _identityService.clearDeviceToken(id);
      await _identityService.clearThisPhoneIdentity();
      await _nativeBridgeService.clearDeviceCredentials();
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

  @override
  Future<dynamic> getDeviceDiagnostics(String id) {
    return _remoteDataSource.getDeviceDiagnostics(id);
  }
}

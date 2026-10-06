import '../entities/device.dart';

abstract class DeviceRepository {
  Future<LinkedDeviceResult> linkCurrentDevice({
    required String name,
    required DeviceMode mode,
    String? fcmToken,
  });

  Future<List<Device>> listDevices();

  Future<Device> getDeviceById(String id);

  Future<Device> renameDevice({
    required String id,
    required String name,
    String? fcmToken,
  });

  Future<void> unlinkDevice(String id);

  Future<String?> getThisPhoneDeviceId();

  Future<String?> getDeviceToken(String deviceId);
}

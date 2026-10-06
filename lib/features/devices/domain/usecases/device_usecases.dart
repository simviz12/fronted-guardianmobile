import '../entities/device.dart';
import '../repositories/device_repository.dart';

class LinkCurrentDeviceUseCase {
  final DeviceRepository _repository;

  LinkCurrentDeviceUseCase(this._repository);

  Future<LinkedDeviceResult> call({
    required String name,
    required DeviceMode mode,
    String? fcmToken,
  }) {
    return _repository.linkCurrentDevice(
      name: name,
      mode: mode,
      fcmToken: fcmToken,
    );
  }
}

class ListDevicesUseCase {
  final DeviceRepository _repository;

  ListDevicesUseCase(this._repository);

  Future<List<Device>> call() {
    return _repository.listDevices();
  }
}

class RenameDeviceUseCase {
  final DeviceRepository _repository;

  RenameDeviceUseCase(this._repository);

  Future<Device> call({
    required String id,
    required String name,
    String? fcmToken,
  }) {
    return _repository.renameDevice(
      id: id,
      name: name,
      fcmToken: fcmToken,
    );
  }
}

class UnlinkDeviceUseCase {
  final DeviceRepository _repository;

  UnlinkDeviceUseCase(this._repository);

  Future<void> call(String id) {
    return _repository.unlinkDevice(id);
  }
}

class GetThisPhoneDeviceIdUseCase {
  final DeviceRepository _repository;

  GetThisPhoneDeviceIdUseCase(this._repository);

  Future<String?> call() {
    return _repository.getThisPhoneDeviceId();
  }
}

import '../repositories/wipe_repository.dart';

class WipeDeviceUseCase {
  final WipeRepository _repository;

  WipeDeviceUseCase(this._repository);

  Future<void> call({
    required String deviceId,
    required String password,
    String confirmationText = 'BORRAR',
    String? twoFactorCode,
  }) {
    return _repository.wipeDevice(
      deviceId: deviceId,
      password: password,
      confirmationText: confirmationText,
      twoFactorCode: twoFactorCode,
    );
  }
}

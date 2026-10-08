import '../entities/theft_mode_config.dart';
import '../repositories/theft_mode_repository.dart';

class ActivateTheftModeUseCase {
  final TheftModeRepository _repository;

  ActivateTheftModeUseCase(this._repository);

  Future<TheftModeConfig> call({
    required String deviceId,
    required String message,
    String? contactPhone,
    required int locationIntervalSeconds,
    required bool alarm,
    required bool lock,
  }) {
    return _repository.activateTheftMode(
      deviceId: deviceId,
      message: message,
      contactPhone: contactPhone,
      locationIntervalSeconds: locationIntervalSeconds,
      alarm: alarm,
      lock: lock,
    );
  }
}

class GetActiveTheftModeUseCase {
  final TheftModeRepository _repository;

  GetActiveTheftModeUseCase(this._repository);

  Future<TheftModeConfig?> call(String deviceId) {
    return _repository.getActiveTheftMode(deviceId);
  }
}

class GetTheftModeHistoryUseCase {
  final TheftModeRepository _repository;

  GetTheftModeHistoryUseCase(this._repository);

  Future<List<TheftModeConfig>> call(String deviceId) {
    return _repository.getTheftModeHistory(deviceId);
  }
}

class DeactivateTheftModeUseCase {
  final TheftModeRepository _repository;

  DeactivateTheftModeUseCase(this._repository);

  Future<void> call({
    required String deviceId,
    required String password,
    bool force = false,
    String? twoFactorCode,
  }) {
    return _repository.deactivateTheftMode(
      deviceId: deviceId,
      password: password,
      force: force,
      twoFactorCode: twoFactorCode,
    );
  }
}

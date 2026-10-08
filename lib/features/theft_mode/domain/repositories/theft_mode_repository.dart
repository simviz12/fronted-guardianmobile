import 'package:guardian_mobile/features/theft_mode/domain/entities/theft_mode_config.dart';

abstract class TheftModeRepository {
  Future<TheftModeConfig> activateTheftMode({
    required String deviceId,
    required String message,
    String? contactPhone,
    required int locationIntervalSeconds,
    required bool alarm,
    required bool lock,
  });

  Future<TheftModeConfig?> getActiveTheftMode(String deviceId);

  Future<List<TheftModeConfig>> getTheftModeHistory(String deviceId);

  Future<void> deactivateTheftMode({
    required String deviceId,
    required String password,
    bool force = false,
  });
}

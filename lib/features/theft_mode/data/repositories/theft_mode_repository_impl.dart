import 'package:guardian_mobile/features/theft_mode/data/datasources/theft_mode_remote_data_source.dart';
import 'package:guardian_mobile/features/theft_mode/domain/entities/theft_mode_config.dart';
import 'package:guardian_mobile/features/theft_mode/domain/repositories/theft_mode_repository.dart';

class TheftModeRepositoryImpl implements TheftModeRepository {
  final TheftModeRemoteDataSource _remoteDataSource;

  TheftModeRepositoryImpl({required TheftModeRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<TheftModeConfig> activateTheftMode({
    required String deviceId,
    required String message,
    String? contactPhone,
    required int locationIntervalSeconds,
    required bool alarm,
    required bool lock,
  }) async {
    final dto = await _remoteDataSource.activateTheftMode(
      deviceId: deviceId,
      message: message,
      contactPhone: contactPhone,
      locationIntervalSeconds: locationIntervalSeconds,
      alarm: alarm,
      lock: lock,
    );
    return dto.toEntity();
  }

  @override
  Future<TheftModeConfig?> getActiveTheftMode(String deviceId) async {
    final dto = await _remoteDataSource.getActiveTheftMode(deviceId);
    return dto?.toEntity();
  }

  @override
  Future<List<TheftModeConfig>> getTheftModeHistory(String deviceId) async {
    final dtos = await _remoteDataSource.getTheftModeHistory(deviceId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<void> deactivateTheftMode({
    required String deviceId,
    required String password,
    bool force = false,
  }) {
    return _remoteDataSource.deactivateTheftMode(
      deviceId: deviceId,
      password: password,
      force: force,
    );
  }
}

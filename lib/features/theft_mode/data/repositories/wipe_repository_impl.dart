import 'package:guardian_mobile/features/theft_mode/data/datasources/wipe_remote_data_source.dart';
import 'package:guardian_mobile/features/theft_mode/domain/repositories/wipe_repository.dart';

class WipeRepositoryImpl implements WipeRepository {
  final WipeRemoteDataSource _remoteDataSource;

  WipeRepositoryImpl({required WipeRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<void> wipeDevice({
    required String deviceId,
    required String password,
    String confirmationText = 'BORRAR',
    String? twoFactorCode,
  }) async {
    await _remoteDataSource.wipeDevice(
      deviceId: deviceId,
      password: password,
      confirmationText: confirmationText,
      twoFactorCode: twoFactorCode,
    );
  }
}

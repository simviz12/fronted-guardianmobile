import '../../../../core/network/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
  });

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final responseDto = await remoteDataSource.register(
      email: email,
      password: password,
      displayName: displayName,
    );

    await tokenStorage.saveTokens(
      accessToken: responseDto.accessToken,
      refreshToken: responseDto.refreshToken,
    );

    return responseDto.toEntity();
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final responseDto = await remoteDataSource.login(
      email: email,
      password: password,
    );

    await tokenStorage.saveTokens(
      accessToken: responseDto.accessToken,
      refreshToken: responseDto.refreshToken,
    );

    return responseDto.toEntity();
  }

  @override
  Future<void> logout() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await remoteDataSource.logout(refreshToken: refreshToken);
      } catch (_) {
        // Even if remote logout fails (e.g. offline/network), locally wipe session
      }
    }
    await tokenStorage.clearTokens();
  }

  @override
  Future<User> getCurrentUser() async {
    final userDto = await remoteDataSource.getMe();
    return userDto.toEntity();
  }

  @override
  Future<User?> restoreSession() async {
    final accessToken = await tokenStorage.getAccessToken();
    final refreshToken = await tokenStorage.getRefreshToken();

    if (accessToken == null && refreshToken == null) {
      return null;
    }

    try {
      final userDto = await remoteDataSource.getMe();
      return userDto.toEntity();
    } catch (_) {
      // If session is completely invalid, clear storage
      await tokenStorage.clearTokens();
      return null;
    }
  }
}

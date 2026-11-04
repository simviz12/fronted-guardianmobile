import '../../../../core/error/failures.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/storage/user_cache.dart';
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

    final session = responseDto.toEntity();
    await UserCache.save(session.user);
    return session;
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

    final session = responseDto.toEntity();
    await UserCache.save(session.user);
    return session;
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
    await UserCache.clear();
  }

  @override
  Future<User> getCurrentUser() async {
    final userDto = await remoteDataSource.getMe();
    final user = userDto.toEntity();
    await UserCache.save(user);
    return user;
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
      final user = userDto.toEntity();
      await UserCache.save(user);
      return user;
    } catch (e) {
      // Only a definitive auth rejection invalidates the stored session.
      // (The interceptor already tried to refresh before this point.)
      final isAuthRejection = e is ServerFailure &&
          (e.statusCode == 401 || e.statusCode == 403);
      if (isAuthRejection) {
        await tokenStorage.clearTokens();
        await UserCache.clear();
        return null;
      }

      // Offline, timeout or Render cold start: keep the tokens and open the
      // app with the last known profile; requests recover once online.
      final cached = await UserCache.read();
      if (cached != null) return cached;
      return null;
    }
  }
}

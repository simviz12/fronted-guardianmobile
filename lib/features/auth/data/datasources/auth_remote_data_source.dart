import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_dtos.dart';

/// Special exception thrown when login requires 2FA step.
class TwoFactorRequiredException implements Exception {
  final String twoFactorToken;
  const TwoFactorRequiredException(this.twoFactorToken);
}

abstract interface class AuthRemoteDataSource {
  Future<AuthResponseDto> register({
    required String email,
    required String password,
    required String displayName,
  });

  /// Throws [TwoFactorRequiredException] if account has 2FA enabled.
  Future<AuthResponseDto> login({
    required String email,
    required String password,
  });

  Future<TokenRefreshResponseDto> refreshToken({
    required String refreshToken,
  });

  Future<void> logout({
    required String refreshToken,
  });

  Future<UserDto> getMe();

  // --- 2FA ---
  Future<TwoFactorSetupDto> setup2FA();
  Future<TwoFactorEnableResultDto> enable2FA({required String token});
  Future<void> disable2FA({required String password, required String twoFactorCode});
  Future<AuthResponseDto> verifyTwoFactorLogin({
    required String twoFactorToken,
    required String code,
  });

  // --- Sessions ---
  Future<List<ActiveSessionDto>> getSessions();
  Future<void> revokeSession({required String sessionId});
  Future<void> logoutAll();

  // --- Account ---
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<AuthResponseDto> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await client.dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );
      return AuthResponseDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  @override
  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      final data = response.data!;
      // Detect 2FA pending response
      if (data['requiresTwoFactor'] == true) {
        throw TwoFactorRequiredException(data['twoFactorToken'] as String? ?? '');
      }
      return AuthResponseDto.fromJson(data);
    } on TwoFactorRequiredException {
      rethrow;
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is TwoFactorRequiredException) rethrow;
      throw const NetworkFailure();
    }
  }

  @override
  Future<TokenRefreshResponseDto> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await client.dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return TokenRefreshResponseDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  @override
  Future<void> logout({
    required String refreshToken,
  }) async {
    try {
      await client.dio.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  @override
  Future<UserDto> getMe() async {
    try {
      final response = await client.dio.get<Map<String, dynamic>>('/auth/me');
      return UserDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  // --- 2FA ---

  @override
  Future<TwoFactorSetupDto> setup2FA() async {
    try {
      final response = await client.dio.post<Map<String, dynamic>>('/auth/2fa/setup');
      return TwoFactorSetupDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  @override
  Future<TwoFactorEnableResultDto> enable2FA({required String token}) async {
    try {
      final response = await client.dio.post<Map<String, dynamic>>(
        '/auth/2fa/enable',
        data: {'token': token},
      );
      return TwoFactorEnableResultDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  @override
  Future<void> disable2FA({required String password, required String twoFactorCode}) async {
    try {
      await client.dio.post(
        '/auth/2fa/disable',
        data: {'password': password, 'twoFactorCode': twoFactorCode},
      );
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  @override
  Future<AuthResponseDto> verifyTwoFactorLogin({
    required String twoFactorToken,
    required String code,
  }) async {
    try {
      final response = await client.dio.post<Map<String, dynamic>>(
        '/auth/2fa/verify',
        data: {'twoFactorToken': twoFactorToken, 'code': code},
      );
      return AuthResponseDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  // --- Sessions ---

  @override
  Future<List<ActiveSessionDto>> getSessions() async {
    try {
      final response = await client.dio.get<List<dynamic>>('/auth/sessions');
      final list = response.data ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ActiveSessionDto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  @override
  Future<void> revokeSession({required String sessionId}) async {
    try {
      await client.dio.delete('/auth/sessions/$sessionId');
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  @override
  Future<void> logoutAll() async {
    try {
      await client.dio.post('/auth/logout-all');
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  // --- Account ---

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await client.dio.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (_) {
      throw const NetworkFailure();
    }
  }
}

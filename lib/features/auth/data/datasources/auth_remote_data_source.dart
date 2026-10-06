import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_dtos.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthResponseDto> register({
    required String email,
    required String password,
    required String displayName,
  });

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
      return AuthResponseDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw DioClient.mapDioExceptionToFailure(e);
    } catch (_) {
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
}

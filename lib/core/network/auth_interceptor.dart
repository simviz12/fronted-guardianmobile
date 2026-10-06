import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'token_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage tokenStorage;
  final Dio dio;
  final void Function()? onSessionTerminated;

  AuthInterceptor({
    required this.tokenStorage,
    required this.dio,
    this.onSessionTerminated,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Avoid attaching header for public endpoints or refresh calls
    final path = options.path;
    final isPublic = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/health');

    if (!isPublic) {
      final token = await tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final statusCode = response?.statusCode;

    // Check if error is 401 with ACCESS_TOKEN_EXPIRED
    final isTokenExpired = statusCode == 401 && _isAccessTokenExpired(response?.data);

    // If not token expiration, or request is already auth refresh, forward error
    if (!isTokenExpired || err.requestOptions.path.contains('/auth/refresh')) {
      return handler.next(err);
    }

    // Attempt token refresh
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _handleSessionExpired();
      return handler.next(err);
    }

    try {
      // Use dedicated unintercepted Dio instance to call /auth/refresh
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: {'Accept': 'application/json'},
        ),
      );

      final refreshResponse = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
        final data = refreshResponse.data!;
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;

        await tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Retry original request with new token
        final requestOptions = err.requestOptions;
        requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await dio.fetch(requestOptions);
        return handler.resolve(retryResponse);
      } else {
        await _handleSessionExpired();
        return handler.next(err);
      }
    } on DioException catch (refreshErr) {
      final refreshData = refreshErr.response?.data;
      if (refreshData is Map<String, dynamic> &&
          refreshData['error'] is Map<String, dynamic>) {
        final code = (refreshData['error'] as Map<String, dynamic>)['code'];
        if (code == 'REFRESH_TOKEN_REUSED' ||
            code == 'REFRESH_TOKEN_EXPIRED' ||
            code == 'REFRESH_TOKEN_INVALID') {
          await _handleSessionExpired();
        }
      } else {
        await _handleSessionExpired();
      }
      return handler.next(err);
    } catch (_) {
      await _handleSessionExpired();
      return handler.next(err);
    }
  }

  bool _isAccessTokenExpired(dynamic data) {
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      final code = (data['error'] as Map<String, dynamic>)['code'];
      return code == 'ACCESS_TOKEN_EXPIRED';
    }
    return false;
  }

  Future<void> _handleSessionExpired() async {
    await tokenStorage.clearTokens();
    onSessionTerminated?.call();
  }
}

import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'token_storage.dart';

/// Attaches the user access token and transparently rotates it on expiry.
///
/// Extends [QueuedInterceptor], so concurrent 401s are processed one at a
/// time: the first one refreshes, the rest detect that the stored token
/// already changed and simply retry with it (no duplicate refresh calls,
/// which the backend would treat as refresh-token reuse).
class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage tokenStorage;
  final Dio dio;
  final void Function()? onSessionTerminated;
  final Dio Function()? refreshDioFactory;

  static const _retriedFlag = '__auth_retried';

  static const _terminalRefreshCodes = {
    'REFRESH_TOKEN_REUSED',
    'REFRESH_TOKEN_EXPIRED',
    'REFRESH_TOKEN_INVALID',
    'UNAUTHORIZED',
  };

  AuthInterceptor({
    required this.tokenStorage,
    required this.dio,
    this.onSessionTerminated,
    this.refreshDioFactory,
  });

  static bool _isPublicPath(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/2fa/verify') ||
        path.contains('/health');
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicPath(options.path)) {
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
    final options = err.requestOptions;

    final isTokenExpired =
        response?.statusCode == 401 && _errorCode(response?.data) == 'ACCESS_TOKEN_EXPIRED';

    if (!isTokenExpired ||
        _isPublicPath(options.path) ||
        options.extra[_retriedFlag] == true) {
      return handler.next(err);
    }

    // Another queued request may already have refreshed the session.
    final usedHeader = options.headers['Authorization'] as String?;
    final storedAccess = await tokenStorage.getAccessToken();
    if (storedAccess != null &&
        storedAccess.isNotEmpty &&
        usedHeader != 'Bearer $storedAccess') {
      return _retry(options, storedAccess, handler, err);
    }

    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _handleSessionExpired();
      return handler.next(err);
    }

    try {
      final refreshDio = refreshDioFactory?.call() ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              sendTimeout: ApiConfig.sendTimeout,
              headers: {'Accept': 'application/json'},
            ),
          );

      final refreshResponse = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = refreshResponse.data;
      final newAccessToken = data?['accessToken'];
      final newRefreshToken = data?['refreshToken'];
      if (newAccessToken is! String || newRefreshToken is! String) {
        // Malformed response: do not destroy the session on a server glitch.
        return handler.next(err);
      }

      await tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      await _retry(options, newAccessToken, handler, err);
      return;
    } on DioException catch (refreshErr) {
      final status = refreshErr.response?.statusCode;
      final code = _errorCode(refreshErr.response?.data);

      // Only a definitive auth rejection ends the session. Timeouts, offline
      // mode or a sleeping Render instance must NOT log the user out.
      if ((status == 401 || status == 403) &&
          (code == null || _terminalRefreshCodes.contains(code))) {
        await _handleSessionExpired();
      }
      return handler.next(err);
    } catch (_) {
      return handler.next(err);
    }
  }

  Future<void> _retry(
    RequestOptions options,
    String accessToken,
    ErrorInterceptorHandler handler,
    DioException originalError,
  ) async {
    try {
      options.headers['Authorization'] = 'Bearer $accessToken';
      options.extra[_retriedFlag] = true;
      final retryResponse = await dio.fetch<dynamic>(options);
      return handler.resolve(retryResponse);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    } catch (_) {
      return handler.next(originalError);
    }
  }

  String? _errorCode(dynamic data) {
    if (data is Map && data['error'] is Map) {
      final code = (data['error'] as Map)['code'];
      return code is String ? code : null;
    }
    return null;
  }

  Future<void> _handleSessionExpired() async {
    await tokenStorage.clearTokens();
    onSessionTerminated?.call();
  }
}

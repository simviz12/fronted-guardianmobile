import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../error/failures.dart';
import 'auth_interceptor.dart';
import 'server_wake_interceptor.dart';
import 'token_storage.dart';

class NetworkInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.baseUrl != ApiConfig.baseUrl && !options.path.startsWith('http')) {
      options.baseUrl = ApiConfig.baseUrl;
    }
    if (kDebugMode) {
      debugPrint('[HTTP] --> ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP] <-- ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP] <-- ERROR ${err.response?.statusCode ?? 'NO_STATUS'} ${err.requestOptions.method} ${err.requestOptions.uri}: ${err.message}',
      );
    }
    handler.next(err);
  }
}

/// Retries idempotent requests (GET/HEAD) on transient failures with
/// exponential backoff + jitter: connection drops, timeouts and the
/// 502/503/504 answers Render returns while an instance is waking up.
/// Mutations (POST/PATCH/DELETE) are never retried automatically so a
/// command such as LOCK or WIPE can't be sent twice.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;
  final Random _random = Random();

  static const _attemptKey = '__retry_attempt';

  RetryInterceptor({
    required this.dio,
    int? maxRetries,
    this.baseDelay = const Duration(milliseconds: 800),
  }) : maxRetries = maxRetries ?? ApiConfig.maxIdempotentRetries;

  bool _isIdempotent(RequestOptions options) {
    final method = options.method.toUpperCase();
    return method == 'GET' || method == 'HEAD';
  }

  bool _isTransient(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        return status == 502 || status == 503 || status == 504;
      default:
        return false;
    }
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;

    if (!_isIdempotent(options) || !_isTransient(err) || attempt >= maxRetries) {
      return handler.next(err);
    }

    final backoffMs = baseDelay.inMilliseconds * pow(2, attempt).toInt();
    final jitterMs = _random.nextInt(400);
    await Future<void>.delayed(Duration(milliseconds: backoffMs + jitterMs));

    options.extra[_attemptKey] = attempt + 1;
    try {
      final response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    } catch (_) {
      return handler.next(err);
    }
  }
}

class DioClient {
  final Dio dio;

  DioClient({
    Dio? customDio,
    TokenStorage? tokenStorage,
    void Function()? onSessionTerminated,
  }) : dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: ApiConfig.connectTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
                sendTimeout: ApiConfig.sendTimeout,
                headers: {
                  'Accept': 'application/json',
                },
              ),
            ) {
    if (customDio == null) {
      if (tokenStorage != null) {
        dio.interceptors.add(
          AuthInterceptor(
            tokenStorage: tokenStorage,
            dio: dio,
            onSessionTerminated: onSessionTerminated,
          ),
        );
      }
      dio.interceptors.add(ServerWakeInterceptor());
      dio.interceptors.add(RetryInterceptor(dio: dio));
      dio.interceptors.add(NetworkInterceptor());
    }
  }

  static Failure mapDioExceptionToFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();

      case DioExceptionType.connectionError:
        return const NetworkFailure();

      case DioExceptionType.badResponse:
        final response = e.response;
        final data = response?.data;
        if (data is Map && data['error'] is Map) {
          final errorMap = data['error'] as Map;
          final code = errorMap['code'] is String ? errorMap['code'] as String : null;
          final message = errorMap['message'] is String
              ? errorMap['message'] as String
              : 'Error del servidor';
          final rawDetails = errorMap['details'];
          final details = rawDetails is List
              ? rawDetails.map((d) => d.toString()).toList()
              : <String>[];
          return ServerFailure(
            message: message,
            code: code,
            statusCode: response?.statusCode,
            details: details,
          );
        }
        final status = response?.statusCode;
        if (status == 502 || status == 503 || status == 504) {
          return ServerFailure(
            message: 'El servidor se está iniciando. Intenta de nuevo en unos segundos.',
            code: 'SERVICE_UNAVAILABLE',
            statusCode: status,
          );
        }
        return ServerFailure(
          message: 'Error en la respuesta del servidor (${status ?? 500}).',
          statusCode: status,
        );

      case DioExceptionType.cancel:
        return const UnknownFailure(message: 'La solicitud fue cancelada.');

      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          message: 'No se pudo verificar el certificado de seguridad del servidor.',
        );

      default:
        return UnknownFailure(
          message: e.message ?? 'Error desconocido al comunicar con el servidor.',
        );
    }
  }
}

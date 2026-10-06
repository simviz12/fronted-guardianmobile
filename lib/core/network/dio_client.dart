import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../error/failures.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

class NetworkInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
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
        if (response != null && response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('error') && data['error'] is Map<String, dynamic>) {
            final errorMap = data['error'] as Map<String, dynamic>;
            final code = errorMap['code'] as String?;
            final message = errorMap['message'] as String? ?? 'Error del servidor';
            final details = (errorMap['details'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                <String>[];
            return ServerFailure(
              message: message,
              code: code,
              statusCode: response.statusCode,
              details: details,
            );
          }
        }
        return ServerFailure(
          message: 'Error en la respuesta del servidor (${response?.statusCode ?? 500}).',
          statusCode: response?.statusCode,
        );

      case DioExceptionType.cancel:
        return const UnknownFailure(message: 'La solicitud fue cancelada.');

      case DioExceptionType.unknown:
      default:
        return UnknownFailure(
          message: e.message ?? 'Error desconocido al comunicar con el servidor.',
        );
    }
  }
}

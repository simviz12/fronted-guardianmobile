import 'dart:async';
import 'package:dio/dio.dart';
import '../ui/app_toast.dart';

/// Render's free instances sleep when idle and the first request can take up
/// to a minute. If a request is still pending after [threshold], tell the
/// user what is happening instead of showing a frozen spinner.
class ServerWakeInterceptor extends Interceptor {
  final Duration threshold;
  final Duration cooldown;

  static DateTime? _lastShownAt;
  static const _timerKey = '__wake_timer';

  ServerWakeInterceptor({
    this.threshold = const Duration(seconds: 5),
    this.cooldown = const Duration(minutes: 3),
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Retries re-enter onRequest with the same options: replace, don't leak.
    _cancel(options);
    options.extra[_timerKey] = Timer(threshold, () {
      final now = DateTime.now();
      final last = _lastShownAt;
      if (last != null && now.difference(last) < cooldown) return;
      _lastShownAt = now;
      AppToast.info(
        'Conectando con el servidor seguro… la primera conexión puede tardar hasta un minuto.',
      );
    });
    handler.next(options);
  }

  void _cancel(RequestOptions options) {
    final timer = options.extra.remove(_timerKey);
    if (timer is Timer) timer.cancel();
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _cancel(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _cancel(err.requestOptions);
    handler.next(err);
  }
}

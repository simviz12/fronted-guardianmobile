import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  ApiConfig._();

  static const String _defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mobile-backendd.onrender.com',
  );

  static const String keyCustomBaseUrl = 'custom_api_base_url';
  static String _activeBaseUrl = _normalize(_defaultUrl);

  static String get baseUrl => _activeBaseUrl;
  static String get defaultUrl => _normalize(_defaultUrl);

  /// Removes surrounding whitespace and trailing slashes so that
  /// `'$baseUrl/path'` never produces a double slash.
  static String _normalize(String url) {
    var value = url.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  static bool _isValidHttpUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(keyCustomBaseUrl);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        final normalized = _normalize(savedUrl);
        final isEphemeral = normalized.contains('trycloudflare') ||
            normalized.contains('lhr.life') ||
            normalized.contains('192.168.');
        if (isEphemeral || !_isValidHttpUrl(normalized)) {
          _activeBaseUrl = defaultUrl;
          await prefs.remove(keyCustomBaseUrl);
        } else {
          _activeBaseUrl = normalized;
        }
      } else {
        _activeBaseUrl = defaultUrl;
      }
    } catch (_) {
      _activeBaseUrl = defaultUrl;
    }
  }

  static Future<void> setBaseUrl(String url) async {
    final normalized = _normalize(url);
    _activeBaseUrl = _isValidHttpUrl(normalized) ? normalized : defaultUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyCustomBaseUrl, _activeBaseUrl);
    } catch (_) {}
  }

  /// Render's free tier sleeps after inactivity and needs ~30-60 s to wake up.
  /// A 10 s timeout made the first request after idle always fail, so the
  /// connect/receive windows are sized for a cold start.
  static Duration connectTimeout = const Duration(seconds: 60);
  static Duration receiveTimeout = const Duration(seconds: 60);
  static Duration sendTimeout = const Duration(seconds: 30);

  /// Retries applied to idempotent requests (GET/HEAD) on transient errors.
  static int maxIdempotentRetries = 2;
}

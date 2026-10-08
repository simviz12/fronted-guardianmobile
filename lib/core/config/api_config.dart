import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  ApiConfig._();

  static const String _defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.9:3000',
  );

  static const String keyCustomBaseUrl = 'custom_api_base_url';
  static String _activeBaseUrl = _defaultUrl;

  static String get baseUrl => _activeBaseUrl;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(keyCustomBaseUrl);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _activeBaseUrl = savedUrl.trim();
      } else {
        _activeBaseUrl = _defaultUrl;
      }
    } catch (_) {
      _activeBaseUrl = _defaultUrl;
    }
  }

  static Future<void> setBaseUrl(String url) async {
    _activeBaseUrl = url.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyCustomBaseUrl, _activeBaseUrl);
    } catch (_) {}
  }

  static Duration connectTimeout = const Duration(seconds: 10);
  static Duration receiveTimeout = const Duration(seconds: 10);
}

class ApiConfig {
  ApiConfig._();

  /// Default API base URL from compile-time environment or fallback.
  /// 
  /// Diagnostic connection modes:
  /// 1. Real Android phone via USB cable:
  ///    Run: `adb reverse tcp:3000 tcp:3000`
  ///    URL: `http://localhost:3000`
  /// 2. Android Emulator (Loopback alias):
  ///    URL: `http://10.0.2.2:3000`
  /// 3. LAN IP / Wi-Fi direct:
  ///    URL: `http://<LAN_IP>:3000`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class NativeBridgeService {
  Future<void> saveDeviceCredentials({
    required String apiBaseUrl,
    required String deviceId,
    required String deviceToken,
  });

  Future<void> clearDeviceCredentials();

  Future<bool> isBatteryOptimizationIgnored();

  Future<bool> requestIgnoreBatteryOptimization();
}

class NativeBridgeServiceImpl implements NativeBridgeService {
  static const MethodChannel _channel = MethodChannel('com.guardian.mobile/native_bridge');

  @override
  Future<void> saveDeviceCredentials({
    required String apiBaseUrl,
    required String deviceId,
    required String deviceToken,
  }) async {
    try {
      await _channel.invokeMethod('saveDeviceCredentials', {
        'apiBaseUrl': apiBaseUrl,
        'deviceId': deviceId,
        'deviceToken': deviceToken,
      });
    } catch (_) {}
  }

  @override
  Future<void> clearDeviceCredentials() async {
    try {
      await _channel.invokeMethod('clearDeviceCredentials');
    } catch (_) {}
  }

  @override
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final result = await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestIgnoreBatteryOptimization() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimization');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}

final nativeBridgeServiceProvider = Provider<NativeBridgeService>((ref) {
  return NativeBridgeServiceImpl();
});

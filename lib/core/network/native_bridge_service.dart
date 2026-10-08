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

  Future<bool> isDeviceAdminActive();

  Future<bool> requestEnableDeviceAdmin();

  Future<bool> syncDeviceCapabilities();

  Future<bool> hasLocationPermission();

  Future<bool> hasBackgroundLocationPermission();

  Future<bool> requestForegroundLocationPermission();

  Future<bool> requestBackgroundLocationPermission();

  Future<void> openAppSettings();

  Future<bool> isPeriodicLocationEnabled();

  Future<bool> setPeriodicLocationEnabled(bool enabled);

  Future<int> getLocationIntervalMinutes();

  Future<bool> setLocationIntervalMinutes(int minutes);

  Future<void> flushOfflineLocations();
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

  @override
  Future<bool> isDeviceAdminActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceAdminActive');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestEnableDeviceAdmin() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestEnableDeviceAdmin');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> syncDeviceCapabilities() async {
    try {
      final result = await _channel.invokeMethod<bool>('syncDeviceCapabilities');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasLocationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasLocationPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasBackgroundLocationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasBackgroundLocationPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestForegroundLocationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestForegroundLocationPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestBackgroundLocationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestBackgroundLocationPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (_) {}
  }

  @override
  Future<bool> isPeriodicLocationEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isPeriodicLocationEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> setPeriodicLocationEnabled(bool enabled) async {
    try {
      final result = await _channel.invokeMethod<bool>('setPeriodicLocationEnabled', {
        'enabled': enabled,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<int> getLocationIntervalMinutes() async {
    try {
      final result = await _channel.invokeMethod<int>('getLocationIntervalMinutes');
      return result ?? 15;
    } catch (_) {
      return 15;
    }
  }

  @override
  Future<bool> setLocationIntervalMinutes(int minutes) async {
    try {
      final result = await _channel.invokeMethod<bool>('setLocationIntervalMinutes', {
        'minutes': minutes,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> flushOfflineLocations() async {
    try {
      await _channel.invokeMethod('flushOfflineLocations');
    } catch (_) {}
  }
}

final nativeBridgeServiceProvider = Provider<NativeBridgeService>((ref) {
  return NativeBridgeServiceImpl();
});

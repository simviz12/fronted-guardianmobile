import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

class DeviceInstallInfo {
  final String installId;
  final String suggestedName;
  final String platform;
  final String? model;
  final String? osVersion;
  final String? appVersion;

  const DeviceInstallInfo({
    required this.installId,
    required this.suggestedName,
    required this.platform,
    this.model,
    this.osVersion,
    this.appVersion,
  });
}

abstract class DeviceIdentityService {
  Future<DeviceInstallInfo> getInstallInfo();
  Future<void> saveThisPhoneDeviceId(String deviceId);
  Future<String?> getThisPhoneDeviceId();
  Future<void> saveDeviceToken({required String deviceId, required String token});
  Future<String?> getDeviceToken(String deviceId);
  Future<void> clearDeviceToken(String deviceId);
  Future<void> clearThisPhoneIdentity();
}

class DeviceIdentityServiceImpl implements DeviceIdentityService {
  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _deviceInfoPlugin;

  static const String _installIdKey = 'guardian_install_id';
  static const String _thisPhoneDeviceIdKey = 'guardian_this_phone_device_id';
  static const String _deviceTokenPrefix = 'guardian_device_token_';

  DeviceIdentityServiceImpl({
    FlutterSecureStorage? storage,
    DeviceInfoPlugin? deviceInfoPlugin,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  @override
  Future<DeviceInstallInfo> getInstallInfo() async {
    // 1. Install ID persistent UUID
    String? installId = await _storage.read(key: _installIdKey);
    if (installId == null || installId.isEmpty) {
      installId = const Uuid().v4();
      await _storage.write(key: _installIdKey, value: installId);
    }

    String suggestedName = 'Mi Dispositivo';
    String platform = Platform.isIOS ? 'ios' : 'android';
    String? model;
    String? osVersion;
    String? appVersion;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (_) {
      appVersion = '1.0.0';
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        model = androidInfo.model;
        osVersion = androidInfo.version.release;
        suggestedName = androidInfo.model.isNotEmpty
            ? androidInfo.model
            : 'Android Device';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        model = iosInfo.utsname.machine;
        osVersion = iosInfo.systemVersion;
        suggestedName = iosInfo.name.isNotEmpty ? iosInfo.name : 'iPhone';
      }
    } catch (_) {
      suggestedName = 'Dispositivo Guardian';
    }

    return DeviceInstallInfo(
      installId: installId,
      suggestedName: suggestedName,
      platform: platform,
      model: model,
      osVersion: osVersion,
      appVersion: appVersion,
    );
  }

  @override
  Future<void> saveThisPhoneDeviceId(String deviceId) async {
    await _storage.write(key: _thisPhoneDeviceIdKey, value: deviceId);
  }

  @override
  Future<String?> getThisPhoneDeviceId() async {
    return _storage.read(key: _thisPhoneDeviceIdKey);
  }

  @override
  Future<void> saveDeviceToken({
    required String deviceId,
    required String token,
  }) async {
    await _storage.write(key: '$_deviceTokenPrefix$deviceId', value: token);
  }

  @override
  Future<String?> getDeviceToken(String deviceId) async {
    return _storage.read(key: '$_deviceTokenPrefix$deviceId');
  }

  @override
  Future<void> clearDeviceToken(String deviceId) async {
    await _storage.delete(key: '$_deviceTokenPrefix$deviceId');
  }

  @override
  Future<void> clearThisPhoneIdentity() async {
    await _storage.delete(key: _thisPhoneDeviceIdKey);
  }
}

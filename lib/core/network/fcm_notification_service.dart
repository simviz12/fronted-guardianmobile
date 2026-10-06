import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/devices/domain/entities/device.dart';
import '../../features/devices/presentation/providers/devices_provider.dart';

abstract class FcmNotificationService {
  Future<void> initialize(WidgetRef ref);
  Future<String?> getFcmToken();
  Future<bool> requestNotificationPermissions();
}

class FcmNotificationServiceImpl implements FcmNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  Future<void> initialize(WidgetRef ref) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      // 1. Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[FCM] Token refreshed');
        await _syncTokenIfProtected(ref, newToken);
      });

      // 2. Initial token sync
      final token = await _messaging.getToken();
      if (token != null) {
        await _syncTokenIfProtected(ref, token);
      }
    } catch (e) {
      debugPrint('[FCM] Error initializing notifications: $e');
    }
  }

  @override
  Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
      return null;
    }
  }

  @override
  Future<bool> requestNotificationPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  Future<void> _syncTokenIfProtected(WidgetRef ref, String token) async {
    final dashboardState = ref.read(devicesNotifierProvider);
    final thisPhone = dashboardState.thisPhoneDevice;
    if (thisPhone != null && thisPhone.mode == DeviceMode.protected) {
      try {
        final updateUseCase = ref.read(updateFcmTokenUseCaseProvider);
        await updateUseCase(id: thisPhone.id, fcmToken: token);
        debugPrint('[FCM] Synced FCM token to backend for device ${thisPhone.id}');
      } catch (e) {
        debugPrint('[FCM] Failed to sync token to backend: $e');
      }
    }
  }
}

final fcmNotificationServiceProvider = Provider<FcmNotificationService>((ref) {
  return FcmNotificationServiceImpl();
});

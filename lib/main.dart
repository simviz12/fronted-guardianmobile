import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/api_config.dart';
import 'core/network/fcm_notification_service.dart';
import 'core/network/native_bridge_service.dart';
import 'core/realtime/realtime_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/ui/app_toast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Never let an unexpected async error kill the app silently.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught async error: $error\n$stack');
    return true;
  };

  // Edge-to-edge: draw behind status and navigation bars (SafeArea handles insets).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await ApiConfig.init();
  try {
    // Without android/app/google-services.json Firebase is unavailable; the
    // app keeps working through the realtime WebSocket channel.
    await Firebase.initializeApp().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Firebase.initializeApp() warning: $e');
  }

  runApp(
    const ProviderScope(
      child: GuardianMobileApp(),
    ),
  );
}

class GuardianMobileApp extends ConsumerStatefulWidget {
  const GuardianMobileApp({super.key});

  @override
  ConsumerState<GuardianMobileApp> createState() => _GuardianMobileAppState();
}

class _GuardianMobileAppState extends ConsumerState<GuardianMobileApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmNotificationServiceProvider).initialize(ref);
      ref.read(nativeBridgeServiceProvider).syncDeviceCapabilities();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Android may kill the socket while in background; restore it.
      ref.read(realtimeServiceProvider).ensureConnected();
      ref.read(nativeBridgeServiceProvider).syncDeviceCapabilities();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Guardian Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeOutCubic,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final brightness = Theme.of(context).brightness;
        // Respect accessibility font sizes but cap them so layouts never overflow.
        final textScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.overlayStyleFor(brightness),
          child: MediaQuery(
            data: mediaQuery.copyWith(textScaler: textScaler),
            child: GestureDetector(
              // Tap outside any field to dismiss the keyboard.
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

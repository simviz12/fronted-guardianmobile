import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/fcm_notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
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

class _GuardianMobileAppState extends ConsumerState<GuardianMobileApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmNotificationServiceProvider).initialize(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Guardian Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

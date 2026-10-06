import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/commands/presentation/pages/command_history_page.dart';
import '../../features/commands/presentation/pages/device_detail_page.dart';
import '../../features/devices/domain/entities/device.dart';
import '../../features/devices/presentation/pages/dashboard_page.dart';
import '../../features/devices/presentation/pages/link_device_page.dart';
import '../../features/devices/presentation/pages/protected_setup_page.dart';
import '../../features/devices/presentation/pages/settings_page.dart';
import '../../features/server_status/presentation/pages/server_status_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider.notifier);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _RiverpodListenable(authNotifier),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.uri.path;

      // Allow public diagnostic page unconditionally
      if (location == '/server-status') {
        return null;
      }

      if (authState.status == AuthStatus.initial) {
        return location == '/' ? null : '/';
      }

      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isAuthRoute = location == '/login' || location == '/register' || location == '/';

      if (!isAuthenticated) {
        // If unauthenticated, redirect to /login unless already in auth screens
        if (location == '/register') return null;
        return isAuthRoute && location != '/' ? null : '/login';
      }

      // If authenticated, skip login/register/splash and go to /home
      if (isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/link-device',
        builder: (context, state) => const LinkDevicePage(),
      ),
      GoRoute(
        path: '/protected-setup',
        builder: (context, state) => const ProtectedSetupPage(),
      ),
      GoRoute(
        path: '/device-detail',
        builder: (context, state) {
          final device = state.extra as Device;
          return DeviceDetailPage(device: device);
        },
      ),
      GoRoute(
        path: '/command-history',
        builder: (context, state) {
          final device = state.extra as Device;
          return CommandHistoryPage(device: device);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/server-status',
        builder: (context, state) => const ServerStatusPage(),
      ),
    ],
  );
});

class _RiverpodListenable extends ChangeNotifier {
  _RiverpodListenable(StateNotifier<dynamic> notifier) {
    notifier.addListener((_) {
      notifyListeners();
    });
  }
}

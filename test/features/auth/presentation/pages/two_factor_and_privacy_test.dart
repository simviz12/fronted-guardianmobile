import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_mobile/features/auth/domain/entities/user.dart';
import 'package:guardian_mobile/features/auth/presentation/pages/privacy_page.dart';
import 'package:guardian_mobile/features/auth/presentation/pages/two_factor_login_page.dart';
import 'package:guardian_mobile/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  bool verifyCalled = false;
  String? lastCode;

  @override
  void clearError() {}

  @override
  Future<bool> login({required String email, required String password}) async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async =>
      true;

  @override
  Future<void> restoreSession() async {}

  @override
  void cancelTwoFactorLogin() {}

  @override
  void updateUser(User user) {}

  @override
  Future<bool> verifyTwoFactorLogin({required String code}) async {
    verifyCalled = true;
    lastCode = code;
    return true;
  }
}

void main() {
  group('TwoFactorLoginPage Tests', () {
    testWidgets('renders 2FA code input, verify button, and toggle to backup code',
        (tester) async {
      final fakeNotifier = _FakeAuthNotifier(
        const AuthState(
          status: AuthStatus.unauthenticated,
          requiresTwoFactor: true,
          pendingTwoFactorToken: 'test-2fa-token',
        ),
      );

      final router = GoRouter(
        initialLocation: '/2fa',
        routes: [
          GoRoute(path: '/2fa', builder: (context, state) => const TwoFactorLoginPage()),
          GoRoute(path: '/home', builder: (context, state) => const SizedBox()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(find.text('Verificación en Dos Pasos'), findsOneWidget);
      expect(find.text('Código de 6 dígitos'), findsOneWidget);
      expect(find.text('Verificar'), findsOneWidget);
      expect(find.text('Usar código de respaldo'), findsOneWidget);

      // Toggle to backup code
      await tester.tap(find.text('Usar código de respaldo'));
      await tester.pumpAndSettle();

      expect(find.text('Código de respaldo'), findsOneWidget);
      expect(find.text('Usar código de autenticación (TOTP)'), findsOneWidget);

      // Enter code and tap verify
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.verifyCalled, isTrue);
      expect(fakeNotifier.lastCode, equals('123456'));
    });
  });

  group('PrivacyPage Tests', () {
    testWidgets('renders privacy sections and commitment details', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacyPage(),
        ),
      );

      expect(find.text('Privacidad y Seguridad'), findsOneWidget);
      expect(find.text('Compromiso de Privacidad Guardian'), findsOneWidget);
      expect(find.text('¿Qué datos recolectamos?'), findsOneWidget);
      expect(find.text('¿Qué NO recolectamos?'), findsOneWidget);

      // Scroll down to reveal bottom card
      await tester.scrollUntilVisible(find.text('Cifrado y Seguridad de Acceso'), 200);
      expect(find.text('Cifrado y Seguridad de Acceso'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/core/error/failures.dart';
import 'package:guardian_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guardian_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:guardian_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  Widget buildLoginPage() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: LoginPage(),
        ),
      ),
    );
  }

  testWidgets('LoginPage renders idle state with all elements', (tester) async {
    await tester.pumpWidget(buildLoginPage());
    await tester.pump();

    expect(find.text('Acceso Seguro'), findsOneWidget);
    expect(find.text('Iniciar Sesión Segura'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Estado del servidor (Diagnóstico)'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('LoginPage triggers inline validation for empty fields', (tester) async {
    await tester.pumpWidget(buildLoginPage());

    await tester.tap(find.text('Iniciar Sesión Segura'));
    await tester.pump();

    expect(find.text('El correo es requerido'), findsOneWidget);
    expect(find.text('La contraseña es requerida'), findsOneWidget);
  });

  testWidgets('LoginPage displays mapped Spanish error banner on INVALID_CREDENTIALS', (tester) async {
    when(
      () => mockAuthRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      const ServerFailure(
        message: 'Invalid credentials',
        code: 'INVALID_CREDENTIALS',
        statusCode: 401,
      ),
    );

    await tester.pumpWidget(buildLoginPage());

    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'Password123!',
    );

    await tester.tap(find.text('Iniciar Sesión Segura'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
  });

  testWidgets('LoginPage displays connection error when network failure happens', (tester) async {
    when(
      () => mockAuthRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      const NetworkFailure(),
    );

    await tester.pumpWidget(buildLoginPage());

    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'Password123!',
    );

    await tester.tap(find.text('Iniciar Sesión Segura'));
    await tester.pumpAndSettle();

    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
  });
}

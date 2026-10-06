import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guardian_mobile/features/auth/presentation/pages/register_page.dart';
import 'package:guardian_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  Widget buildRegisterPage() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: const MaterialApp(
        home: RegisterPage(),
      ),
    );
  }

  testWidgets('RegisterPage renders all fields and validates required inputs', (tester) async {
    await tester.pumpWidget(buildRegisterPage());

    expect(find.text('Crea tu Cuenta'), findsOneWidget);
    expect(find.text('Registrar Cuenta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));

    await tester.tap(find.text('Registrar Cuenta'));
    await tester.pump();

    expect(find.text('El nombre es requerido'), findsOneWidget);
    expect(find.text('El correo es requerido'), findsOneWidget);
    expect(find.text('La contraseña es requerida'), findsOneWidget);
  });

  testWidgets('RegisterPage validates password rules and confirmation match', (tester) async {
    await tester.pumpWidget(buildRegisterPage());

    final fields = find.byType(TextFormField);

    // Name
    await tester.enterText(fields.at(0), 'Alex Developer');
    // Email
    await tester.enterText(fields.at(1), 'alex@example.com');
    // Password short
    await tester.enterText(fields.at(2), 'short');
    // Confirm password mismatch
    await tester.enterText(fields.at(3), 'short123');

    await tester.tap(find.text('Registrar Cuenta'));
    await tester.pump();

    expect(find.text('Debe tener al menos 8 caracteres'), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });
}

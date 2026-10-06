import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/features/auth/domain/entities/user.dart';
import 'package:guardian_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guardian_mobile/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late RegisterUseCase registerUseCase;
  late LoginUseCase loginUseCase;
  late LogoutUseCase logoutUseCase;
  late GetCurrentUserUseCase getCurrentUserUseCase;
  late RestoreSessionUseCase restoreSessionUseCase;

  const testUser = User(
    id: 'user-123',
    email: 'user@example.com',
    displayName: 'Alex Developer',
  );

  const testSession = AuthSession(
    user: testUser,
    accessToken: 'access-token-xyz',
    refreshToken: 'refresh-token-abc',
    expiresIn: 900,
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    registerUseCase = RegisterUseCase(mockRepository);
    loginUseCase = LoginUseCase(mockRepository);
    logoutUseCase = LogoutUseCase(mockRepository);
    getCurrentUserUseCase = GetCurrentUserUseCase(mockRepository);
    restoreSessionUseCase = RestoreSessionUseCase(mockRepository);
  });

  group('Auth Use Cases', () {
    test('RegisterUseCase calls repository.register', () async {
      when(
        () => mockRepository.register(
          email: 'user@example.com',
          password: 'Password123!',
          displayName: 'Alex Developer',
        ),
      ).thenAnswer((_) async => testSession);

      final result = await registerUseCase(
        email: 'user@example.com',
        password: 'Password123!',
        displayName: 'Alex Developer',
      );

      expect(result, testSession);
      verify(
        () => mockRepository.register(
          email: 'user@example.com',
          password: 'Password123!',
          displayName: 'Alex Developer',
        ),
      ).called(1);
    });

    test('LoginUseCase calls repository.login', () async {
      when(
        () => mockRepository.login(
          email: 'user@example.com',
          password: 'Password123!',
        ),
      ).thenAnswer((_) async => testSession);

      final result = await loginUseCase(
        email: 'user@example.com',
        password: 'Password123!',
      );

      expect(result, testSession);
      verify(
        () => mockRepository.login(
          email: 'user@example.com',
          password: 'Password123!',
        ),
      ).called(1);
    });

    test('LogoutUseCase calls repository.logout', () async {
      when(() => mockRepository.logout()).thenAnswer((_) async {});

      await logoutUseCase();

      verify(() => mockRepository.logout()).called(1);
    });

    test('GetCurrentUserUseCase calls repository.getCurrentUser', () async {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => testUser);

      final result = await getCurrentUserUseCase();

      expect(result, testUser);
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('RestoreSessionUseCase calls repository.restoreSession', () async {
      when(() => mockRepository.restoreSession()).thenAnswer((_) async => testUser);

      final result = await restoreSessionUseCase();

      expect(result, testUser);
      verify(() => mockRepository.restoreSession()).called(1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_mobile/core/network/token_storage.dart';
import 'package:guardian_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:guardian_mobile/features/auth/data/models/auth_dtos.dart';
import 'package:guardian_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthRemoteDataSource mockDataSource;
  late MockTokenStorage mockTokenStorage;
  late AuthRepositoryImpl repository;

  const testUserDto = UserDto(
    id: 'user-123',
    email: 'user@example.com',
    displayName: 'Alex Developer',
  );

  const testAuthDto = AuthResponseDto(
    user: testUserDto,
    accessToken: 'access-123',
    refreshToken: 'refresh-456',
    expiresIn: 900,
  );

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    mockTokenStorage = MockTokenStorage();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockDataSource,
      tokenStorage: mockTokenStorage,
    );
  });

  group('AuthRepositoryImpl', () {
    test('login stores tokens and returns entity', () async {
      when(
        () => mockDataSource.login(
          email: 'user@example.com',
          password: 'Password123!',
        ),
      ).thenAnswer((_) async => testAuthDto);

      when(
        () => mockTokenStorage.saveTokens(
          accessToken: 'access-123',
          refreshToken: 'refresh-456',
        ),
      ).thenAnswer((_) async {});

      final result = await repository.login(
        email: 'user@example.com',
        password: 'Password123!',
      );

      expect(result.user.id, 'user-123');
      expect(result.accessToken, 'access-123');
      verify(
        () => mockTokenStorage.saveTokens(
          accessToken: 'access-123',
          refreshToken: 'refresh-456',
        ),
      ).called(1);
    });

    test('register stores tokens and returns entity', () async {
      when(
        () => mockDataSource.register(
          email: 'user@example.com',
          password: 'Password123!',
          displayName: 'Alex Developer',
        ),
      ).thenAnswer((_) async => testAuthDto);

      when(
        () => mockTokenStorage.saveTokens(
          accessToken: 'access-123',
          refreshToken: 'refresh-456',
        ),
      ).thenAnswer((_) async {});

      final result = await repository.register(
        email: 'user@example.com',
        password: 'Password123!',
        displayName: 'Alex Developer',
      );

      expect(result.user.displayName, 'Alex Developer');
      verify(
        () => mockTokenStorage.saveTokens(
          accessToken: 'access-123',
          refreshToken: 'refresh-456',
        ),
      ).called(1);
    });

    test('logout calls remote logout and clears tokens', () async {
      when(() => mockTokenStorage.getRefreshToken())
          .thenAnswer((_) async => 'refresh-456');
      when(() => mockDataSource.logout(refreshToken: 'refresh-456'))
          .thenAnswer((_) async {});
      when(() => mockTokenStorage.clearTokens()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockDataSource.logout(refreshToken: 'refresh-456')).called(1);
      verify(() => mockTokenStorage.clearTokens()).called(1);
    });

    test('restoreSession returns null if no tokens exist', () async {
      when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async => null);
      when(() => mockTokenStorage.getRefreshToken()).thenAnswer((_) async => null);

      final user = await repository.restoreSession();

      expect(user, isNull);
    });

    test('restoreSession returns user when token is valid', () async {
      when(() => mockTokenStorage.getAccessToken())
          .thenAnswer((_) async => 'access-123');
      when(() => mockTokenStorage.getRefreshToken())
          .thenAnswer((_) async => 'refresh-456');
      when(() => mockDataSource.getMe()).thenAnswer((_) async => testUserDto);

      final user = await repository.restoreSession();

      expect(user?.email, 'user@example.com');
      verify(() => mockDataSource.getMe()).called(1);
    });
  });
}

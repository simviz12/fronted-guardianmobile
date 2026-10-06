import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<User> getCurrentUser();

  Future<User?> restoreSession();
}

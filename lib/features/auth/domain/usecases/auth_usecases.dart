import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<AuthSession> call({
    required String email,
    required String password,
    required String displayName,
  }) {
    return repository.register(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthSession> call({
    required String email,
    required String password,
  }) {
    return repository.login(email: email, password: password);
  }
}

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<User> call() {
    return repository.getCurrentUser();
  }
}

class RestoreSessionUseCase {
  final AuthRepository repository;

  RestoreSessionUseCase(this.repository);

  Future<User?> call() {
    return repository.restoreSession();
  }
}

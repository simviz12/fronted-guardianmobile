import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/token_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

// Storage Provider
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return const SecureTokenStorageImpl();
});

// Callback for session termination
final sessionTerminatedCallbackProvider = StateProvider<VoidCallback?>((ref) => null);

// DioClient Provider with auth support
final authenticatedDioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return DioClient(
    tokenStorage: storage,
    onSessionTerminated: () {
      final callback = ref.read(sessionTerminatedCallbackProvider);
      callback?.call();
    },
  );
});

// DataSource
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dioClient = ref.watch(authenticatedDioClientProvider);
  return AuthRemoteDataSourceImpl(client: dioClient);
});

// Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    tokenStorage: tokenStorage,
  );
});

// Use Cases
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
  return RestoreSessionUseCase(ref.watch(authRepositoryProvider));
});

// Auth State Definition
enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final bool isLoading;
  final String? errorMessage;
  final String? errorCode;

  const AuthState({
    required this.status,
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.errorCode,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  factory AuthState.unauthenticated({String? errorMessage, String? errorCode}) =>
      AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: errorMessage,
        errorCode: errorCode,
      );

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isLoading,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState.initial()) {
    // Setup session termination hook deferred to after current build frame
    Future.microtask(() {
      _ref.read(sessionTerminatedCallbackProvider.notifier).state = () {
        state = AuthState.unauthenticated(
          errorMessage: 'Tu sesión ha caducado. Vuelve a iniciar sesión.',
          errorCode: 'SESSION_EXPIRED',
        );
      };
    });
  }

  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final restoreUseCase = _ref.read(restoreSessionUseCaseProvider);
      final user = await restoreUseCase();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final loginUseCase = _ref.read(loginUseCaseProvider);
      final session = await loginUseCase(email: email, password: password);
      state = AuthState.authenticated(session.user);
      return true;
    } catch (e) {
      _mapFailureToError(e);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final registerUseCase = _ref.read(registerUseCaseProvider);
      final session = await registerUseCase(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AuthState.authenticated(session.user);
      return true;
    } catch (e) {
      _mapFailureToError(e);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final logoutUseCase = _ref.read(logoutUseCaseProvider);
      await logoutUseCase();
    } finally {
      state = AuthState.unauthenticated();
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _mapFailureToError(dynamic failure) {
    String message = 'Ocurrió un error inesperado al procesar la solicitud.';
    String? code;

    final failureString = failure.toString();
    if (failureString.contains('NetworkFailure')) {
      message = 'No hay conexión con el servidor.';
      code = 'NETWORK_ERROR';
    } else if (failureString.contains('TimeoutFailure')) {
      message = 'El servidor tardó demasiado en responder.';
      code = 'TIMEOUT_ERROR';
    } else {
      // Check code if available
      try {
        final dynamic fail = failure;
        code = fail.code as String?;
        final serverMessage = fail.message as String?;

        if (code == 'INVALID_CREDENTIALS') {
          message = 'Correo o contraseña incorrectos.';
        } else if (code == 'TOO_MANY_REQUESTS') {
          message = 'Demasiados intentos, espera un minuto.';
        } else if (code == 'EMAIL_ALREADY_REGISTERED') {
          message = 'Este correo ya está registrado.';
        } else if (code == 'VALIDATION_ERROR') {
          message = serverMessage ?? 'Los datos ingresados no son válidos.';
        } else if (serverMessage != null && serverMessage.isNotEmpty) {
          message = serverMessage;
        }
      } catch (_) {}
    }

    state = state.copyWith(
      isLoading: false,
      errorMessage: message,
      errorCode: code,
    );
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

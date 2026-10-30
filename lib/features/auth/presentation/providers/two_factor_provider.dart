import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/auth_dtos.dart';
import '../providers/auth_provider.dart';

// ─── 2FA Setup State Machine ───────────────────────────────────────────────

enum TwoFactorSetupStep { idle, loading, showQr, showBackupCodes, disabled }

class TwoFactorSetupState {
  final TwoFactorSetupStep step;
  final String? otpauthUrl;
  final String? secret;
  final List<String> backupCodes;
  final bool isLoading;
  final String? errorMessage;

  const TwoFactorSetupState({
    this.step = TwoFactorSetupStep.idle,
    this.otpauthUrl,
    this.secret,
    this.backupCodes = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  TwoFactorSetupState copyWith({
    TwoFactorSetupStep? step,
    String? otpauthUrl,
    String? secret,
    List<String>? backupCodes,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TwoFactorSetupState(
      step: step ?? this.step,
      otpauthUrl: otpauthUrl ?? this.otpauthUrl,
      secret: secret ?? this.secret,
      backupCodes: backupCodes ?? this.backupCodes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TwoFactorSetupNotifier extends StateNotifier<TwoFactorSetupState> {
  final Ref _ref;

  TwoFactorSetupNotifier(this._ref) : super(const TwoFactorSetupState());

  Future<void> startSetup() async {
    state = state.copyWith(isLoading: true, clearError: true, step: TwoFactorSetupStep.loading);
    try {
      final ds = _ref.read(authRemoteDataSourceProvider);
      final dto = await ds.setup2FA();
      state = state.copyWith(
        step: TwoFactorSetupStep.showQr,
        otpauthUrl: dto.otpauthUrl,
        secret: dto.secret,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        step: TwoFactorSetupStep.idle,
        isLoading: false,
        errorMessage: _errorMessage(e),
      );
    }
  }

  Future<bool> enableWithToken(String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ds = _ref.read(authRemoteDataSourceProvider);
      final result = await ds.enable2FA(token: token);
      state = state.copyWith(
        step: TwoFactorSetupStep.showBackupCodes,
        backupCodes: result.backupCodes,
        isLoading: false,
      );
      // Update user entity so Settings shows 2FA as enabled
      final user = _ref.read(authNotifierProvider).user;
      if (user != null) {
        _ref.read(authNotifierProvider.notifier).updateUser(
              user.copyWith(twoFactorEnabled: true),
            );
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _errorMessage(e));
      return false;
    }
  }

  Future<bool> disable({required String password, required String twoFactorCode}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ds = _ref.read(authRemoteDataSourceProvider);
      await ds.disable2FA(password: password, twoFactorCode: twoFactorCode);
      state = const TwoFactorSetupState(step: TwoFactorSetupStep.disabled);
      // Update user entity so Settings shows 2FA as disabled
      final user = _ref.read(authNotifierProvider).user;
      if (user != null) {
        _ref.read(authNotifierProvider.notifier).updateUser(
              user.copyWith(twoFactorEnabled: false),
            );
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _errorMessage(e));
      return false;
    }
  }

  void reset() {
    state = const TwoFactorSetupState();
  }

  String _errorMessage(dynamic e) {
    try {
      final code = (e as dynamic).code as String?;
      if (code == 'INVALID_CREDENTIALS') return 'Contraseña incorrecta.';
      if (code == 'TWO_FACTOR_INVALID') return 'Código 2FA incorrecto.';
      final msg = (e as dynamic).message as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    } catch (_) {}
    if (e.toString().contains('NetworkFailure')) {
      return 'Sin conexión con el servidor.';
    }
    return 'Error inesperado. Inténtalo de nuevo.';
  }
}

final twoFactorSetupProvider =
    StateNotifierProvider<TwoFactorSetupNotifier, TwoFactorSetupState>((ref) {
  return TwoFactorSetupNotifier(ref);
});

// ─── Sessions State ─────────────────────────────────────────────────────────

class SessionsState {
  final List<ActiveSessionDto> sessions;
  final bool isLoading;
  final String? errorMessage;

  const SessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  SessionsState copyWith({
    List<ActiveSessionDto>? sessions,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionsState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SessionsNotifier extends StateNotifier<SessionsState> {
  final Ref _ref;

  SessionsNotifier(this._ref) : super(const SessionsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ds = _ref.read(authRemoteDataSourceProvider);
      final list = await ds.getSessions();
      state = state.copyWith(sessions: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudieron cargar las sesiones.',
      );
    }
  }

  Future<void> revoke(String sessionId) async {
    try {
      final ds = _ref.read(authRemoteDataSourceProvider);
      await ds.revokeSession(sessionId: sessionId);
      state = state.copyWith(
        sessions: state.sessions.where((s) => s.id != sessionId).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'No se pudo revocar la sesión.');
    }
  }

  Future<void> revokeAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final ds = _ref.read(authRemoteDataSourceProvider);
      await ds.logoutAll();
      // After revoking all sessions, log out locally
      await _ref.read(authNotifierProvider.notifier).logout();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error al cerrar todas las sesiones.');
    }
  }
}

final sessionsProvider = StateNotifierProvider<SessionsNotifier, SessionsState>((ref) {
  return SessionsNotifier(ref);
});

// ─── Change Password State ───────────────────────────────────────────────────

class ChangePasswordState {
  final bool isLoading;
  final bool success;
  final String? errorMessage;

  const ChangePasswordState({
    this.isLoading = false,
    this.success = false,
    this.errorMessage,
  });

  ChangePasswordState copyWith({
    bool? isLoading,
    bool? success,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      success: success ?? this.success,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ChangePasswordNotifier extends StateNotifier<ChangePasswordState> {
  final Ref _ref;

  ChangePasswordNotifier(this._ref) : super(const ChangePasswordState());

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, success: false);
    try {
      final ds = _ref.read(authRemoteDataSourceProvider);
      await ds.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, success: true);
      return true;
    } catch (e) {
      String msg = 'Error al cambiar la contraseña.';
      try {
        final code = (e as dynamic).code as String?;
        if (code == 'INVALID_CREDENTIALS') msg = 'La contraseña actual es incorrecta.';
      } catch (_) {}
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  void reset() {
    state = const ChangePasswordState();
  }
}

final changePasswordProvider =
    StateNotifierProvider<ChangePasswordNotifier, ChangePasswordState>((ref) {
  return ChangePasswordNotifier(ref);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian_mobile/core/error/failures.dart';
import 'package:guardian_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:guardian_mobile/features/devices/presentation/providers/devices_provider.dart';
import 'package:guardian_mobile/features/theft_mode/data/datasources/theft_mode_remote_data_source.dart';
import 'package:guardian_mobile/features/theft_mode/data/repositories/theft_mode_repository_impl.dart';
import 'package:guardian_mobile/features/theft_mode/domain/entities/theft_mode_config.dart';
import 'package:guardian_mobile/features/theft_mode/domain/repositories/theft_mode_repository.dart';
import 'package:guardian_mobile/features/theft_mode/domain/usecases/theft_mode_usecases.dart';

final theftModeRemoteDataSourceProvider = Provider<TheftModeRemoteDataSource>((ref) {
  final dioClient = ref.watch(authenticatedDioClientProvider);
  return TheftModeRemoteDataSourceImpl(client: dioClient);
});

final theftModeRepositoryProvider = Provider<TheftModeRepository>((ref) {
  final remote = ref.watch(theftModeRemoteDataSourceProvider);
  return TheftModeRepositoryImpl(remoteDataSource: remote);
});

final activateTheftModeUseCaseProvider = Provider<ActivateTheftModeUseCase>((ref) {
  return ActivateTheftModeUseCase(ref.watch(theftModeRepositoryProvider));
});

final getActiveTheftModeUseCaseProvider = Provider<GetActiveTheftModeUseCase>((ref) {
  return GetActiveTheftModeUseCase(ref.watch(theftModeRepositoryProvider));
});

final getTheftModeHistoryUseCaseProvider = Provider<GetTheftModeHistoryUseCase>((ref) {
  return GetTheftModeHistoryUseCase(ref.watch(theftModeRepositoryProvider));
});

final deactivateTheftModeUseCaseProvider = Provider<DeactivateTheftModeUseCase>((ref) {
  return DeactivateTheftModeUseCase(ref.watch(theftModeRepositoryProvider));
});

class TheftModeState {
  final TheftModeConfig? activeConfig;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? actionSuccessMessage;

  const TheftModeState({
    this.activeConfig,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.actionSuccessMessage,
  });

  bool get isActive => activeConfig != null && activeConfig!.isActive;

  TheftModeState copyWith({
    TheftModeConfig? activeConfig,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? actionSuccessMessage,
    bool clearActiveConfig = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TheftModeState(
      activeConfig: clearActiveConfig ? null : (activeConfig ?? this.activeConfig),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionSuccessMessage: clearSuccess ? null : (actionSuccessMessage ?? this.actionSuccessMessage),
    );
  }
}

class TheftModeNotifier extends StateNotifier<TheftModeState> {
  final Ref _ref;
  final String _deviceId;

  TheftModeNotifier(this._ref, this._deviceId) : super(const TheftModeState(isLoading: true)) {
    loadActiveConfig();
  }

  Future<void> loadActiveConfig() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final getUseCase = _ref.read(getActiveTheftModeUseCaseProvider);
      final active = await getUseCase(_deviceId);
      state = state.copyWith(
        activeConfig: active,
        clearActiveConfig: active == null,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al consultar modo robo: ${e.toString()}',
      );
    }
  }

  Future<bool> activate({
    required String message,
    String? contactPhone,
    required int locationIntervalSeconds,
    required bool alarm,
    required bool lock,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final activateUseCase = _ref.read(activateTheftModeUseCaseProvider);
      final result = await activateUseCase(
        deviceId: _deviceId,
        message: message,
        contactPhone: contactPhone,
        locationIntervalSeconds: locationIntervalSeconds,
        alarm: alarm,
        lock: lock,
      );

      state = state.copyWith(
        activeConfig: result,
        isSubmitting: false,
        actionSuccessMessage: 'Modo robo activado exitosamente.',
      );

      // Refresh devices list to update device.theftModeActive
      _ref.read(devicesNotifierProvider.notifier).loadDevices();
      return true;
    } catch (e) {
      String errorMsg = 'Error al activar modo robo.';
      final str = e.toString();
      if (str.contains('THEFT_MODE_ALREADY_ACTIVE')) {
        errorMsg = 'El modo robo ya se encuentra activo en este dispositivo.';
      } else if (str.contains('CAPABILITY_NOT_AVAILABLE')) {
        errorMsg = 'No es posible bloquear la pantalla porque el permiso de Administrador no está activo.';
      } else if (e is Failure && e.message.isNotEmpty) {
        errorMsg = e.message;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: errorMsg,
      );
      return false;
    }
  }

  Future<bool> deactivate({
    required String password,
    bool force = false,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final deactivateUseCase = _ref.read(deactivateTheftModeUseCaseProvider);
      await deactivateUseCase(
        deviceId: _deviceId,
        password: password,
        force: force,
      );

      state = state.copyWith(
        clearActiveConfig: true,
        isSubmitting: false,
        actionSuccessMessage: 'Modo robo desactivado exitosamente.',
      );

      // Refresh devices list
      _ref.read(devicesNotifierProvider.notifier).loadDevices();
      return true;
    } catch (e) {
      String errorMsg = 'Error al desactivar el modo robo.';
      final str = e.toString();
      if (str.contains('INVALID_CREDENTIALS') || str.contains('401')) {
        errorMsg = 'Contraseña incorrecta. Por favor verifica tus credenciales.';
      } else if (e is Failure && e.message.isNotEmpty) {
        errorMsg = e.message;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: errorMsg,
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }
}

final theftModeProvider =
    StateNotifierProvider.family<TheftModeNotifier, TheftModeState, String>((ref, deviceId) {
  return TheftModeNotifier(ref, deviceId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/realtime/realtime_events.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../devices/presentation/providers/devices_provider.dart';
import '../../data/datasources/wipe_remote_data_source.dart';
import '../../data/repositories/wipe_repository_impl.dart';
import '../../domain/repositories/wipe_repository.dart';
import '../../domain/usecases/wipe_device_usecase.dart';

final wipeRemoteDataSourceProvider = Provider<WipeRemoteDataSource>((ref) {
  final dioClient = ref.watch(authenticatedDioClientProvider);
  return WipeRemoteDataSourceImpl(client: dioClient);
});

final wipeRepositoryProvider = Provider<WipeRepository>((ref) {
  return WipeRepositoryImpl(remoteDataSource: ref.watch(wipeRemoteDataSourceProvider));
});

final wipeDeviceUseCaseProvider = Provider<WipeDeviceUseCase>((ref) {
  return WipeDeviceUseCase(ref.watch(wipeRepositoryProvider));
});

enum WipeProgressStep {
  idle,
  sending,
  sent,
  received,
  wiping,
  offlineCompleted,
  failed,
}

class WipeWizardState {
  final int currentStep; // 1, 2, 3, 4
  final bool checklistConsequences;
  final bool checklistOtherMethods;
  final bool checklistCorrectDevice;
  final String confirmationInput;
  final String passwordInput;
  final bool isSubmitting;
  final WipeProgressStep progressStep;
  final String? errorMessage;
  final String? commandId;

  const WipeWizardState({
    this.currentStep = 1,
    this.checklistConsequences = false,
    this.checklistOtherMethods = false,
    this.checklistCorrectDevice = false,
    this.confirmationInput = '',
    this.passwordInput = '',
    this.isSubmitting = false,
    this.progressStep = WipeProgressStep.idle,
    this.errorMessage,
    this.commandId,
  });

  bool get isChecklistComplete =>
      checklistConsequences && checklistOtherMethods && checklistCorrectDevice;

  bool get isConfirmationValid => confirmationInput.trim() == 'BORRAR';

  bool get isPasswordValid => passwordInput.isNotEmpty;

  WipeWizardState copyWith({
    int? currentStep,
    bool? checklistConsequences,
    bool? checklistOtherMethods,
    bool? checklistCorrectDevice,
    String? confirmationInput,
    String? passwordInput,
    bool? isSubmitting,
    WipeProgressStep? progressStep,
    String? errorMessage,
    String? commandId,
    bool clearError = false,
  }) {
    return WipeWizardState(
      currentStep: currentStep ?? this.currentStep,
      checklistConsequences: checklistConsequences ?? this.checklistConsequences,
      checklistOtherMethods: checklistOtherMethods ?? this.checklistOtherMethods,
      checklistCorrectDevice: checklistCorrectDevice ?? this.checklistCorrectDevice,
      confirmationInput: confirmationInput ?? this.confirmationInput,
      passwordInput: passwordInput ?? this.passwordInput,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      progressStep: progressStep ?? this.progressStep,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      commandId: commandId ?? this.commandId,
    );
  }
}

class WipeWizardNotifier extends StateNotifier<WipeWizardState> {
  final Ref _ref;
  final String _deviceId;

  WipeWizardNotifier(this._ref, this._deviceId) : super(const WipeWizardState()) {
    _listenToRealtime();
  }

  void _listenToRealtime() {
    _ref.listen<AsyncValue<RealtimeEvent>>(
      realtimeEventsStreamProvider,
      (previous, next) {
        next.whenData((event) {
          if (event is CommandUpdatedEvent && event.deviceId == _deviceId) {
            _onCommandUpdated(event);
          } else if (event is DeviceStatusEvent && event.deviceId == _deviceId) {
            _onDeviceStatus(event);
          }
        });
      },
    );
  }

  void _onCommandUpdated(CommandUpdatedEvent event) {
    if (event.type.toUpperCase() == 'WIPE' ||
        (state.commandId != null && event.commandId == state.commandId)) {
      final status = event.status.toUpperCase();
      if (status == 'SENT') {
        state = state.copyWith(progressStep: WipeProgressStep.sent);
      } else if (status == 'DELIVERED') {
        state = state.copyWith(progressStep: WipeProgressStep.received);
      } else if (status == 'EXECUTING' || status == 'EXECUTED') {
        state = state.copyWith(progressStep: WipeProgressStep.wiping);
      } else if (status == 'FAILED') {
        state = state.copyWith(
          progressStep: WipeProgressStep.failed,
          errorMessage: event.failureReason ?? 'El borrado falló en el dispositivo.',
        );
      }
    }
  }

  void _onDeviceStatus(DeviceStatusEvent event) {
    if (!event.isOnline &&
        (state.progressStep == WipeProgressStep.wiping ||
            state.progressStep == WipeProgressStep.received ||
            state.progressStep == WipeProgressStep.sent)) {
      state = state.copyWith(progressStep: WipeProgressStep.offlineCompleted);
    }
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step, clearError: true);
  }

  void nextStep() {
    if (state.currentStep < 4) {
      state = state.copyWith(currentStep: state.currentStep + 1, clearError: true);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1, clearError: true);
    }
  }

  void toggleChecklistConsequences(bool? val) {
    state = state.copyWith(checklistConsequences: val ?? false);
  }

  void toggleChecklistOtherMethods(bool? val) {
    state = state.copyWith(checklistOtherMethods: val ?? false);
  }

  void toggleChecklistCorrectDevice(bool? val) {
    state = state.copyWith(checklistCorrectDevice: val ?? false);
  }

  void setConfirmationInput(String val) {
    state = state.copyWith(confirmationInput: val, clearError: true);
  }

  void setPasswordInput(String val) {
    state = state.copyWith(passwordInput: val, clearError: true);
  }

  Future<bool> executeWipe() async {
    if (!state.isConfirmationValid) {
      state = state.copyWith(
        errorMessage: 'Debes escribir exactamente la palabra "BORRAR".',
      );
      return false;
    }
    if (!state.isPasswordValid) {
      state = state.copyWith(
        errorMessage: 'Ingresa la contraseña de tu cuenta para autorizar la orden.',
      );
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      progressStep: WipeProgressStep.sending,
      clearError: true,
    );

    try {
      final wipeUseCase = _ref.read(wipeDeviceUseCaseProvider);
      await wipeUseCase(
        deviceId: _deviceId,
        password: state.passwordInput,
        confirmationText: state.confirmationInput.trim(),
      );

      state = state.copyWith(
        isSubmitting: false,
        progressStep: WipeProgressStep.sent,
      );

      // Refresh devices list in background
      _ref.read(devicesNotifierProvider.notifier).loadDevices();
      return true;
    } catch (e) {
      String message = 'Ocurrió un error al ordenar el borrado del dispositivo.';
      final str = e.toString().toUpperCase();

      if (str.contains('WIPE_DISABLED')) {
        message = 'El borrado remoto está deshabilitado en este dispositivo.';
      } else if (str.contains('INVALID_CREDENTIALS') || str.contains('401')) {
        message = 'Contraseña incorrecta. Límite de 3 intentos por hora.';
      } else if (str.contains('CAPABILITY_NOT_AVAILABLE')) {
        message = 'El dispositivo no cuenta con permisos de Administrador para borrado remoto.';
      } else if (str.contains('TOO_MANY_REQUESTS') || str.contains('429')) {
        message = 'Demasiados intentos fallidos. Intenta nuevamente en 1 hora.';
      } else if (e is Failure && e.message.isNotEmpty) {
        message = e.message;
      }

      state = state.copyWith(
        isSubmitting: false,
        progressStep: WipeProgressStep.failed,
        errorMessage: message,
      );
      return false;
    }
  }

  void reset() {
    state = const WipeWizardState();
  }
}

final wipeWizardProvider =
    StateNotifierProvider.family<WipeWizardNotifier, WipeWizardState, String>((ref, deviceId) {
  return WipeWizardNotifier(ref, deviceId);
});

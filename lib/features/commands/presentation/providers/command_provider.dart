import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/command_remote_data_source.dart';
import '../../data/repositories/command_repository_impl.dart';
import '../../domain/entities/command.dart';
import '../../domain/repositories/command_repository.dart';
import '../../domain/usecases/command_usecases.dart';

// Remote DataSource
final commandRemoteDataSourceProvider = Provider<CommandRemoteDataSource>((ref) {
  final dioClient = ref.watch(authenticatedDioClientProvider);
  return CommandRemoteDataSourceImpl(client: dioClient);
});

// Repository
final commandRepositoryProvider = Provider<CommandRepository>((ref) {
  final remoteDataSource = ref.watch(commandRemoteDataSourceProvider);
  return CommandRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Use Cases
final sendCommandUseCaseProvider = Provider<SendCommandUseCase>((ref) {
  return SendCommandUseCase(ref.watch(commandRepositoryProvider));
});

final getCommandUseCaseProvider = Provider<GetCommandUseCase>((ref) {
  return GetCommandUseCase(ref.watch(commandRepositoryProvider));
});

final listDeviceCommandsUseCaseProvider = Provider<ListDeviceCommandsUseCase>((ref) {
  return ListDeviceCommandsUseCase(ref.watch(commandRepositoryProvider));
});

// State for Live Command Tracking
class CommandExecutionState {
  final Command? activeCommand;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isPolling;

  const CommandExecutionState({
    this.activeCommand,
    this.isSubmitting = false,
    this.errorMessage,
    this.isPolling = false,
  });

  factory CommandExecutionState.idle() => const CommandExecutionState();

  CommandExecutionState copyWith({
    Command? activeCommand,
    bool? isSubmitting,
    String? errorMessage,
    bool? isPolling,
    bool clearActiveCommand = false,
    bool clearError = false,
  }) {
    return CommandExecutionState(
      activeCommand: clearActiveCommand ? null : (activeCommand ?? this.activeCommand),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPolling: isPolling ?? this.isPolling,
    );
  }
}

class CommandNotifier extends StateNotifier<CommandExecutionState> {
  final Ref _ref;
  Timer? _pollingTimer;
  int _pollAttempts = 0;
  static const int _maxPollAttempts = 75; // 75 * 2s = 150s (2.5 minutes)

  CommandNotifier(this._ref) : super(CommandExecutionState.idle());

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<bool> sendRingCommand({
    required String deviceId,
    int durationSeconds = 60,
  }) async {
    _pollingTimer?.cancel();
    state = state.copyWith(isSubmitting: true, clearError: true, clearActiveCommand: true);

    try {
      final sendUseCase = _ref.read(sendCommandUseCaseProvider);
      final command = await sendUseCase(
        deviceId: deviceId,
        type: CommandType.ring,
        payload: {
          'durationSeconds': durationSeconds,
        },
        ttl: 120,
      );

      state = state.copyWith(
        activeCommand: command,
        isSubmitting: false,
        isPolling: true,
        clearError: true,
      );

      _startPolling(command.id);
      return true;
    } catch (e) {
      _handleSendError(e);
      return false;
    }
  }

  Future<bool> sendVibrateCommand({
    required String deviceId,
    int durationSeconds = 5,
  }) async {
    _pollingTimer?.cancel();
    state = state.copyWith(isSubmitting: true, clearError: true, clearActiveCommand: true);

    try {
      final sendUseCase = _ref.read(sendCommandUseCaseProvider);
      final command = await sendUseCase(
        deviceId: deviceId,
        type: CommandType.vibrate,
        payload: {
          'durationSeconds': durationSeconds,
        },
        ttl: 60,
      );

      state = state.copyWith(
        activeCommand: command,
        isSubmitting: false,
        isPolling: true,
        clearError: true,
      );

      _startPolling(command.id);
      return true;
    } catch (e) {
      _handleSendError(e);
      return false;
    }
  }

  Future<bool> sendMessageCommand({
    required String deviceId,
    required String text,
    String? contactPhone,
  }) async {
    _pollingTimer?.cancel();
    state = state.copyWith(isSubmitting: true, clearError: true, clearActiveCommand: true);

    try {
      final sendUseCase = _ref.read(sendCommandUseCaseProvider);
      final payload = <String, dynamic>{
        'text': text,
      };
      if (contactPhone != null && contactPhone.trim().isNotEmpty) {
        payload['contactPhone'] = contactPhone.trim();
      }

      final command = await sendUseCase(
        deviceId: deviceId,
        type: CommandType.message,
        payload: payload,
        ttl: 300,
      );

      state = state.copyWith(
        activeCommand: command,
        isSubmitting: false,
        isPolling: true,
        clearError: true,
      );

      _startPolling(command.id);
      return true;
    } catch (e) {
      _handleSendError(e);
      return false;
    }
  }

  Future<bool> sendLockCommand({
    required String deviceId,
  }) async {
    _pollingTimer?.cancel();
    state = state.copyWith(isSubmitting: true, clearError: true, clearActiveCommand: true);

    try {
      final sendUseCase = _ref.read(sendCommandUseCaseProvider);
      final command = await sendUseCase(
        deviceId: deviceId,
        type: CommandType.lock,
        payload: null,
        ttl: 60,
      );

      state = state.copyWith(
        activeCommand: command,
        isSubmitting: false,
        isPolling: true,
        clearError: true,
      );

      _startPolling(command.id);
      return true;
    } catch (e) {
      _handleSendError(e);
      return false;
    }
  }

  Future<bool> sendLocateCommand({
    required String deviceId,
  }) async {
    _pollingTimer?.cancel();
    state = state.copyWith(isSubmitting: true, clearError: true, clearActiveCommand: true);

    try {
      final sendUseCase = _ref.read(sendCommandUseCaseProvider);
      final command = await sendUseCase(
        deviceId: deviceId,
        type: CommandType.locate,
        payload: null,
        ttl: 60,
      );

      state = state.copyWith(
        activeCommand: command,
        isSubmitting: false,
        isPolling: true,
        clearError: true,
      );

      _startPolling(command.id);
      return true;
    } catch (e) {
      _handleSendError(e);
      return false;
    }
  }

  void _handleSendError(Object e) {
    String msg = 'Error al enviar la orden.';
    if (e is ServerFailure) {
      if (e.details.isNotEmpty) {
        msg = '${e.message}: ${e.details.join(", ")}';
      } else {
        msg = e.message;
      }
    } else if (e is Failure && e.message.isNotEmpty) {
      msg = e.message;
    }
    final str = e.toString();
    if (str.contains('CAPABILITY_NOT_AVAILABLE')) {
      msg = 'Este dispositivo no ha activado el permiso de bloqueo (Administrador de Dispositivo).';
    } else if (str.contains('DEVICE_NOT_REACHABLE')) {
      msg = 'Este dispositivo aún no puede recibir órdenes (sin token FCM registrado).';
    } else if (str.contains('NetworkFailure')) {
      msg = 'No hay conexión con el servidor.';
    } else if (str.contains('DEVICE_NOT_FOUND')) {
      msg = 'Dispositivo no encontrado.';
    }
    state = state.copyWith(
      isSubmitting: false,
      errorMessage: msg,
      isPolling: false,
    );
  }

  void _startPolling(String commandId) {
    _pollAttempts = 0;
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      _pollAttempts++;

      if (_pollAttempts >= _maxPollAttempts) {
        timer.cancel();
        state = state.copyWith(
          isPolling: false,
          errorMessage: 'El comando tardó demasiado en responder (Expiró).',
        );
        return;
      }

      try {
        final getUseCase = _ref.read(getCommandUseCaseProvider);
        final latest = await getUseCase(commandId);

        state = state.copyWith(activeCommand: latest);

        if (latest.isFinal) {
          timer.cancel();
          state = state.copyWith(isPolling: false);
        }
      } catch (e) {
        // Silently retry polling unless final
      }
    });
  }

  void clearActiveCommand() {
    _pollingTimer?.cancel();
    state = CommandExecutionState.idle();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final commandNotifierProvider =
    StateNotifierProvider<CommandNotifier, CommandExecutionState>((ref) {
  return CommandNotifier(ref);
});

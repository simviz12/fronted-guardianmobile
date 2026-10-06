import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/command.dart';
import '../../domain/usecases/command_usecases.dart';
import 'command_provider.dart';

final getDeviceCommandsHistoryUseCaseProvider =
    Provider<GetDeviceCommandsHistoryUseCase>((ref) {
  return GetDeviceCommandsHistoryUseCase(ref.watch(commandRepositoryProvider));
});

class CommandHistoryState {
  final List<Command> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? nextCursor;
  final bool hasMore;
  final CommandType? selectedType;

  const CommandHistoryState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.nextCursor,
    this.hasMore = false,
    this.selectedType,
  });

  CommandHistoryState copyWith({
    List<Command>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    String? nextCursor,
    bool? hasMore,
    CommandType? selectedType,
    bool clearError = false,
    bool clearType = false,
  }) {
    return CommandHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
    );
  }
}

class CommandHistoryNotifier extends StateNotifier<CommandHistoryState> {
  final Ref _ref;
  final String _deviceId;

  CommandHistoryNotifier(this._ref, this._deviceId)
      : super(const CommandHistoryState());

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final useCase = _ref.read(getDeviceCommandsHistoryUseCaseProvider);
      final page = await useCase(
        deviceId: _deviceId,
        limit: 15,
        type: state.selectedType,
      );

      state = state.copyWith(
        items: page.items,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar el historial de órdenes.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final useCase = _ref.read(getDeviceCommandsHistoryUseCaseProvider);
      final page = await useCase(
        deviceId: _deviceId,
        limit: 15,
        cursor: state.nextCursor,
        type: state.selectedType,
      );

      state = state.copyWith(
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void filterByType(CommandType? type) {
    if (state.selectedType == type) return;
    if (type == null) {
      state = state.copyWith(clearType: true, items: [], nextCursor: null, hasMore: false);
    } else {
      state = state.copyWith(selectedType: type, items: [], nextCursor: null, hasMore: false);
    }
    loadInitial();
  }
}

final commandHistoryNotifierProvider = StateNotifierProvider.family<
    CommandHistoryNotifier, CommandHistoryState, String>((ref, deviceId) {
  return CommandHistoryNotifier(ref, deviceId);
});

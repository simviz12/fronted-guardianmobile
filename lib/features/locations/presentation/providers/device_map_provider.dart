import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/location_remote_data_source.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/entities/device_location.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/location_usecases.dart';

final locationRemoteDataSourceProvider = Provider<LocationRemoteDataSource>((ref) {
  final client = ref.watch(authenticatedDioClientProvider);
  return LocationRemoteDataSourceImpl(client: client);
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final remoteDataSource = ref.watch(locationRemoteDataSourceProvider);
  return LocationRepositoryImpl(remoteDataSource: remoteDataSource);
});

final getLocationsUseCaseProvider = Provider<GetLocationsUseCase>((ref) {
  final repo = ref.watch(locationRepositoryProvider);
  return GetLocationsUseCase(repo);
});

final getLatestLocationUseCaseProvider = Provider<GetLatestLocationUseCase>((ref) {
  final repo = ref.watch(locationRepositoryProvider);
  return GetLatestLocationUseCase(repo);
});

enum LocationRangeFilter {
  today,
  yesterday,
  last7Days;

  String get label {
    switch (this) {
      case LocationRangeFilter.today:
        return 'Hoy';
      case LocationRangeFilter.yesterday:
        return 'Ayer';
      case LocationRangeFilter.last7Days:
        return 'Últimos 7 días';
    }
  }

  (DateTime from, DateTime to) calculateBounds() {
    final now = DateTime.now();
    switch (this) {
      case LocationRangeFilter.today:
        final from = DateTime(now.year, now.month, now.day);
        final to = now;
        return (from, to);
      case LocationRangeFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        final from = DateTime(yesterday.year, yesterday.month, yesterday.day);
        final to = DateTime(now.year, now.month, now.day).subtract(const Duration(milliseconds: 1));
        return (from, to);
      case LocationRangeFilter.last7Days:
        final from = now.subtract(const Duration(days: 7));
        final to = now;
        return (from, to);
    }
  }
}

class DeviceMapState {
  final bool isLoading;
  final String? errorMessage;
  final DeviceLocation? latestLocation;
  final List<DeviceLocation> history;
  final LocationRangeFilter selectedRange;
  final DeviceLocation? selectedPoint;

  const DeviceMapState({
    this.isLoading = false,
    this.errorMessage,
    this.latestLocation,
    this.history = const [],
    this.selectedRange = LocationRangeFilter.today,
    this.selectedPoint,
  });

  DeviceMapState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    DeviceLocation? latestLocation,
    List<DeviceLocation>? history,
    LocationRangeFilter? selectedRange,
    DeviceLocation? selectedPoint,
    bool clearSelectedPoint = false,
  }) {
    return DeviceMapState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      latestLocation: latestLocation ?? this.latestLocation,
      history: history ?? this.history,
      selectedRange: selectedRange ?? this.selectedRange,
      selectedPoint: clearSelectedPoint ? null : (selectedPoint ?? this.selectedPoint),
    );
  }
}

class DeviceMapNotifier extends StateNotifier<DeviceMapState> {
  final Ref _ref;
  final String _deviceId;

  DeviceMapNotifier(this._ref, this._deviceId) : super(const DeviceMapState()) {
    loadMapData();
  }

  Future<void> loadMapData({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final latestUseCase = _ref.read(getLatestLocationUseCaseProvider);
      final historyUseCase = _ref.read(getLocationsUseCaseProvider);

      DeviceLocation? latest;
      try {
        latest = await latestUseCase(deviceId: _deviceId);
      } catch (_) {
        // May be 404 NO_LOCATION_YET
      }

      final bounds = state.selectedRange.calculateBounds();
      final history = await historyUseCase(
        deviceId: _deviceId,
        from: bounds.$1,
        to: bounds.$2,
        limit: 100,
      );

      state = state.copyWith(
        isLoading: false,
        clearError: true,
        latestLocation: latest ?? (history.isNotEmpty ? history.first : null),
        history: history,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar ubicaciones: ${e.toString()}',
      );
    }
  }

  Future<void> changeRange(LocationRangeFilter range) async {
    state = state.copyWith(selectedRange: range, isLoading: true, clearError: true);
    try {
      final bounds = range.calculateBounds();
      final historyUseCase = _ref.read(getLocationsUseCaseProvider);
      final history = await historyUseCase(
        deviceId: _deviceId,
        from: bounds.$1,
        to: bounds.$2,
        limit: 100,
      );

      state = state.copyWith(
        isLoading: false,
        history: history,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al filtrar historial: ${e.toString()}',
      );
    }
  }

  void selectPoint(DeviceLocation? point) {
    if (point == null) {
      state = state.copyWith(clearSelectedPoint: true);
    } else {
      state = state.copyWith(selectedPoint: point);
    }
  }
}

final deviceMapProvider = StateNotifierProvider.family<DeviceMapNotifier, DeviceMapState, String>(
  (ref, deviceId) => DeviceMapNotifier(ref, deviceId),
);

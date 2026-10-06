import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/native_bridge_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/device_identity_service.dart';
import '../../data/datasources/device_remote_data_source.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/usecases/device_usecases.dart';

// Services
final nativeBridgeServiceProvider = Provider<NativeBridgeService>((ref) {
  return NativeBridgeServiceImpl();
});

final deviceIdentityServiceProvider = Provider<DeviceIdentityService>((ref) {
  return DeviceIdentityServiceImpl();
});

// Remote DataSource
final deviceRemoteDataSourceProvider = Provider<DeviceRemoteDataSource>((ref) {
  final dioClient = ref.watch(authenticatedDioClientProvider);
  return DeviceRemoteDataSourceImpl(client: dioClient);
});

// Repository
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final remoteDataSource = ref.watch(deviceRemoteDataSourceProvider);
  final identityService = ref.watch(deviceIdentityServiceProvider);
  final nativeBridgeService = ref.watch(nativeBridgeServiceProvider);
  return DeviceRepositoryImpl(
    remoteDataSource: remoteDataSource,
    identityService: identityService,
    nativeBridgeService: nativeBridgeService,
  );
});

// Use Cases
final linkCurrentDeviceUseCaseProvider = Provider<LinkCurrentDeviceUseCase>((ref) {
  return LinkCurrentDeviceUseCase(ref.watch(deviceRepositoryProvider));
});

final updateFcmTokenUseCaseProvider = Provider<UpdateFcmTokenUseCase>((ref) {
  return UpdateFcmTokenUseCase(ref.watch(deviceRepositoryProvider));
});

final listDevicesUseCaseProvider = Provider<ListDevicesUseCase>((ref) {
  return ListDevicesUseCase(ref.watch(deviceRepositoryProvider));
});

final renameDeviceUseCaseProvider = Provider<RenameDeviceUseCase>((ref) {
  return RenameDeviceUseCase(ref.watch(deviceRepositoryProvider));
});

final unlinkDeviceUseCaseProvider = Provider<UnlinkDeviceUseCase>((ref) {
  return UnlinkDeviceUseCase(ref.watch(deviceRepositoryProvider));
});

final getThisPhoneDeviceIdUseCaseProvider = Provider<GetThisPhoneDeviceIdUseCase>((ref) {
  return GetThisPhoneDeviceIdUseCase(ref.watch(deviceRepositoryProvider));
});

// Device Install Info Future Provider (for LinkDevicePage initial pre-fill)
final deviceInstallInfoProvider = FutureProvider<DeviceInstallInfo>((ref) {
  return ref.watch(deviceIdentityServiceProvider).getInstallInfo();
});

// State classes for Dashboard
class DevicesDashboardState {
  final List<Device> devices;
  final String? thisPhoneDeviceId;
  final bool isLoading;
  final String? errorMessage;

  const DevicesDashboardState({
    required this.devices,
    this.thisPhoneDeviceId,
    this.isLoading = false,
    this.errorMessage,
  });

  factory DevicesDashboardState.initial() => const DevicesDashboardState(
        devices: [],
        isLoading: true,
      );

  Device? get thisPhoneDevice {
    if (thisPhoneDeviceId == null) return null;
    try {
      return devices.firstWhere((d) => d.id == thisPhoneDeviceId);
    } catch (_) {
      return null;
    }
  }

  List<Device> get otherDevices {
    if (thisPhoneDeviceId == null) return devices;
    return devices.where((d) => d.id != thisPhoneDeviceId).toList();
  }

  DevicesDashboardState copyWith({
    List<Device>? devices,
    String? thisPhoneDeviceId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DevicesDashboardState(
      devices: devices ?? this.devices,
      thisPhoneDeviceId: thisPhoneDeviceId ?? this.thisPhoneDeviceId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// Notifier
class DevicesNotifier extends StateNotifier<DevicesDashboardState> {
  final Ref _ref;

  DevicesNotifier(this._ref) : super(DevicesDashboardState.initial()) {
    loadDevices();
  }

  Future<void> loadDevices() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final listUseCase = _ref.read(listDevicesUseCaseProvider);
      final getThisPhoneUseCase = _ref.read(getThisPhoneDeviceIdUseCaseProvider);

      final devices = await listUseCase();
      final thisPhoneId = await getThisPhoneUseCase();

      state = state.copyWith(
        devices: devices,
        thisPhoneDeviceId: thisPhoneId,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      String msg = 'Error al cargar dispositivos.';
      final str = e.toString();
      if (str.contains('NetworkFailure')) {
        msg = 'No hay conexión con el servidor.';
      } else if (str.contains('TimeoutFailure')) {
        msg = 'El servidor tardó demasiado en responder.';
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
    }
  }

  Future<bool> renameDevice(String id, String newName) async {
    try {
      final renameUseCase = _ref.read(renameDeviceUseCaseProvider);
      final updated = await renameUseCase(id: id, name: newName);

      final updatedList = state.devices.map((d) => d.id == id ? updated : d).toList();
      state = state.copyWith(devices: updatedList);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unlinkDevice(String id) async {
    try {
      final unlinkUseCase = _ref.read(unlinkDeviceUseCaseProvider);
      await unlinkUseCase(id);

      final updatedList = state.devices.where((d) => d.id != id).toList();
      String? newThisPhoneId = state.thisPhoneDeviceId;
      if (state.thisPhoneDeviceId == id) {
        newThisPhoneId = null;
      }

      state = state.copyWith(
        devices: updatedList,
        thisPhoneDeviceId: newThisPhoneId,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

final devicesNotifierProvider =
    StateNotifierProvider<DevicesNotifier, DevicesDashboardState>((ref) {
  return DevicesNotifier(ref);
});

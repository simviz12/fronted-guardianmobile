import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/server_status_remote_data_source.dart';
import '../../data/repositories/server_status_repository_impl.dart';
import '../../domain/entities/server_status.dart';
import '../../domain/repositories/server_status_repository.dart';
import '../../domain/usecases/check_server_status.dart';

// Network
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

// DataSource
final serverStatusRemoteDataSourceProvider =
    Provider<ServerStatusRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ServerStatusRemoteDataSourceImpl(client: dioClient);
});

// Repository
final serverStatusRepositoryProvider = Provider<ServerStatusRepository>((ref) {
  final remoteDataSource = ref.watch(serverStatusRemoteDataSourceProvider);
  return ServerStatusRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Use Case
final checkServerStatusUseCaseProvider = Provider<CheckServerStatus>((ref) {
  final repository = ref.watch(serverStatusRepositoryProvider);
  return CheckServerStatus(repository);
});

// Notifier / State
final serverStatusNotifierProvider =
    AsyncNotifierProvider<ServerStatusNotifier, ServerStatus>(
  ServerStatusNotifier.new,
);

class ServerStatusNotifier extends AsyncNotifier<ServerStatus> {
  @override
  Future<ServerStatus> build() async {
    return _checkStatus();
  }

  Future<ServerStatus> _checkStatus() async {
    final useCase = ref.read(checkServerStatusUseCaseProvider);
    return await useCase();
  }

  Future<void> retry() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _checkStatus());
  }
}

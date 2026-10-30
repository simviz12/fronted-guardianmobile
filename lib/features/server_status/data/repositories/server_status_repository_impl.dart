import '../../domain/entities/server_status.dart';
import '../../domain/repositories/server_status_repository.dart';
import '../datasources/server_status_remote_data_source.dart';

class ServerStatusRepositoryImpl implements ServerStatusRepository {
  final ServerStatusRemoteDataSource remoteDataSource;

  ServerStatusRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ServerStatus> checkStatus() async {
    final dto = await remoteDataSource.getHealth();
    return dto.toEntity();
  }
}

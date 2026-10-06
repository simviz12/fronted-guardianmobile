import '../entities/server_status.dart';
import '../repositories/server_status_repository.dart';

class CheckServerStatus {
  final ServerStatusRepository repository;

  CheckServerStatus(this.repository);

  Future<ServerStatus> call() async {
    return await repository.checkStatus();
  }
}

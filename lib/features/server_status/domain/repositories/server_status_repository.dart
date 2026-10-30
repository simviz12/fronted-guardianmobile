import '../entities/server_status.dart';

abstract interface class ServerStatusRepository {
  Future<ServerStatus> checkStatus();
}

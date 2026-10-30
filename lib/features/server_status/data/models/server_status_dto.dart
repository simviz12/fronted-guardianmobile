import '../../domain/entities/server_status.dart';

class ServerStatusDto {
  final String status;
  final String service;
  final String version;
  final String time;
  final String database;

  const ServerStatusDto({
    required this.status,
    required this.service,
    required this.version,
    required this.time,
    required this.database,
  });

  factory ServerStatusDto.fromJson(Map<String, dynamic> json) {
    return ServerStatusDto(
      status: json['status'] as String? ?? '',
      service: json['service'] as String? ?? '',
      version: json['version'] as String? ?? '',
      time: json['time'] as String? ?? '',
      database: json['database'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'service': service,
      'version': version,
      'time': time,
      'database': database,
    };
  }

  ServerStatus toEntity() {
    return ServerStatus(
      status: status,
      service: service,
      version: version,
      time: DateTime.tryParse(time) ?? DateTime.now(),
      database: database,
    );
  }
}

class ServerStatus {
  final String status;
  final String service;
  final String version;
  final DateTime time;
  final String database;

  const ServerStatus({
    required this.status,
    required this.service,
    required this.version,
    required this.time,
    required this.database,
  });

  bool get isDatabaseUp => database.toLowerCase() == 'up';
}

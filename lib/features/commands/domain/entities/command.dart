enum CommandType {
  ring,
  vibrate,
  locate,
  lock,
  message;

  String toContractString() {
    switch (this) {
      case CommandType.ring:
        return 'RING';
      case CommandType.vibrate:
        return 'VIBRATE';
      case CommandType.locate:
        return 'LOCATE';
      case CommandType.lock:
        return 'LOCK';
      case CommandType.message:
        return 'MESSAGE';
    }
  }

  static CommandType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'RING':
        return CommandType.ring;
      case 'VIBRATE':
        return CommandType.vibrate;
      case 'LOCATE':
        return CommandType.locate;
      case 'LOCK':
        return CommandType.lock;
      case 'MESSAGE':
        return CommandType.message;
      default:
        return CommandType.ring;
    }
  }
}

enum CommandStatus {
  pending,
  delivered,
  executed,
  failed,
  expired;

  String toContractString() {
    return name.toUpperCase();
  }

  static CommandStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'PENDING':
        return CommandStatus.pending;
      case 'DELIVERED':
        return CommandStatus.delivered;
      case 'EXECUTED':
        return CommandStatus.executed;
      case 'FAILED':
        return CommandStatus.failed;
      case 'EXPIRED':
        return CommandStatus.expired;
      default:
        return CommandStatus.pending;
    }
  }
}

class Command {
  final String id;
  final String deviceId;
  final CommandType type;
  final CommandStatus status;
  final Map<String, dynamic> payload;
  final String? failureReason;
  final DateTime issuedAt;
  final DateTime? deliveredAt;
  final DateTime? executedAt;
  final int ttl;

  const Command({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.status,
    required this.payload,
    this.failureReason,
    required this.issuedAt,
    this.deliveredAt,
    this.executedAt,
    required this.ttl,
  });

  bool get isFinal =>
      status == CommandStatus.executed ||
      status == CommandStatus.failed ||
      status == CommandStatus.expired;

  Command copyWith({
    String? id,
    String? deviceId,
    CommandType? type,
    CommandStatus? status,
    Map<String, dynamic>? payload,
    String? failureReason,
    DateTime? issuedAt,
    DateTime? deliveredAt,
    DateTime? executedAt,
    int? ttl,
  }) {
    return Command(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      type: type ?? this.type,
      status: status ?? this.status,
      payload: payload ?? this.payload,
      failureReason: failureReason ?? this.failureReason,
      issuedAt: issuedAt ?? this.issuedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      executedAt: executedAt ?? this.executedAt,
      ttl: ttl ?? this.ttl,
    );
  }
}

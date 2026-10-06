import '../../domain/entities/command.dart';

class CommandDto {
  final String id;
  final String deviceId;
  final String type;
  final String status;
  final Map<String, dynamic> payload;
  final String? failureReason;
  final String issuedAt;
  final String? deliveredAt;
  final String? executedAt;
  final int ttl;

  const CommandDto({
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

  factory CommandDto.fromJson(Map<String, dynamic> json) {
    return CommandDto(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      failureReason: json['failureReason'] as String?,
      issuedAt: json['issuedAt'] as String,
      deliveredAt: json['deliveredAt'] as String?,
      executedAt: json['executedAt'] as String?,
      ttl: (json['ttl'] as num?)?.toInt() ?? 120,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'type': type,
      'status': status,
      'payload': payload,
      'failureReason': failureReason,
      'issuedAt': issuedAt,
      'deliveredAt': deliveredAt,
      'executedAt': executedAt,
      'ttl': ttl,
    };
  }

  Command toEntity() {
    return Command(
      id: id,
      deviceId: deviceId,
      type: CommandType.fromString(type),
      status: CommandStatus.fromString(status),
      payload: payload,
      failureReason: failureReason,
      issuedAt: DateTime.parse(issuedAt),
      deliveredAt: deliveredAt != null ? DateTime.tryParse(deliveredAt!) : null,
      executedAt: executedAt != null ? DateTime.tryParse(executedAt!) : null,
      ttl: ttl,
    );
  }
}

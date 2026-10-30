import 'package:guardian_mobile/features/theft_mode/domain/entities/theft_mode_config.dart';

class TheftModeConfigDto {
  final String id;
  final String deviceId;
  final String message;
  final String? contactPhone;
  final int locationIntervalSeconds;
  final bool alarm;
  final bool lock;
  final String activatedAt;
  final String? deactivatedAt;

  const TheftModeConfigDto({
    required this.id,
    required this.deviceId,
    required this.message,
    this.contactPhone,
    required this.locationIntervalSeconds,
    required this.alarm,
    required this.lock,
    required this.activatedAt,
    this.deactivatedAt,
  });

  factory TheftModeConfigDto.fromJson(Map<String, dynamic> json) {
    return TheftModeConfigDto(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      message: json['message'] as String,
      contactPhone: json['contactPhone'] as String?,
      locationIntervalSeconds: (json['locationIntervalSeconds'] as num?)?.toInt() ?? 60,
      alarm: json['alarm'] as bool? ?? false,
      lock: json['lock'] as bool? ?? false,
      activatedAt: json['activatedAt'] as String,
      deactivatedAt: json['deactivatedAt'] as String?,
    );
  }

  TheftModeConfig toEntity() {
    return TheftModeConfig(
      id: id,
      deviceId: deviceId,
      message: message,
      contactPhone: contactPhone,
      locationIntervalSeconds: locationIntervalSeconds,
      alarm: alarm,
      lock: lock,
      activatedAt: DateTime.tryParse(activatedAt) ?? DateTime.now(),
      deactivatedAt: deactivatedAt != null ? DateTime.tryParse(deactivatedAt!) : null,
    );
  }
}

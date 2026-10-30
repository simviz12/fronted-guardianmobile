class TheftModeConfig {
  final String id;
  final String deviceId;
  final String message;
  final String? contactPhone;
  final int locationIntervalSeconds;
  final bool alarm;
  final bool lock;
  final DateTime activatedAt;
  final DateTime? deactivatedAt;

  const TheftModeConfig({
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

  bool get isActive => deactivatedAt == null;
}

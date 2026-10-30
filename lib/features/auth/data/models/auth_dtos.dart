import '../../domain/entities/user.dart';

class UserDto {
  final String id;
  final String email;
  final String displayName;
  final String? createdAt;
  final bool twoFactorEnabled;

  const UserDto({
    required this.id,
    required this.email,
    required this.displayName,
    this.createdAt,
    this.twoFactorEnabled = false,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      if (createdAt != null) 'createdAt': createdAt,
      'twoFactorEnabled': twoFactorEnabled,
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
      twoFactorEnabled: twoFactorEnabled,
    );
  }
}

class AuthResponseDto {
  final UserDto user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthResponseDto({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: json['expiresIn'] as int? ?? 900,
    );
  }

  AuthSession toEntity() {
    return AuthSession(
      user: user.toEntity(),
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
    );
  }
}

class TokenRefreshResponseDto {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const TokenRefreshResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory TokenRefreshResponseDto.fromJson(Map<String, dynamic> json) {
    return TokenRefreshResponseDto(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: json['expiresIn'] as int? ?? 900,
    );
  }
}

/// Returned by POST /auth/login when user has 2FA enabled
class TwoFactorLoginPendingDto {
  final bool requiresTwoFactor;
  final String twoFactorToken;

  const TwoFactorLoginPendingDto({
    required this.requiresTwoFactor,
    required this.twoFactorToken,
  });

  factory TwoFactorLoginPendingDto.fromJson(Map<String, dynamic> json) {
    return TwoFactorLoginPendingDto(
      requiresTwoFactor: json['requiresTwoFactor'] as bool? ?? false,
      twoFactorToken: json['twoFactorToken'] as String? ?? '',
    );
  }
}

/// Returned by POST /auth/2fa/setup
class TwoFactorSetupDto {
  final String otpauthUrl;
  final String secret;

  const TwoFactorSetupDto({required this.otpauthUrl, required this.secret});

  factory TwoFactorSetupDto.fromJson(Map<String, dynamic> json) {
    return TwoFactorSetupDto(
      otpauthUrl: json['otpauthUrl'] as String? ?? '',
      secret: json['secret'] as String? ?? '',
    );
  }
}

/// Returned by POST /auth/2fa/enable
class TwoFactorEnableResultDto {
  final List<String> backupCodes;

  const TwoFactorEnableResultDto({required this.backupCodes});

  factory TwoFactorEnableResultDto.fromJson(Map<String, dynamic> json) {
    final raw = json['backupCodes'];
    final codes = raw is List ? raw.map((e) => e.toString()).toList() : <String>[];
    return TwoFactorEnableResultDto(backupCodes: codes);
  }
}

/// Returned by GET /auth/sessions
class ActiveSessionDto {
  final String id;
  final String? userAgent;
  final String? createdAt;
  final String? expiresAt;

  const ActiveSessionDto({
    required this.id,
    this.userAgent,
    this.createdAt,
    this.expiresAt,
  });

  factory ActiveSessionDto.fromJson(Map<String, dynamic> json) {
    return ActiveSessionDto(
      id: json['id'] as String? ?? '',
      userAgent: json['userAgent'] as String?,
      createdAt: json['createdAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
    );
  }
}


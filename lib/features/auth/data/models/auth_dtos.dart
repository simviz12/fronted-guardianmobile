import '../../domain/entities/user.dart';

class UserDto {
  final String id;
  final String email;
  final String displayName;
  final String? createdAt;

  const UserDto({
    required this.id,
    required this.email,
    required this.displayName,
    this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
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

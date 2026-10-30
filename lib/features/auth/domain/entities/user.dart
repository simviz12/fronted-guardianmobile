class User {
  final String id;
  final String email;
  final String displayName;
  final DateTime? createdAt;
  final bool twoFactorEnabled;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.createdAt,
    this.twoFactorEnabled = false,
  });

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    bool? twoFactorEnabled,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ displayName.hashCode;
}

class AuthSession {
  final User user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });
}

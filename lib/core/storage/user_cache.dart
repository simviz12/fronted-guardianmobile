import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/entities/user.dart';

/// Persists the last known user profile (non-sensitive data only) so the app
/// can open offline or while the backend on Render is still waking up,
/// instead of forcing the user back to the login screen.
class UserCache {
  UserCache._();

  static const _key = 'guardian_cached_user_v1';

  static Future<void> save(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'id': user.id,
          'email': user.email,
          'displayName': user.displayName,
          'createdAt': user.createdAt?.toIso8601String(),
          'twoFactorEnabled': user.twoFactorEnabled,
        }),
      );
    } catch (_) {
      // Cache is best-effort.
    }
  }

  static Future<User?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final id = json['id'];
      if (id is! String || id.isEmpty) return null;
      final createdAt = json['createdAt'];
      return User(
        id: id,
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
        twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}

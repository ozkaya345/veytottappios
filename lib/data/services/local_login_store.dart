import 'package:shared_preferences/shared_preferences.dart';

final class LocalLoginStore {
  const LocalLoginStore._();

  static const _keyRememberEmail = 'login_remember_email';
  static const _keyEmail = 'login_email';

  static Future<bool> isRememberEmailEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberEmail) ?? false;
  }

  /// Returns the remembered email only if remember-email is enabled.
  static Future<String?> loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyRememberEmail) ?? false;
    if (!enabled) return null;

    final email = prefs.getString(_keyEmail);
    if (email == null) return null;

    final trimmed = email.trim();
    if (trimmed.isEmpty) return null;

    return trimmed;
  }

  static Future<void> setRememberEmail({
    required bool enabled,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!enabled) {
      await prefs.setBool(_keyRememberEmail, false);
      await prefs.remove(_keyEmail);
      return;
    }

    await prefs.setBool(_keyRememberEmail, true);

    final trimmed = email?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      await prefs.setString(_keyEmail, trimmed);
    }
  }
}

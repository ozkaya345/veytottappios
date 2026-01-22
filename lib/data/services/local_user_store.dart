import 'package:shared_preferences/shared_preferences.dart';

final class LocalUserStore {
  const LocalUserStore._();

  static const _keyRegistered = 'user_registered';
  static const _keyFullName = 'user_full_name';
  static const _keyEmail = 'user_email';

  static Future<void> saveRegistration({
    required String fullName,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRegistered, true);
    await prefs.setString(_keyFullName, fullName);
    await prefs.setString(_keyEmail, email);
  }

  static Future<LocalRegistration?> getRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final isRegistered = prefs.getBool(_keyRegistered) ?? false;
    if (!isRegistered) return null;

    final fullName = prefs.getString(_keyFullName);
    final email = prefs.getString(_keyEmail);
    if (fullName == null || fullName.trim().isEmpty) return null;
    if (email == null || email.trim().isEmpty) return null;

    return LocalRegistration(fullName: fullName.trim(), email: email.trim());
  }
}

final class LocalRegistration {
  final String fullName;
  final String email;

  const LocalRegistration({required this.fullName, required this.email});
}

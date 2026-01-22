import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalLocaleStore {
  static const _languageCodeKey = 'locale_language_code';
  static const _countryCodeKey = 'locale_country_code';

  static Future<Locale?> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    if (languageCode == null || languageCode.isEmpty) return null;

    final countryCode = prefs.getString(_countryCodeKey);
    if (countryCode == null || countryCode.isEmpty) {
      return Locale(languageCode);
    }

    return Locale(languageCode, countryCode);
  }

  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, locale.languageCode);

    final countryCode = locale.countryCode;
    if (countryCode == null || countryCode.isEmpty) {
      await prefs.remove(_countryCodeKey);
    } else {
      await prefs.setString(_countryCodeKey, countryCode);
    }
  }

  static Future<void> clearLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageCodeKey);
    await prefs.remove(_countryCodeKey);
  }
}

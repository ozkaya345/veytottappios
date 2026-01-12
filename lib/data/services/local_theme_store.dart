import 'package:shared_preferences/shared_preferences.dart';

enum ThemeVariant { green, blue, red, orange, purple, mono }

class LocalThemeStore {
  static const _themeKey = 'app_theme_variant';

  static Future<ThemeVariant> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeKey);
    switch (value) {
      case 'blue':
        return ThemeVariant.blue;
      case 'red':
        return ThemeVariant.red;
      case 'orange':
        return ThemeVariant.orange;
      case 'purple':
        return ThemeVariant.purple;
      case 'mono':
        return ThemeVariant.mono;
      case 'green':
      default:
        return ThemeVariant.green;
    }
  }

  static Future<void> saveTheme(ThemeVariant variant) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (variant) {
      ThemeVariant.green => 'green',
      ThemeVariant.blue => 'blue',
      ThemeVariant.red => 'red',
      ThemeVariant.orange => 'orange',
      ThemeVariant.purple => 'purple',
      ThemeVariant.mono => 'mono',
    };
    await prefs.setString(_themeKey, value);
  }
}
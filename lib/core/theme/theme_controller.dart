import 'package:flutter/material.dart';
import '../../data/services/local_theme_store.dart';
import 'app_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  ThemeVariant _variant = ThemeVariant.green;

  ThemeVariant get variant => _variant;

  ThemeData get themeData => AppTheme.darkVariant(_variant);

  Future<void> init() async {
    _variant = await LocalThemeStore.loadTheme();
  }

  Future<void> setVariant(ThemeVariant variant) async {
    if (_variant == variant) return;
    _variant = variant;
    await LocalThemeStore.saveTheme(variant);
    notifyListeners();
  }
}
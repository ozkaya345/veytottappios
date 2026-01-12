import 'package:flutter/material.dart';
import '../../data/services/local_theme_store.dart';

final class AppTheme {
  const AppTheme._();

  // Legacy light theme (not used after dark variants added)
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
    );
  }

  static ThemeData darkVariant(ThemeVariant variant) {
    final Color seed = switch (variant) {
      ThemeVariant.green => Colors.green,
      ThemeVariant.blue => Colors.blue,
      ThemeVariant.red => Colors.red,
      ThemeVariant.orange => Colors.orange,
      ThemeVariant.purple => Colors.purple,
      ThemeVariant.mono => Colors.white,
    };
    final ColorScheme scheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: seed,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.black,
    );
  }
}

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
    // Bazı platform/renderer kombinasyonlarında (özellikle web) ikonların
    // görünmemesi genelde IconTheme/AppBarTheme renklerinin beklenmedik şekilde
    // override edilmesinden kaynaklanır. Burada açıkça set ederek deterministik
    // hale getiriyoruz.
    final iconTheme = IconThemeData(color: scheme.onSurface, size: 22);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.black,
      iconTheme: iconTheme,
      primaryIconTheme: IconThemeData(color: scheme.onPrimary, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
        iconTheme: iconTheme,
        actionsIconTheme: iconTheme,
      ),
    );
  }
}

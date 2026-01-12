import 'package:flutter/material.dart';
import 'package:ottapp/l10n/app_localizations.dart';

import 'core/localization/locale_controller.dart';
import 'data/services/firebase_bootstrap.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';
// import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Firebase hazır olmadan Auth/Firestore çağrıları ownerId/code gibi alanların null kalmasına yol açabiliyor.
    await FirebaseBootstrap.init();
  } catch (e, st) {
    // Firebase init hatasını gizlemeyelim; aksi halde "kaydet" her yerde bozulmuş gibi görünür.
    debugPrint('Firebase init FAILED: $e');
    debugPrintStack(stackTrace: st);
  }
  try {
    await LocaleController.instance.init();
  } catch (_) {
    // Locale yüklenemezse varsayılan sistem/dil kullanılır.
  }
  try {
    await ThemeController.instance.init();
  } catch (_) {
    // Tema yüklenemezse varsayılan (green) ile devam edilir.
  }
  runApp(const OttApp());
}

class OttApp extends StatelessWidget {
  const OttApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, __) {
        return AnimatedBuilder(
          animation: LocaleController.instance,
          builder: (context, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'OTT App',
              theme: ThemeController.instance.themeData,
              locale: LocaleController.instance.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              onGenerateRoute: AppRouter.onGenerateRoute,
              initialRoute: AppRoutes.splash,
            );
          },
        );
      },
    );
  }
}
  
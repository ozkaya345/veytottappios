import 'package:flutter/material.dart';

import '../../view/screens/home_screen.dart';
import '../../view/screens/splash_screen.dart';
import '../../view/screens/auth_gate_screen.dart';
import '../../view/screens/login_screen.dart';
import '../../view/screens/register_screen.dart';
import '../../view/screens/profile_screen.dart';
import '../../view/screens/settings_screen.dart';
import '../../view/screens/security_screen.dart';
import '../../view/screens/avatar_screen.dart';
import '../../view/screens/status_add_screen.dart';
import '../../view/screens/status_open_code_screen.dart';
import '../../view/screens/status_track_list_screen.dart';
import '../../view/screens/status_track_screen.dart';
import '../../view/screens/trash_screen.dart';
import '../../view/screens/personnel_screen.dart';
import 'app_routes.dart';

final class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      case AppRoutes.auth:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AuthGateScreen(),
        );
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case AppRoutes.register:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );
      case AppRoutes.profile:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ProfileScreen(),
        );
      case AppRoutes.settings:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );
      case AppRoutes.security:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SecurityScreen(),
        );
      case AppRoutes.avatar:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AvatarScreen(),
        );
      case AppRoutes.statusAdd:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const StatusAddScreen(),
        );
      case AppRoutes.statusOpenCode:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const StatusOpenCodeScreen(),
        );
      case AppRoutes.statusTrackList:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const StatusTrackListScreen(),
        );
      case AppRoutes.statusTrack:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            final arg = settings.arguments;
            if (arg is String && arg.isNotEmpty) {
              return StatusTrackScreen(tableId: arg);
            }
            if (arg is Map) {
              final title = arg['title'];
              if (title is String && title.trim().isNotEmpty) {
                return StatusTrackScreen(initialTitle: title.trim());
              }
            }
            return const StatusTrackScreen();
          },
        );
      case AppRoutes.trash:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const TrashScreen(),
        );
      case AppRoutes.personnel:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const PersonnelScreen(),
        );
      case AppRoutes.home:
      case null:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Sayfa bulunamadı')),
            body: Center(child: Text('Route: ${settings.name}')),
          ),
        );
    }
  }
}

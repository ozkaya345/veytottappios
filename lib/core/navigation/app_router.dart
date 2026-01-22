import 'package:flutter/material.dart';

import '../../view/screens/home_screen.dart';
import '../../view/screens/splash_screen.dart';
import '../../view/screens/auth_gate_screen.dart';
import '../../view/screens/login_screen.dart';
import '../../view/screens/forgot_password_screen.dart';
import '../../view/screens/reset_password_screen.dart';
import '../../view/screens/register_screen.dart';
import '../../view/screens/profile_screen.dart';
import '../../view/screens/settings_screen.dart';
import '../../view/screens/security_screen.dart';
import '../../view/screens/admin_login_screen.dart';
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
      case AppRoutes.forgotPassword:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            final arg = settings.arguments;
            final String? initialEmail = arg is String && arg.trim().isNotEmpty
                ? arg.trim()
                : null;
            return ForgotPasswordScreen(initialEmail: initialEmail);
          },
        );
      case AppRoutes.resetPassword:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            final arg = settings.arguments;
            String? oobCode;

            if (arg is String && arg.trim().isNotEmpty) {
              oobCode = arg.trim();
            } else if (arg is Map) {
              final v = arg['oobCode'];
              if (v is String && v.trim().isNotEmpty) {
                oobCode = v.trim();
              }
            }

            if (oobCode == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Şifre sıfırlama bağlantısı geçersiz.'),
                ),
              );
            }

            return ResetPasswordScreen(oobCode: oobCode);
          },
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
      case AppRoutes.adminLogin:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminLoginScreen(),
        );
      case AppRoutes.statusAdd:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            final arg = settings.arguments;
            final bool useAdminAuth =
                (arg is Map && arg['useAdminAuth'] == true);
            return StatusAddScreen(useAdminAuth: useAdminAuth);
          },
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
              // Trans Takip yolu: her zaman salt-okunur aç.
              return StatusTrackScreen(tableId: arg, readOnly: true);
            }

            if (arg is Map) {
              final tableId = arg['tableId'];
              final title = arg['title'];
              final dynamic ro = arg['readOnly'];
              final bool readOnly = ro is bool ? ro : true;

              final String? parsedTableId =
                  tableId is String && tableId.trim().isNotEmpty
                      ? tableId.trim()
                      : null;
              final String? parsedTitle = title is String && title.trim().isNotEmpty
                  ? title.trim()
                  : null;

              return StatusTrackScreen(
                tableId: parsedTableId,
                initialTitle: parsedTitle,
                readOnly: readOnly,
              );
            }

            return const StatusTrackScreen(readOnly: true);
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

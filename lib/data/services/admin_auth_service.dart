import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import 'firebase_bootstrap.dart';

/// Provides a separate FirebaseAuth session for admin operations.
/// This allows normal users to stay signed in while admin signs in/out independently.
final class AdminAuthService {
  AdminAuthService._();

  static const String _adminAppName = 'admin';

  static Future<FirebaseApp> ensureAdminAppInitialized() async {
    // Ensure default app is initialized first.
    await FirebaseBootstrap.init();

    for (final app in Firebase.apps) {
      if (app.name == _adminAppName) return app;
    }

    return Firebase.initializeApp(
      name: _adminAppName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static Future<FirebaseAuth> adminAuth() async {
    final app = await ensureAdminAppInitialized();
    return FirebaseAuth.instanceFor(app: app);
  }
}

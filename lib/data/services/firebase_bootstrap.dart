import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../../firebase_options.dart';

final class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (Firebase.apps.isNotEmpty) {
      return;
    }

    FirebaseOptions options;
    try {
      options = DefaultFirebaseOptions.currentPlatform;
    } on UnimplementedError {
      throw StateError(
        'Firebase ayarları eksik. Çözüm: `flutterfire configure` çalıştırıp '
        '`lib/firebase_options.dart` dosyasını üretin.',
      );
    } on UnsupportedError catch (e) {
      throw StateError(
        'Firebase ayarları bu platform için eksik: $e\n'
        'Çözüm: `flutterfire configure` çalıştırıp Windows dahil platformları seçin ve '
        '`lib/firebase_options.dart` dosyasını yeniden üretin.',
      );
    }

    await Firebase.initializeApp(options: options);
  }
}

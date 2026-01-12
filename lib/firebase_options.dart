import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// FirebaseOptions, `mesajlar-a48b6` projesi için üretilmiştir.
/// Not: Bu dosyada Windows için ayrıca bir Firebase app kaydı yoksa,
/// geçici olarak Web ayarları kullanılır. En doğru çözüm: `flutterfire configure`
/// ile Windows'u da seçip bu dosyayı yeniden üretmektir.
final class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        // Desktop için en doğru yol flutterfire configure ile windows app üretmektir.
        // Geçici workaround: web ayarlarıyla init.
        return web;
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Bu platform için FirebaseOptions tanımlı değil.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC5M3vCJJLD2C8an2EJ1lsZ2FXAEaa2vt4',
    appId: '1:773952414668:web:eb985fd71404515d16b369',
    messagingSenderId: '773952414668',
    projectId: 'mesajlar-a48b6',
    authDomain: 'mesajlar-a48b6.firebaseapp.com',
    databaseURL: 'https://mesajlar-a48b6-default-rtdb.firebaseio.com',
    storageBucket: 'mesajlar-a48b6.firebasestorage.app',
    measurementId: 'G-HS0HV2PQ8X',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2_dqJqV2ANw7Fo7egQayvIu8B02QPkJM',
    appId: '1:773952414668:android:6368d054e22f3ffb16b369',
    messagingSenderId: '773952414668',
    projectId: 'mesajlar-a48b6',
    databaseURL: 'https://mesajlar-a48b6-default-rtdb.firebaseio.com',
    storageBucket: 'mesajlar-a48b6.firebasestorage.app',
  );
}

import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  const StorageService._();

  static Future<String> uploadAvatar(
    Uint8List bytes, {
    String? uid,
    String contentType = 'image/jpeg',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = uid ?? user?.uid;
    if (userId == null || userId.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'Kullanıcı oturumu bulunamadı',
      );
    }

    final storage = FirebaseStorage.instance;
    final ext = _extensionFromContentType(contentType);
    final ref = storage.ref().child('avatars/$userId/avatar.$ext');
    // Aynı Storage path + aynı download URL ile agresif cache yüzünden kullanıcı “değişmedi” sanabiliyor.
    // Bu yüzden max-age=0 + URL’ye cache-bust parametresi ekliyoruz.
    final metadata = SettableMetadata(
      contentType: contentType,
      cacheControl: 'public,max-age=0',
    );
    await ref.putData(bytes, metadata);
    final url = await ref.getDownloadURL();

    final cacheBustedUrl = _appendCacheBust(url);

    // Kullanıcının photoURL’ini güncelle
    await user?.updatePhotoURL(cacheBustedUrl);
    await user?.reload();
    return cacheBustedUrl;
  }

  static String _extensionFromContentType(String contentType) {
    final ct = contentType.toLowerCase().trim();
    if (ct.contains('png')) return 'png';
    if (ct.contains('webp')) return 'webp';
    if (ct.contains('gif')) return 'gif';
    if (ct.contains('heic') || ct.contains('heif')) return 'heic';
    return 'jpg';
  }

  static String _appendCacheBust(String url) {
    final v = DateTime.now().millisecondsSinceEpoch;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=$v';
  }

  static Future<bool> deleteAvatar({String? uid}) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = uid ?? user?.uid;
    if (userId == null || userId.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'Kullanıcı oturumu bulunamadı',
      );
    }

    final storage = FirebaseStorage.instance;

    // Yeni yol: avatars/<uid>/avatar.<ext>
    // Eski yol: avatars/<uid>.jpg
    final refs = <Reference>[
      storage.ref().child('avatars/$userId.jpg'),
      storage.ref().child('avatars/$userId/avatar.jpg'),
      storage.ref().child('avatars/$userId/avatar.jpeg'),
      storage.ref().child('avatars/$userId/avatar.png'),
      storage.ref().child('avatars/$userId/avatar.webp'),
      storage.ref().child('avatars/$userId/avatar.gif'),
      storage.ref().child('avatars/$userId/avatar.heic'),
    ];

    var deletedAny = false;
    for (final ref in refs) {
      try {
        await ref.delete();
        deletedAny = true;
      } on FirebaseException catch (e) {
        // Obje yoksa sorun değil. Diğer hatalarda da kaldırma akışını bozmayalım.
        // (Örn. permission-denied vs.)
        if (e.code == 'object-not-found' || e.code == 'not-found') {
          continue;
        }
      } catch (_) {
        // ignore
      }
    }
    return deletedAny;
  }
}

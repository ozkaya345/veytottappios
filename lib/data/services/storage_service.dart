import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  const StorageService._();

  static Future<String> uploadAvatar(Uint8List bytes, {String? uid, String contentType = 'image/jpeg'}) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = uid ?? user?.uid;
    if (userId == null || userId.isEmpty) {
      throw FirebaseException(plugin: 'firebase_auth', message: 'Kullanıcı oturumu bulunamadı');
    }

    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child('avatars/$userId.jpg');
    final metadata = SettableMetadata(contentType: contentType, cacheControl: 'public,max-age=3600');
    await ref.putData(bytes, metadata);
    final url = await ref.getDownloadURL();

    // Kullanıcının photoURL’ini güncelle
    await user?.updatePhotoURL(url);
    await user?.reload();
    return url;
  }
}
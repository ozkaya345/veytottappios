import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/services/storage_service.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  bool _isSaving = false;
  String? _message;
  final ImagePicker _picker = ImagePicker();
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _photoUrl = user?.photoURL;
  }

  bool get _supportsGalleryPicker {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => true,
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  String _contentTypeFromExtension(String? ext) {
    final e = (ext ?? '').toLowerCase().trim();
    return switch (e) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' || 'heif' => 'image/heic',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };
  }

  String? _extensionFromName(String? name) {
    if (name == null) return null;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return null;
    return name.substring(dot + 1);
  }

  Future<void> _pickFromGallery() async {
    setState(() => _message = null);
    try {
      setState(() => _isSaving = true);
      if (!_supportsGalleryPicker) {
        // Windows/Linux gibi platformlarda image_picker galeri seçimi plugin olarak yok.
        await _pickFromFiles();
        return;
      }
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
      );
      if (xfile == null) {
        setState(() => _isSaving = false);
        return;
      }
      final Uint8List bytes = await xfile.readAsBytes();
      final contentType =
          xfile.mimeType ??
          _contentTypeFromExtension(_extensionFromName(xfile.name));
      final String url = await StorageService.uploadAvatar(
        bytes,
        contentType: contentType,
      );
      setState(() {
        _message = 'Avatar güncellendi';
        _photoUrl = url;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Galeri hatası: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _pickFromFiles() async {
    setState(() => _message = null);
    try {
      setState(() => _isSaving = true);
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        withReadStream: true,
      );
      if (result == null) {
        setState(() => _isSaving = false);
        return;
      }
      final PlatformFile file = result.files.first;
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.readStream != null) {
        final buffer = <int>[];
        await for (final chunk in file.readStream!) {
          buffer.addAll(chunk);
        }
        bytes = Uint8List.fromList(buffer);
      }
      if (bytes == null) {
        setState(() {
          _message = 'Dosya okunamadı';
          _isSaving = false;
        });
        return;
      }
      final String contentType = _contentTypeFromExtension(file.extension);
      final String url = await StorageService.uploadAvatar(
        bytes,
        contentType: contentType,
      );
      setState(() {
        _message = 'Avatar güncellendi';
        _photoUrl = url;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Dosya seçimi hatası: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _isSaving = true;
      _message = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'Oturum bulunamadı',
        );
      }

      // Storage’daki avatar dosyasını da temizlemeyi dene (başarısız olsa bile devam).
      try {
        await StorageService.deleteAvatar(uid: user.uid);
      } catch (_) {}

      await user.updatePhotoURL(null);
      await user.reload();
      setState(() {
        _photoUrl = null;
        _message = 'Avatar kaldırıldı';
        _isSaving = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = e.message ?? 'İşlem başarısız';
        _isSaving = false;
      });
    } catch (_) {
      setState(() {
        _message = 'Beklenmedik bir hata oluştu';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Avatar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 0.75, 1.0],
                  colors: [
                    Colors.black,
                    primary.withValues(alpha: 0.35),
                    primary.withValues(alpha: 0.70),
                    primary,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          backgroundImage:
                              (_photoUrl != null && _photoUrl!.isNotEmpty)
                              ? NetworkImage(_photoUrl!)
                              : null,
                          child: (_photoUrl == null || _photoUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 32)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Fotoğraf seçince otomatik kaydedilir.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isSaving
                              ? null
                              : (_supportsGalleryPicker
                                    ? _pickFromGallery
                                    : _pickFromFiles),
                          icon: const Icon(Icons.photo_library),
                          label: Text(
                            _supportsGalleryPicker
                                ? 'Galeriden Seç'
                                : 'Dosyadan Seç',
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _pickFromFiles,
                          icon: const Icon(Icons.folder_open),
                          label: Text(kIsWeb ? 'Dosya Seç' : 'Dosyadan Seç'),
                        ),
                        const Spacer(),
                        if (_isSaving)
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          TextButton(
                            onPressed: _photoUrl == null ? null : _removeAvatar,
                            child: const Text('Kaldır'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_message != null) Text(_message!),
                    const SizedBox(height: 16),
                    const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

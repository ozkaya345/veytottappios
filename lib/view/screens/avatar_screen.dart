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
  final _urlController = TextEditingController();
  bool _isSaving = false;
  String? _message;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _urlController.text = user?.photoURL ?? '';
  }

  Future<void> _pickFromGallery() async {
    setState(() => _message = null);
    try {
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
      );
      if (xfile == null) return;
      final Uint8List bytes = await xfile.readAsBytes();
      final String url = await StorageService.uploadAvatar(
        bytes,
        contentType: 'image/jpeg',
      );
      setState(() {
        _message = 'Avatar güncellendi';
        _urlController.text = url;
      });
    } catch (e) {
      setState(() => _message = 'Galeri hatası: $e');
    }
  }

  Future<void> _pickFromFiles() async {
    setState(() => _message = null);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null) return;
      final PlatformFile file = result.files.first;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        setState(() => _message = 'Dosya okunamadı');
        return;
      }
      final String contentType = (file.extension?.toLowerCase() == 'png')
          ? 'image/png'
          : 'image/jpeg';
      final String url = await StorageService.uploadAvatar(
        bytes,
        contentType: contentType,
      );
      setState(() {
        _message = 'Avatar güncellendi';
        _urlController.text = url;
      });
    } catch (e) {
      setState(() => _message = 'Dosya seçimi hatası: $e');
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
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
      await user.updatePhotoURL(
        _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
      );
      await user.reload();
      setState(() {
        _message = 'Avatar güncellendi';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = e.message ?? 'İşlem başarısız';
      });
    } catch (_) {
      setState(() {
        _message = 'Beklenmedik bir hata oluştu';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final photoUrl = user?.photoURL;
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
                              (photoUrl != null && photoUrl.isNotEmpty)
                              ? NetworkImage(photoUrl)
                              : null,
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? const Icon(Icons.person, size: 32)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              labelText: 'Avatar URL',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Bir resim URL’si girin (örn. https://...)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _pickFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galeriden Seç'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _pickFromFiles,
                          icon: const Icon(Icons.folder_open),
                          label: Text(kIsWeb ? 'Dosya Seç' : 'Dosyadan Seç'),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isSaving ? null : _save,
                              icon: const Icon(Icons.save),
                              label: _isSaving
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Kaydet'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _isSaving
                                  ? null
                                  : () {
                                      _urlController.clear();
                                      _save();
                                    },
                              child: const Text('Temizle'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_message != null) Text(_message!),
                    const SizedBox(height: 16),
                    const Text(
                      'Not: Yerel dosya/galeri seçimi için image_picker veya file_picker eklentisi eklenebilir.',
                    ),
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

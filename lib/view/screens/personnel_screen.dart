import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PersonnelScreen extends StatefulWidget {
  const PersonnelScreen({super.key});

  @override
  State<PersonnelScreen> createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends State<PersonnelScreen> {
  bool _useUnorderedFallback = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchPersonnel() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }

    final base = FirebaseFirestore.instance
        .collection('personnel')
        .where('ownerId', isEqualTo: uid)
        .where('trashed', isEqualTo: false);

    if (_useUnorderedFallback) {
      return base.limit(200).snapshots();
    }

    return base.orderBy('updatedAt', descending: true).limit(200).snapshots();
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sil'),
        content: const Text('Bu personel kaydı silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete),
            label: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseFirestore.instance.collection('personnel').doc(id).set({
      'trashed': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Çöp kutusuna taşındı')));
  }

  Future<void> _openForm({DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PersonnelFormDialog(doc: doc),
    );
  }

  Widget _build3dCard({required BuildContext context, required Widget child}) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Basit "3D" hissi: hafif perspektif + gölge.
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(0.015)
        ..rotateY(-0.012),
      child: Material(
        color: Colors.transparent,
        elevation: 10,
        shadowColor: primary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary.withAlpha(115)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withAlpha(140),
                Color.alphaBlend(primary.withAlpha(45), Colors.black),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> data) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(data['name'] ?? 'Personel'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['photoUrl'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Image.network(
                      data['photoUrl'],
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                _kv('Tarih', data['date'] ?? ''),
                _kv('Adres', data['address'] ?? ''),
                _kv('Maaş', (data['salary'] ?? 0).toString()),
                _kv('Borç', (data['debt'] ?? 0).toString()),
                _kv('Alacak', (data['receivable'] ?? 0).toString()),
                _kv('Harcamalar', (data['expenses'] ?? 0).toString()),
                _kv('Plaka', data['plate'] ?? ''),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Personel'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.55, 1.0],
                  colors: [
                    Colors.black,
                    Color.alphaBlend(primary.withAlpha(90), Colors.black),
                    primary.withAlpha(56),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: uid == null ? null : () => _openForm(),
                        icon: const Icon(Icons.login),
                        label: const Text('Giriş'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: (uid == null || uid.isEmpty)
                        ? Center(
                            child: Text(
                              'Personel için giriş yapmalısın',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          )
                        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _watchPersonnel(),
                            builder: (context, snapshot) {
                              final error = snapshot.error;
                              if (error is FirebaseException &&
                                  error.code == 'failed-precondition' &&
                                  !_useUnorderedFallback) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!mounted) return;
                                  setState(() => _useUnorderedFallback = true);
                                });
                              }

                              final docs = snapshot.data?.docs ?? const [];
                              final showSpinner =
                                  snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  docs.isEmpty;
                              if (showSpinner) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (docs.isEmpty) {
                                return Center(
                                  child: Text(
                                    'Kayıt yok. "Giriş" ile ekleyin.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (ctx, idx) {
                                  final d = docs[idx];
                                  final data = d.data();
                                  final id = d.id;
                                  final name = (data['name'] as String?)
                                      ?.trim();
                                  final date = (data['date'] as String?)
                                      ?.trim();
                                  final plate = (data['plate'] as String?)
                                      ?.trim();
                                  final photoUrl = (data['photoUrl'] as String?)
                                      ?.trim();

                                  return GestureDetector(
                                    onTap: () => _showDetails(data),
                                    onLongPress: () async {
                                      final action =
                                          await showModalBottomSheet<String>(
                                            context: context,
                                            builder: (ctx) => SafeArea(
                                              child: Wrap(
                                                children: [
                                                  ListTile(
                                                    leading: const Icon(
                                                      Icons.edit,
                                                    ),
                                                    title: const Text(
                                                      'Düzenle',
                                                    ),
                                                    onTap: () => Navigator.pop(
                                                      ctx,
                                                      'edit',
                                                    ),
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(
                                                      Icons.delete,
                                                    ),
                                                    title: const Text('Sil'),
                                                    onTap: () => Navigator.pop(
                                                      ctx,
                                                      'delete',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                      if (action == 'edit') {
                                        await _openForm(doc: d);
                                      } else if (action == 'delete') {
                                        await _delete(id);
                                      }
                                    },
                                    child: _build3dCard(
                                      context: context,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          if (photoUrl != null &&
                                              photoUrl.isNotEmpty)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                photoUrl,
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: Colors.white10,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.white24,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white54,
                                              ),
                                            ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name == null || name.isEmpty
                                                      ? 'Adsız'
                                                      : name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  [
                                                    if (date != null &&
                                                        date.isNotEmpty)
                                                      date,
                                                    if (plate != null &&
                                                        plate.isNotEmpty)
                                                      ' • $plate',
                                                  ].join(''),
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonnelFormDialog extends StatefulWidget {
  const _PersonnelFormDialog({this.doc});
  final DocumentSnapshot<Map<String, dynamic>>? doc;

  @override
  State<_PersonnelFormDialog> createState() => _PersonnelFormDialogState();
}

class _PersonnelFormDialogState extends State<_PersonnelFormDialog> {
  final _name = TextEditingController();
  final _date = TextEditingController();
  final _address = TextEditingController();
  final _salary = TextEditingController();
  final _debt = TextEditingController();
  final _receivable = TextEditingController();
  final _expenses = TextEditingController();
  final _plate = TextEditingController();
  XFile? _pickedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data();
    if (data != null) {
      _name.text = data['name']?.toString() ?? '';
      _date.text = data['date']?.toString() ?? '';
      _address.text = data['address']?.toString() ?? '';
      _salary.text = (data['salary']?.toString() ?? '');
      _debt.text = (data['debt']?.toString() ?? '');
      _receivable.text = (data['receivable']?.toString() ?? '');
      _expenses.text = (data['expenses']?.toString() ?? '');
      _plate.text = data['plate']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _date.dispose();
    _address.dispose();
    _salary.dispose();
    _debt.dispose();
    _receivable.dispose();
    _expenses.dispose();
    _plate.dispose();
    super.dispose();
  }

  double _toDouble(String s) {
    return double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img != null) setState(() => _pickedImage = img);
  }

  Future<void> _save() async {
    if (_saving) return;

    final messenger = ScaffoldMessenger.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Oturum açmadan personel kaydı eklenemez.'),
        ),
      );
      return;
    }

    // Değerleri pop'tan önce kopyala; dialog kapanınca state dispose olabilir.
    final ref = FirebaseFirestore.instance.collection('personnel');
    final String? existingId = widget.doc?.id;
    final XFile? pickedImage = _pickedImage;
    final payload = {
      'name': _name.text.trim(),
      'date': _date.text.trim(),
      'address': _address.text.trim(),
      'salary': _toDouble(_salary.text),
      'debt': _toDouble(_debt.text),
      'receivable': _toDouble(_receivable.text),
      'expenses': _toDouble(_expenses.text),
      'plate': _plate.text.trim().toUpperCase(),
      'updatedAt': FieldValue.serverTimestamp(),
      'ownerId': user.uid,
    };

    // Kullanıcı "Kaydet"e basar basmaz form kapansın.
    setState(() => _saving = true);
    Navigator.of(context).pop(false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Kaydediliyor…')));

    // Arka planda kaydetme + (varsa) fotoğraf yükleme.
    // ignore: discarded_futures
    Future(() async {
      try {
        String docId = existingId ?? '';
        if (docId.isEmpty) {
          final created = await ref.add({
            ...payload,
            'trashed': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          docId = created.id;
        } else {
          await ref.doc(docId).set(payload, SetOptions(merge: true));
        }

        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Kaydedildi')));

        if (pickedImage != null) {
          try {
            final bytes = await pickedImage.readAsBytes();
            final storageRef = FirebaseStorage.instance.ref(
              'personnel/$docId.jpg',
            );
            await storageRef.putData(
              bytes,
              SettableMetadata(
                contentType: pickedImage.mimeType ?? 'image/jpeg',
                cacheControl: 'public,max-age=0',
              ),
            );
            final url = await storageRef.getDownloadURL();
            final cacheBustedUrl =
                '$url${url.contains('?') ? '&' : '?'}v=${DateTime.now().millisecondsSinceEpoch}';
            await ref.doc(docId).set({
              'photoUrl': cacheBustedUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Fotoğraf yükleme başarısız: $e');
            }
          }
        }
      } on FirebaseException catch (e) {
        final msg = e.message?.trim();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Kaydedilemedi: ${msg?.isNotEmpty == true ? msg : e.code}',
              ),
            ),
          );
      } catch (e) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Kaydetme sırasında hata: $e')),
          );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Personel Girişi'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _date,
              decoration: const InputDecoration(
                labelText: 'Tarih (gg/aa/yyyy)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _DateSlashFormatter(),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Adres'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _salary,
                    decoration: const InputDecoration(labelText: 'Maaş'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _debt,
                    decoration: const InputDecoration(labelText: 'Borç'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _receivable,
                    decoration: const InputDecoration(labelText: 'Alacak'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _expenses,
                    decoration: const InputDecoration(labelText: 'Harcamalar'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _plate,
              decoration: const InputDecoration(labelText: 'Plaka'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Fotoğraf'),
                ),
                const SizedBox(width: 12),
                if (_pickedImage != null)
                  Text('Seçildi', style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (_saving)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save),
          label: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
        ),
      ],
    );
  }
}

class _DateSlashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 8) text = text.substring(0, 8);
    final buf = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buf.write(text[i]);
      if ((i == 1 || i == 3) && i != text.length - 1) buf.write('/');
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text('$k:')),
        const SizedBox(width: 8),
        Expanded(child: Text(v)),
      ],
    ),
  );
}

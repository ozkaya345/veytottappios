import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:async';
import '../../data/services/status_table_service.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/utils/save_text_file.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatusTrackScreen extends StatefulWidget {
  const StatusTrackScreen({
    super.key,
    this.tableId,
    this.initialTitle,
    this.readOnly = true,
  });

  final String? tableId;
  final String? initialTitle;
  final bool readOnly;

  @override
  State<StatusTrackScreen> createState() => _StatusTrackScreenState();
}

class _StatusTrackScreenState extends State<StatusTrackScreen>
    with WidgetsBindingObserver {
  static const int _maxCols = 10;
  static const int _maxRows = 100;

  static const int _minCols = 1;
  static const int _minRows = 1;

  int _cols = 8; // başlangıç sütun sayısı
  int _rowsCount = 12; // başlangıç satır sayısı
  double _colWidth = 160; // dinamik sütun genişliği
  double _rowHeight = 48; // dinamik satır yüksekliği
  final Map<int, String> _headerOverrides = {}; // 1-based index -> label
  final Map<int, String> _rowOverrides = {}; // 1-based index -> label

  late List<List<TextEditingController>> _cellCtrls;
  late List<TextEditingController> _colHeaderCtrls;
  String? _tableTitle;
  String? _tableCode;
  String? _currentTableId;
  bool _isReadOnly = true;

  bool _dirty = false;
  bool _autoSaveInProgress = false;
  DateTime? _lastAutoSaveAt;

  bool _manualSaveInProgress = false;
  final ScrollController _hScrollCtrl = ScrollController();
  final ScrollController _vScrollCtrl = ScrollController();

  bool _didPostFrameRebuild = false;

  void _scrollToOrigin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_hScrollCtrl.hasClients) {
        _hScrollCtrl.jumpTo(0);
      }
      if (_vScrollCtrl.hasClients) {
        _vScrollCtrl.jumpTo(0);
      }
    });
  }

  List<String> _collectColHeaders() {
    return List<String>.generate(_cols, (i) => _colHeaderCtrls[i].text.trim());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _isReadOnly = widget.readOnly;
    _cellCtrls = List.generate(
      _rowsCount,
      (_) => List.generate(_cols, (_) => TextEditingController()),
    );
    _colHeaderCtrls = List.generate(_cols, (_) => TextEditingController());

    // Yeni tablo ekranı: başlık parametreyle geldiyse ekranda kullan.
    final initialTitle = widget.initialTitle;
    if (initialTitle != null && initialTitle.trim().isNotEmpty) {
      _tableTitle = initialTitle.trim();
    }

    // Eğer tablo ID ile gelindiyse otomatik yükle
    final id = widget.tableId;
    if (id != null && id.isNotEmpty) {
      _currentTableId = id;
      // initState içinde async çağrı
      Future.microtask(() async {
        final data = await StatusTableService.loadTable(id);
        if (data != null && mounted) {
          final rows = (data['rows'] as num).toInt();
          final cols = (data['cols'] as num).toInt();
          final cappedCols = cols.clamp(1, _maxCols);
          final list = (data['data'] as List)
              .map<List<String>>(
                (row) => (row as List).map((e) => e.toString()).toList(),
              )
              .toList();

          final storedHeaders = data['colHeaders'];
          final colHeaders = (storedHeaders is List)
              ? storedHeaders.map((e) => e?.toString() ?? '').toList()
              : <String>[];
          setState(() {
            _tableTitle = (data['title'] as String?)?.trim();
            final code = (data['code'] as String?)?.trim();
            _tableCode = (code != null && code.isNotEmpty) ? code : id;
            _rowsCount = rows;
            _cols = cappedCols;
            _isReadOnly = widget.readOnly;
            _dirty = false;
            for (final row in _cellCtrls) {
              for (final c in row) {
                c.dispose();
              }
            }
            for (final c in _colHeaderCtrls) {
              c.dispose();
            }
            _cellCtrls = List.generate(
              rows,
              (r) => List.generate(
                cappedCols,
                (c) => TextEditingController(
                  text: (r < list.length && c < list[r].length)
                      ? list[r][c]
                      : '',
                ),
              ),
            );

            _colHeaderCtrls = List.generate(
              cappedCols,
              (i) => TextEditingController(
                text: (i < colHeaders.length)
                    ? colHeaders[i].toString().trim()
                    : '',
              ),
            );
            _headerOverrides.clear();
            for (int i = 0; i < _colHeaderCtrls.length; i++) {
              final t = _colHeaderCtrls[i].text.trim();
              if (t.isNotEmpty) {
                _headerOverrides[i + 1] = t;
              }
            }
          });

          // Açılışta her zaman A sütununa/satır başına dön.
          _scrollToOrigin();
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_didPostFrameRebuild) return;
      _didPostFrameRebuild = true;
      setState(() {});

      // İlk frame'de scroll offset sıfırlansın.
      _scrollToOrigin();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plana gidince/askıya alınca son değişiklikleri kaydet.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_autoSaveIfNeeded(reason: 'lifecycle:$state'));
    }
  }

  void _markDirty() {
    if (_isReadOnly) return;
    _dirty = true;
  }

  Future<void> _handleBackNavigation() async {
    if (!mounted) return;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_isReadOnly || !_dirty) {
      _goBackAfterTrack(nav);
      return;
    }

    // Dialog: true => save&exit, false => discard&exit, null => cancel
    final dialogResult = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydedilmemiş değişiklikler var'),
        content: const Text('Çıkmadan önce kaydetmek ister misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kaydetmeden Çık'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet ve Çık'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (dialogResult == null) {
      return;
    }

    if (dialogResult == false) {
      setState(() {
        _dirty = false;
      });
      _goBackAfterTrack(nav);
      return;
    }

    // Save & exit
    final ok = await _saveCurrentOrPrompt(navigateAfterSave: false);
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Kaydedildi, çıkılıyor')),
      );
      _goBackAfterTrack(nav);
    }
  }

  // Saved badge göstergesi kaldırıldı.

  Future<void> _autoSaveIfNeeded({
    required String reason,
    bool showSnackOnSuccess = false,
  }) async {
    if (_isReadOnly) return;
    if (!_dirty) return;
    if (_autoSaveInProgress) return;

    // Yeni tablo henüz başlıksızsa otomatik create etmeyelim.
    final title = (_tableTitle ?? '').trim();
    if ((_currentTableId == null || _currentTableId!.isEmpty) &&
        title.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final last = _lastAutoSaveAt;
    if (last != null &&
        now.difference(last) < const Duration(milliseconds: 800)) {
      return;
    }

    _autoSaveInProgress = true;
    _lastAutoSaveAt = now;

    try {
      final id = _currentTableId;
      if (id != null && id.isNotEmpty) {
        await StatusTableService.saveTable(
          id: id,
          rows: _rowsCount,
          cols: _cols,
          data: _collectData(),
          title: _tableTitle,
          colHeaders: _collectColHeaders(),
        );
      } else {
        final result = await StatusTableService.createTable(
          rows: _rowsCount,
          cols: _cols,
          data: _collectData(),
          title: title,
          colHeaders: _collectColHeaders(),
        );

        final newId = result['id'];
        final newCode = result['code'];
        if (mounted) {
          setState(() {
            _currentTableId = newId;
            _tableCode = newCode;
          });
        } else {
          _currentTableId = newId;
          _tableCode = newCode;
        }
      }

      _dirty = false;
      if (showSnackOnSuccess && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Otomatik kaydedildi')));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AUTO-SAVE FAILED ($reason): $e');
        debugPrintStack();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: Text('Otomatik kaydedilemedi: ${_humanizeSaveError(e)}'),
          ),
        );
      }
    } finally {
      _autoSaveInProgress = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // dispose async olamaz; ama en azından tetikleyelim.
    unawaited(_autoSaveIfNeeded(reason: 'dispose'));
    for (final row in _cellCtrls) {
      for (final c in row) {
        c.dispose();
      }
    }
    for (final c in _colHeaderCtrls) {
      c.dispose();
    }
    _hScrollCtrl.dispose();
    _vScrollCtrl.dispose();
    super.dispose();
  }

  int _lettersToIndex(String letters) {
    // A -> 1, Z -> 26, AA -> 27
    int result = 0;
    for (int i = 0; i < letters.length; i++) {
      int value = letters.toUpperCase().codeUnitAt(i) - 'A'.codeUnitAt(0) + 1;
      result = result * 26 + value;
    }
    return result;
  }

  void _addColumn() {
    if (_cols >= _maxCols) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('En fazla $_maxCols sütun eklenebilir.')),
      );
      return;
    }
    setState(() {
      _cols += 1;
      _markDirty();
      for (int r = 0; r < _rowsCount; r++) {
        _cellCtrls[r].add(TextEditingController());
      }
      _colHeaderCtrls.add(TextEditingController());
    });
  }

  void _addRow() {
    if (_rowsCount >= _maxRows) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 100 satır eklenebilir.')),
      );
      return;
    }
    setState(() {
      _rowsCount += 1;
      _markDirty();
      _cellCtrls.add(List.generate(_cols, (_) => TextEditingController()));
    });
  }

  void _deleteLastColumn() {
    if (_cols <= _minCols) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('En az $_minCols sütun kalmalı.')));
      return;
    }

    setState(() {
      _markDirty();
      final colIndex = _cols - 1;

      for (int r = 0; r < _rowsCount; r++) {
        _cellCtrls[r][colIndex].dispose();
        _cellCtrls[r].removeAt(colIndex);
      }

      _colHeaderCtrls[colIndex].dispose();
      _colHeaderCtrls.removeAt(colIndex);
      _headerOverrides.remove(_cols); // 1-based
      _cols -= 1;
    });

    unawaited(_autoSaveIfNeeded(reason: 'delete:last_col'));
  }

  void _deleteLastRow() {
    if (_rowsCount <= _minRows) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('En az $_minRows satır kalmalı.')));
      return;
    }

    setState(() {
      _markDirty();
      final rowIndex = _rowsCount - 1;
      for (final c in _cellCtrls[rowIndex]) {
        c.dispose();
      }
      _cellCtrls.removeAt(rowIndex);
      _rowOverrides.remove(_rowsCount); // 1-based
      _rowsCount -= 1;
    });

    unawaited(_autoSaveIfNeeded(reason: 'delete:last_row'));
  }

  Future<void> _renameColumnDialog() async {
    final numCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sütun Yeniden Adlandır'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numCtrl,
              decoration: const InputDecoration(
                labelText: 'Sütun (A.. veya numara)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: textCtrl,
              decoration: const InputDecoration(labelText: 'Yeni Etiket'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (res != true) return;
    final input = numCtrl.text.trim();
    final col = int.tryParse(input) ?? _lettersToIndex(input);
    final label = textCtrl.text.trim();
    if (col < 1 || col > _cols || label.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Geçersiz giriş')));
      return;
    }
    setState(() {
      _markDirty();
      _headerOverrides[col] = label;
      if (col - 1 >= 0 && col - 1 < _colHeaderCtrls.length) {
        _colHeaderCtrls[col - 1].text = label;
      }
    });
  }

  Future<void> _renameRowDialog() async {
    final idxCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Satır Yeniden Adlandır'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idxCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Satır No (1..N)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: textCtrl,
              decoration: const InputDecoration(labelText: 'Yeni Etiket'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (res != true) return;
    final rowIndex = int.tryParse(idxCtrl.text.trim()) ?? -1;
    final label = textCtrl.text.trim();
    if (rowIndex < 1 || rowIndex > _rowsCount || label.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Geçersiz giriş')));
      return;
    }
    setState(() {
      _markDirty();
      _rowOverrides[rowIndex] = label;
    });
  }

  List<List<String>> _collectData() {
    return [
      for (int r = 0; r < _rowsCount; r++)
        [for (int c = 0; c < _cols; c++) _cellCtrls[r][c].text],
    ];
  }

  String _humanizeSaveError(Object e) {
    // FirebaseAuth
    if (e is FirebaseAuthException) {
      if (e.code == 'no-user') return 'Oturum açık değil. Lütfen giriş yap.';
      final msg = (e.message ?? '').trim();
      return msg.isNotEmpty ? msg : 'Giriş hatası: ${e.code}';
    }

    // Firestore
    try {
      // Avoid adding a hard import just for typing; runtime check works.
      // ignore: avoid_dynamic_calls
      final dynamic dyn = e;
      final String? code = (dyn.code is String) ? dyn.code as String : null;
      if (code == 'permission-denied') {
        return 'Kaydetme izni yok. Bu tablo size ait değil veya kurallar izin vermiyor.';
      }
      if (code == 'unavailable') {
        return 'Bağlantı yok veya Firebase geçici olarak erişilemiyor.';
      }
    } catch (_) {
      // ignore
    }

    return e.toString();
  }

  Future<bool> _saveCurrentOrPrompt({bool navigateAfterSave = false}) async {
    if (_isReadOnly) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salt okunur: Kaydetme kapalı')),
        );
      }
      return false;
    }
    if (_manualSaveInProgress) return false;
    setState(() {
      _manualSaveInProgress = true;
    });
    try {
      final id = _currentTableId;
      if (id != null && id.isNotEmpty) {
        await StatusTableService.saveTable(
          id: id,
          rows: _rowsCount,
          cols: _cols,
          data: _collectData(),
          title: _tableTitle,
          colHeaders: _collectColHeaders(),
        );
        _dirty = false;
        if (!mounted) return false;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kaydedildi')));

        return true;
      }

      final title = (_tableTitle ?? '').trim();
      if (title.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Başlık boş olamaz')));
        }
        return false;
      }

      final result = await StatusTableService.createTable(
        rows: _rowsCount,
        cols: _cols,
        data: _collectData(),
        title: title,
        colHeaders: _collectColHeaders(),
      );
      if (!mounted) return false;
      _currentTableId = result['id'];
      _tableCode = result['code'];
      _dirty = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kaydedildi')));
      if (navigateAfterSave) {
        final nav = Navigator.of(context);
        _goBackAfterTrack(nav);
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SAVE FAILED: $e');
        debugPrintStack();
      }
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text('Kaydedilemedi: ${_humanizeSaveError(e)}'),
        ),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _manualSaveInProgress = false;
        });
      } else {
        _manualSaveInProgress = false;
      }
    }
  }

  void _goBackAfterTrack(NavigatorState nav) {
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    nav.pushNamed(AppRoutes.statusTrackList);
  }

  Future<void> _loadDialog() async {
    final idCtrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tabloyu Yükle'),
        content: TextField(
          controller: idCtrl,
          decoration: const InputDecoration(labelText: 'Tablo ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, idCtrl.text.trim()),
            child: const Text('Yükle'),
          ),
        ],
      ),
    );
    if (res == null || res.isEmpty) return;
    final data = await StatusTableService.loadTable(res);
    if (data == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tablo bulunamadı')));
      }
      return;
    }
    final rows = (data['rows'] as num).toInt();
    final cols = (data['cols'] as num).toInt();
    final list = (data['data'] as List)
        .map<List<String>>(
          (row) => (row as List).map((e) => e.toString()).toList(),
        )
        .toList();
    setState(() {
      _tableTitle = (data['title'] as String?)?.trim();
      final code = (data['code'] as String?)?.trim();
      _tableCode = (code != null && code.isNotEmpty) ? code : res;
      _currentTableId = res;
      _isReadOnly = widget.readOnly;
      _rowsCount = rows;
      _cols = cols;
      _dirty = false;
      // yeniden controller üret
      for (final row in _cellCtrls) {
        for (final c in row) {
          c.dispose();
        }
      }
      for (final c in _colHeaderCtrls) {
        c.dispose();
      }
      _cellCtrls = List.generate(
        rows,
        (r) => List.generate(
          cols,
          (c) => TextEditingController(
            text: (r < list.length && c < list[r].length) ? list[r][c] : '',
          ),
        ),
      );

      final storedHeaders = data['colHeaders'];
      final colHeaders = (storedHeaders is List)
          ? storedHeaders.map((e) => e?.toString() ?? '').toList()
          : <String>[];
      _colHeaderCtrls = List.generate(
        cols,
        (i) => TextEditingController(
          text: (i < colHeaders.length) ? colHeaders[i].toString().trim() : '',
        ),
      );
      _headerOverrides.clear();
      for (int i = 0; i < _colHeaderCtrls.length; i++) {
        final t = _colHeaderCtrls[i].text.trim();
        if (t.isNotEmpty) {
          _headerOverrides[i + 1] = t;
        }
      }
    });
    _scrollToOrigin();
  }

  Future<void> _importCsvFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    final content = String.fromCharCodes(bytes);
    _applyCsvContent(content);
  }

  Future<void> _importCsvFromPaste() async {
    final textCtrl = TextEditingController();
    final pasted = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV Yapıştır'),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: textCtrl,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'CSV içeriğini buraya yapıştırın',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, textCtrl.text),
            child: const Text('İçe Aktar'),
          ),
        ],
      ),
    );
    if (pasted == null || pasted.isEmpty) return;
    _applyCsvContent(pasted);
  }

  void _applyCsvContent(String content) {
    final rows = const CsvToListConverter(eol: '\n').convert(content);
    final int newRows = rows.length;
    final int newCols = rows.isNotEmpty
        ? rows.map((r) => r.length).reduce((a, b) => a > b ? a : b)
        : 0;
    final int cappedCols = newCols.clamp(0, _maxCols);
    setState(() {
      _rowsCount = newRows;
      _cols = cappedCols;
      _markDirty();
      for (final row in _cellCtrls) {
        for (final c in row) {
          c.dispose();
        }
      }
      for (final c in _colHeaderCtrls) {
        c.dispose();
      }
      _cellCtrls = List.generate(
        newRows,
        (r) => List.generate(
          cappedCols,
          (c) => TextEditingController(
            text: (c < rows[r].length) ? rows[r][c].toString() : '',
          ),
        ),
      );
      _colHeaderCtrls = List.generate(
        cappedCols,
        (_) => TextEditingController(),
      );
      _headerOverrides.clear();
    });

    _scrollToOrigin();
  }

  Future<void> _exportCsv() async {
    final data = _collectData();
    final csv = const ListToCsvConverter().convert(data);
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CSV panoya kopyalandı')));
    }
  }

  Future<void> _exportCsvToFile() async {
    final data = _collectData();
    final csv = const ListToCsvConverter().convert(data);
    final nameCtrl = TextEditingController(text: 'durum_tablosu.csv');
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV Dosyaya Kaydet'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Dosya adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (res == null || res.isEmpty) return;
    try {
      final saved = await saveTextFile(
        suggestedName: res,
        content: csv,
        mimeType: 'text/csv',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kaydedildi: ${saved ?? res}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_handleBackNavigation());
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (_tableTitle != null && _tableTitle!.isNotEmpty)
                    ? _tableTitle!
                    : 'Trans Takip',
              ),
              if (_tableCode != null && _tableCode!.isNotEmpty)
                DefaultTextStyle(
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Kod: ${_tableCode!}'),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _isReadOnly
                            ? null
                            : () {
                                Clipboard.setData(
                                  ClipboardData(text: _tableCode!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Kod kopyalandı'),
                                  ),
                                );
                              },
                        child: const Icon(
                          Icons.copy_all,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _isReadOnly ? null : _addColumn,
              tooltip: 'Sağa Sütun Ekle (max 10)',
              icon: const Icon(Icons.view_column),
            ),
            IconButton(
              onPressed: _isReadOnly ? null : _addRow,
              tooltip: 'Aşağı Satır Ekle (max 100)',
              icon: const Icon(Icons.view_agenda),
            ),
            IconButton(
              onPressed: _isReadOnly
                  ? null
                  : () async {
                      // Önce kaydı tamamla, başarılıysa listeye dön
                      final nav = Navigator.of(context);
                      final ok = await _saveCurrentOrPrompt(
                        navigateAfterSave: false,
                      );
                      if (!mounted) return;
                      if (ok) {
                        _goBackAfterTrack(nav);
                      }
                    },
              tooltip: 'Kaydet ve Çık',
              icon: const Icon(Icons.save),
            ),
            IconButton(
              onPressed: _isReadOnly ? null : _loadDialog,
              tooltip: 'Yükle (Firestore)',
              icon: const Icon(Icons.folder_open),
            ),
            PopupMenuButton<String>(
              tooltip: 'CSV',
              enabled: !_isReadOnly,
              itemBuilder: (ctx) {
                final items = <PopupMenuEntry<String>>[];
                if (!_isReadOnly) {
                  items.addAll(const [
                    PopupMenuItem(
                      value: 'import_file',
                      child: Text('CSV İçe (Dosya)'),
                    ),
                    PopupMenuItem(
                      value: 'import_paste',
                      child: Text('CSV İçe (Yapıştır)'),
                    ),
                  ]);
                }
                items.addAll(const [
                  PopupMenuItem(
                    value: 'export',
                    child: Text('CSV Dışa (Panoya)'),
                  ),
                  PopupMenuItem(
                    value: 'export_file',
                    child: Text('CSV Dışa (Dosyaya)'),
                  ),
                ]);
                return items;
              },
              onSelected: (v) {
                switch (v) {
                  case 'import_file':
                    if (!_isReadOnly) _importCsvFromFile();
                    break;
                  case 'import_paste':
                    if (!_isReadOnly) _importCsvFromPaste();
                    break;
                  case 'export':
                    _exportCsv();
                    break;
                  case 'export_file':
                    _exportCsvToFile();
                    break;
                }
              },
              icon: const Icon(Icons.file_present),
            ),
            PopupMenuButton<String>(
              tooltip: 'Düzenleme',
              enabled: !_isReadOnly,
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'del_col', child: Text('Sütun Sil')),
                PopupMenuItem(value: 'del_row', child: Text('Satır Sil')),
                PopupMenuItem(
                  value: 'ren_col',
                  child: Text('Sütun Yeniden Adlandır'),
                ),
                PopupMenuItem(
                  value: 'ren_row',
                  child: Text('Satır Yeniden Adlandır'),
                ),
              ],
              onSelected: (v) {
                if (_isReadOnly) return;
                switch (v) {
                  case 'del_col':
                    _deleteLastColumn();
                    break;
                  case 'del_row':
                    _deleteLastRow();
                    break;
                  case 'ren_col':
                    _renameColumnDialog();
                    break;
                  case 'ren_row':
                    _renameRowDialog();
                    break;
                }
              },
              icon: const Icon(Icons.edit),
            ),
            if (_isReadOnly)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.visibility, color: Colors.white70),
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
                      Color.alphaBlend(
                        primary.withValues(alpha: 0.35),
                        Colors.black,
                      ),
                      primary.withValues(alpha: 0.22),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          // PERF: A full `Table` builds every cell widget eagerly.
                          // With 100x20 it's 2000+ TextFields and feels like "loading".
                          // This layout virtualizes rows with SliverList so only visible
                          // rows build.

                          final totalWidth = 90 + (_cols * _colWidth);

                          final headerBg = Color.alphaBlend(
                            Colors.black.withValues(alpha: 0.35),
                            primary,
                          );

                          Widget buildCellBox({
                            required Widget child,
                            required double width,
                            required double height,
                            bool header = false,
                          }) {
                            return Container(
                              width: width,
                              height: height,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: header ? headerBg : Colors.white,
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.45),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: child,
                            );
                          }

                          Widget buildHeaderRow() {
                            return Row(
                              children: [
                                buildCellBox(
                                  width: 90,
                                  height: _rowHeight,
                                  header: true,
                                  child: const Text(
                                    '',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                for (int i = 1; i <= _cols; i++)
                                  buildCellBox(
                                    width: _colWidth,
                                    height: _rowHeight,
                                    header: true,
                                    child: TextField(
                                      controller: _colHeaderCtrls[i - 1],
                                      readOnly: _isReadOnly,
                                      enabled: !_isReadOnly,
                                      cursorColor: Colors.white,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText: i.toString(),
                                        hintStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      onChanged: _isReadOnly
                                          ? null
                                          : (v) {
                                              _markDirty();
                                              final t = v.trim();
                                              if (t.isEmpty) {
                                                _headerOverrides.remove(i);
                                              } else {
                                                _headerOverrides[i] = t;
                                              }
                                              unawaited(
                                                _autoSaveIfNeeded(
                                                  reason: 'edit:header',
                                                ),
                                              );
                                            },
                                    ),
                                  ),
                              ],
                            );
                          }

                          Widget buildDataRow(int r) {
                            return Row(
                              children: [
                                buildCellBox(
                                  width: 90,
                                  height: _rowHeight,
                                  header: true,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      (_rowOverrides[r + 1] ??
                                          (r + 1).toString()),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                for (int c = 0; c < _cols; c++)
                                  buildCellBox(
                                    width: _colWidth,
                                    height: _rowHeight,
                                    child: TextField(
                                      controller: _cellCtrls[r][c],
                                      readOnly: _isReadOnly,
                                      enabled: !_isReadOnly,
                                      maxLines: 1,
                                      cursorColor: Colors.black,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 12,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      onChanged: _isReadOnly
                                          ? null
                                          : (_) {
                                              _markDirty();
                                              unawaited(
                                                _autoSaveIfNeeded(
                                                  reason: 'edit:cell',
                                                ),
                                              );
                                            },
                                    ),
                                  ),
                              ],
                            );
                          }

                          final content = SizedBox(
                            width: totalWidth,
                            child: CustomScrollView(
                              controller: _vScrollCtrl,
                              slivers: [
                                SliverToBoxAdapter(child: buildHeaderRow()),
                                SliverList.builder(
                                  itemCount: _rowsCount,
                                  itemBuilder: (ctx, r) => buildDataRow(r),
                                ),
                              ],
                            ),
                          );

                          final horizontal = SingleChildScrollView(
                            controller: _hScrollCtrl,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth:
                                    MediaQuery.of(context).size.width - 24,
                                minHeight:
                                    MediaQuery.of(context).size.height * 0.5,
                              ),
                              child: RepaintBoundary(child: content),
                            ),
                          );

                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Scrollbar(
                                controller: _hScrollCtrl,
                                thumbVisibility: true,
                                child: Scrollbar(
                                  controller: _vScrollCtrl,
                                  thumbVisibility: true,
                                  notificationPredicate: (n) => n.depth == 1,
                                  child: horizontal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Sütun Genişliği'),
                        Expanded(
                          child: Slider(
                            value: _colWidth,
                            min: 100,
                            max: 300,
                            divisions: 20,
                            label: _colWidth.round().toString(),
                            onChanged: (v) => setState(() => _colWidth = v),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Satır Yüksekliği'),
                        Expanded(
                          child: Slider(
                            value: _rowHeight,
                            min: 32,
                            max: 96,
                            divisions: 16,
                            label: _rowHeight.round().toString(),
                            onChanged: (v) => setState(() => _rowHeight = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

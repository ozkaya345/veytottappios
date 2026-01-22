import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String?> saveTextFile({
  required String suggestedName,
  required String content,
  String mimeType = 'text/plain',
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$suggestedName');
  await file.writeAsString(content);
  return file.path;
}

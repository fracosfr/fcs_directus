import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class CacheProvider {
  CacheProvider({required this.directory});
  final Directory? directory;
  Future<String> get _localPath async {
    if (directory == null) return "";
    if (!(await directory?.exists() ?? true)) {
      await directory?.create();
    }
    return directory?.path ?? "";
  }

  Future<File?> _localFile(String uid) async {
    final path = await _localPath;
    if (path.isEmpty) return null;

    var bytes = utf8.encode(uid); // data being hashed
    var digest = sha1.convert(bytes);

    return File('$path/$digest');
  }

  Future write({required String uid, required String data}) async {
    final file = await _localFile(uid);
    if (file == null) return;
    file.writeAsString(data);
  }

  Future<String?> read(
      {required String uid, required Duration? cacheDuration}) async {
    if (cacheDuration == null) return null;
    final file = await _localFile(uid);

    if (file == null) return null;

    if (await file.exists()) {
      final fileDate = await file.lastModified();
      final now = DateTime.now().subtract(cacheDuration);

      if (fileDate.isAfter(now)) {
        return await file.readAsString();
      } else {
        file.delete();
      }
    }
    return null;
  }
}

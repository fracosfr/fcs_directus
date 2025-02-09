import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

class CacheProvider {
  CacheProvider({required this.directory, required this.isWeb});
  final Directory? directory;
  final bool isWeb;

  Future<Database?> _openStore() async {
    if (isWeb) {
      var factory = databaseFactoryWeb;
      var db = await factory.openDatabase('cache');
      return db;
    } else {
      final dbPath = join(directory?.path ?? "", 'cache.db');
      DatabaseFactory dbFactory = databaseFactoryIo;
      Database db = await dbFactory.openDatabase(dbPath);
      return db;
    }
  }

  String _hashSha1(String value) {
    var bytes = utf8.encode(value); // data being hashed
    var digest = sha1.convert(bytes);
    return "$digest";
  }

  Future write({required String uid, required String data}) async {
    final db = await _openStore();
    if (db == null) return;

    var store = stringMapStoreFactory.store('transaction');
    await store
        .record(_hashSha1(uid))
        .put(db, {"data": data, "date": DateTime.now().toIso8601String()});
  }

  Future<String?> read(
      {required String uid, required Duration? cacheDuration}) async {
    if (cacheDuration == null) return null;

    final db = await _openStore();
    if (db == null) return null;

    var store = stringMapStoreFactory.store('transaction');
    final data = await store.record(_hashSha1(uid)).get(db);
    final dateTest = DateTime.tryParse(data?["date"].toString() ?? "");
    if (dateTest == null) return null;

    print(dateTest);
    final now = DateTime.now().subtract(cacheDuration);
    if (dateTest.isAfter(now)) {
      return data?["data"].toString();
    } else {
      await store.record(_hashSha1(uid)).delete(db);
    }

    return null;
  }
}

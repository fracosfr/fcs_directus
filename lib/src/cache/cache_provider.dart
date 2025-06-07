import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:encrypt/encrypt.dart';

class CacheProvider {
  CacheProvider({required this.directory, required this.isWeb, this.cryptKey});
  final Directory? directory;
  final bool isWeb;
  final String? cryptKey;

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

  String _hashSha512(String value) {
    var bytes = utf8.encode(value); // data being hashed
    var digest = sha512.convert(bytes);
    return "$digest";
  }

  Future write({required String uid, required String data}) async {
    final db = await _openStore();
    if (db == null) return;

    if (cryptKey != null) {}

    uid += "_v2";

    var store = stringMapStoreFactory.store('transaction');
    await store.record(_hashSha1(uid)).put(
        db, {"data": _encrypt(data), "date": DateTime.now().toIso8601String()});
  }

  Future<String?> read(
      {required String uid, required Duration? cacheDuration}) async {
    if (cacheDuration == null) return null;

    final db = await _openStore();
    if (db == null) return null;

    uid += "_v2";

    try {
      var store = stringMapStoreFactory.store('transaction');
      final data = await store.record(_hashSha1(uid)).get(db);
      final dateTest = DateTime.tryParse(data?["date"].toString() ?? "");
      if (dateTest == null) return null;

      final now = DateTime.now().subtract(cacheDuration);
      if (dateTest.isAfter(now)) {
        return _decrypt((data?["data"]).toString());
      } else {
        await store.record(_hashSha1(uid)).delete(db);
      }
    } catch (_) {}

    return null;
  }

  String _decrypt(String encryptedData) {
    if (cryptKey == null) return encryptedData;
    if (encryptedData.isEmpty) return "";

    final String keyString = _hashSha512(cryptKey ?? "").substring(0, 32);
    final key = Key.fromUtf8(keyString);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final initVector = IV.fromUtf8(keyString.substring(0, 16));
    return encrypter.decrypt64(encryptedData, iv: initVector);
  }

  String _encrypt(String plainText) {
    if (cryptKey == null) return plainText;
    if (plainText.isEmpty) return "";

    final String keyString = _hashSha512(cryptKey ?? "").substring(0, 32);
    final key = Key.fromUtf8(keyString);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final initVector = IV.fromUtf8(keyString.substring(0, 16));
    Encrypted encryptedData = encrypter.encrypt(plainText, iv: initVector);
    return encryptedData.base64;
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:fcs_directus/src/cache/cache_provider.dart';
import 'package:fcs_directus/src/errors/errors.dart';
import 'package:fcs_directus/src/request/directus_response.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:http_parser/http_parser.dart';

enum HttpMethod {
  get,
  post,
  search,
  patch,
  delete,
  upload,
  asset,
}

class DirectusRequest {
  String? token;
  final String url;
  final dynamic data;
  final HttpMethod method;
  final Function(dynamic value, {dynamic data, dynamic title}) onPrint;
  final bool parseJson;
  Map<String, String> headers;
  final List<String> _filesAttachement = [];
  final Duration? cache;
  final Directory? directory;
  final bool isWeb;
  final String? cryptKey;

  DirectusRequest({
    required this.url,
    required this.method,
    this.data,
    this.token,
    this.headers = const {},
    required this.onPrint,
    this.parseJson = true,
    this.cache,
    this.directory,
    required this.isWeb,
    this.cryptKey,
  }) {
    if (token != null) addHeader(key: "Authorization", value: "Bearer $token");
  }

  void renewToken(String? newToken) {
    token = newToken;
    if (headers.keys.contains("Authorization")) {
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      } else {
        headers.removeWhere(
          (key, value) => key == "Authorization",
        );
      }
    } else {
      if (token != null) {
        addHeader(key: "Authorization", value: "Bearer $token");
      }
    }
  }

  //DirectusRequest.get({
  //  required this.url,
  //  this.data,
  //  this.token,
  //  this.headers = const {},
  //  this.debugMode = false,
  //}) : method = HttpMethod.get;
//
  //DirectusRequest.post({
  //  required this.url,
  //  this.data,
  //  this.token,
  //  this.headers = const {},
  //  this.debugMode = false,
  //}) : method = HttpMethod.post;
//
  //DirectusRequest.search({
  //  required this.url,
  //  this.data,
  //  this.token,
  //  this.headers = const {},
  //  this.debugMode = false,
  //}) : method = HttpMethod.search;

  void addHeader({required String key, required String value}) {
    headers[key] = value;
  }

  void addMultiplesHeaders({required Map<String, String> headerList}) {
    headers.addAll(headerList);
  }

  void removeHeader({required String key}) {
    headers.removeWhere(
      (k, v) => k == key,
    );
  }

  void deleteAllHeaders() {
    headers = const {};
  }

  void addFileAttachement(String filePath) {
    _filesAttachement.add(filePath);
  }

  Future<DirectusResponse?> execute() async {
    headers["Content-Type"] = "application/json";
    //headers["Access-Control-Allow-Origin"] = "blue.fracos.fr";
    //headers["Access-Control-Allow-Credentials"] = "true";

    //onPrint("$method => $url", data: url, title: method);
    if (data != null) onPrint("Body=> $data", data: data, title: "Body");
    switch (method) {
      case HttpMethod.get:
        return _executeGetRequest();
      case HttpMethod.asset:
        return _executeAssetRequest();
      case HttpMethod.post:
        return _executePostRequest();
      case HttpMethod.search:
        return _executeSearchRequest();
      case HttpMethod.patch:
        return _executePatchRequest();
      case HttpMethod.delete:
        return _executeDeleteRequest();
      case HttpMethod.upload:
        return _executeUploadRequest();
    }
  }

  Future<DirectusResponse> _executeGetRequest() async {
    if (cache != null && directory != null) {
      onPrint("Cache Time : ${cache?.inSeconds}s");
      final cachedData = await CacheProvider(
        directory: directory,
        isWeb: isWeb,
        cryptKey: cryptKey,
      ).read(uid: url, cacheDuration: cache);
      if (cachedData != null) {
        try {
          onPrint("CACHED : $url",
              data: jsonDecode(cachedData), title: "CACHED : $url");
        } catch (_) {}
        return DirectusResponse.fromJson(cachedData, onPrint, parseJson: true);
      }
    }

    try {
      final res = await http.get(Uri.parse(url), headers: headers);
      //onPrint("GET RAW=> ${res.body}", data: res.body, title: "GET RAW $url");

      final response = DirectusResponse.fromRequest(
        url,
        res.body,
        HttpMethod.get,
        onPrint,
        parseJson,
        res.statusCode,
        bytes: res.bodyBytes,
      );

      if (cache != null && response.status == 200) {
        await CacheProvider(
          directory: directory,
          isWeb: isWeb,
          cryptKey: cryptKey,
        ).write(uid: url, data: response.toJson());
      }

      return response;
    } on DirectusErrorHttpJsonException catch (_) {
      rethrow;
    } catch (e) {
      throw DirectusErrorHttp(e.toString());
    }
  }

  Future<DirectusResponse> _executeAssetRequest() async {
    if (cache != null && directory != null) {
      onPrint("Cache Time : ${cache?.inSeconds}s");
      final cachedData = await CacheProvider(
        directory: directory,
        isWeb: isWeb,
        cryptKey: cryptKey,
      ).read(uid: url, cacheDuration: cache);
      if (cachedData != null) {
        try {
          onPrint("CACHED : $url",
              data: jsonDecode(cachedData), title: "CACHED : $url");
        } catch (_) {}
        return DirectusResponse.fromJson(cachedData, onPrint, parseJson: true);
      }
    }

    try {
      final res = await http.get(Uri.parse(url), headers: headers);
      //onPrint("GET RAW=> ${res.body}", data: res.body, title: "GET RAW $url");

      final response = DirectusResponse.fromRequest(
        url,
        res.body,
        HttpMethod.get,
        (dynamic, {dynamic data, dynamic title}) => () {},
        false,
        res.statusCode,
        bytes: res.bodyBytes,
      );

      if (cache != null && response.status == 200) {
        await CacheProvider(
          directory: directory,
          isWeb: isWeb,
          cryptKey: cryptKey,
        ).write(uid: url, data: response.toJson());
      }

      return response;
    } on DirectusErrorHttpJsonException catch (_) {
      rethrow;
    } catch (e) {
      throw DirectusErrorHttp(e.toString());
    }
  }

  Future<DirectusResponse> _executePostRequest() async {
    var client = http.Client();
    try {
      final res = await client.post(
        Uri.parse(url),
        body: jsonEncode(data),
        headers: headers,
      );
      //onPrint("POST RAW=> ${res.body}", data: res.body, title: "POST RAW $url");
      return DirectusResponse.fromRequest(
          url, res.body, HttpMethod.post, onPrint, parseJson, res.statusCode);
    } on DirectusErrorHttpJsonException catch (_) {
      rethrow;
    } catch (e) {
      throw DirectusErrorHttp(e.toString());
    }
  }

  Future<DirectusResponse?> _executeUploadRequest() async {
    //var client = http.Client();
    if (_filesAttachement.isEmpty) return null;
    try {
      final req = http.MultipartRequest("POST", Uri.parse(url));
      final File file = File(_filesAttachement[0]);
      final type = lookupMimeType(file.path);

      //print((this.data ?? {})["folder"] ?? "");
      req.fields["folder"] = (this.data ?? {})["folder"] ?? "";
      req.fields["type"] = type ?? "";
      req.fields["filename_download"] = p.basename(file.path);
      req.headers.addAll(headers);

      req.files.add(
        http.MultipartFile.fromBytes(
          "file",
          await file.readAsBytes(),
          filename: p.basename(file.path),
          contentType: MediaType.parse(type ?? ""),
        ),
      );

      final res = await req.send();
      final data = await res.stream.bytesToString();
      //onPrint(data, data: data, title: "UPLOAD");

      return DirectusResponse.fromRequest(
          url, data, HttpMethod.post, onPrint, parseJson, res.statusCode);
    } on DirectusErrorHttpJsonException catch (_) {
      rethrow;
    } catch (e) {
      throw DirectusErrorHttp(e.toString());
    }
  }

  Future<DirectusResponse> _executePatchRequest() async {
    var client = http.Client();
    try {
      final res = await client.patch(
        Uri.parse(url),
        body: jsonEncode(data),
        headers: headers,
      );
      //onPrint("PATCH RAW=> ${res.body}",
      //    data: res.body, title: "PATCH RAW $url");
      return DirectusResponse.fromRequest(
          url, res.body, HttpMethod.post, onPrint, parseJson, res.statusCode);
    } on DirectusErrorHttpJsonException catch (_) {
      rethrow;
    } catch (e) {
      throw DirectusErrorHttp(e.toString());
    }
  }

  Future<DirectusResponse> _executeDeleteRequest() async {
    try {
      final res = await http.delete(
        Uri.parse(url),
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
      );
      //onPrint("DELETE RAW=> ${res.body}",
      //    data: res.body, title: "DELETE RAW $url");
      return DirectusResponse.fromRequest(
        url,
        res.body,
        HttpMethod.delete,
        onPrint,
        parseJson,
        res.statusCode,
      );
    } on DirectusErrorHttpJsonException catch (_) {
      rethrow;
    } catch (e) {
      throw DirectusErrorHttp(e.toString());
    }
  }

  Future<DirectusResponse> _executeSearchRequest() async {
    var client = http.Client();
    try {
      final req = http.Request("SEARCH", Uri.parse(url));
      req.body = jsonEncode(data);
      req.headers.addAll(headers);

      final res = await client.send(req);

      //print(await res.stream.bytesToString());
      return DirectusResponse.fromRequest(
        url,
        await res.stream.bytesToString(),
        HttpMethod.post,
        onPrint,
        parseJson,
        res.statusCode,
      );
    } on DirectusErrorHttpJsonException catch (_) {
      rethrow;
    } catch (e) {
      throw DirectusErrorHttp(e.toString());
    }
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:fcs_directus/src/errors/errors.dart';
import 'package:fcs_directus/src/request/directus_request.dart';

class DirectusResponse {
  Map<String, dynamic> _data = {};

  final HttpMethod method;
  final String url;
  final String rawData;
  final int status;
  final Uint8List? bodyBytes;
  dynamic get data => _data;

  Map<String, dynamic> toMap() {
    dynamic val;

    if (_data.keys.contains("data")) {
      val = _data["data"];
    } else {
      val = _data;
    }

    if (val is Map<String, dynamic>) return val;
    if (val is List<Map<String, dynamic>>) return val.first;
    return {};
  }

  List<dynamic> toList() {
    dynamic val;

    if (_data.keys.contains("data")) {
      val = _data["data"];
    } else {
      val = _data;
    }

    if (val is Map<String, dynamic>) return [val];
    if (val is List<dynamic>) return val;
    return [];
  }

  String toJson() {
    return jsonEncode({
      "url": url,
      "method": method.name,
      "body": rawData,
      "status": status,
    });
  }

  DirectusResponse.fromRequest(
      this.url,
      String body,
      this.method,
      Function(dynamic value, {dynamic data, dynamic title}) onPrint,
      bool parseJson,
      this.status,
      {bool json = false,
      Uint8List? bytes})
      : rawData = body,
        bodyBytes = bytes {
    if (body.isEmpty) return;
    try {
      _data = parseJson ? jsonDecode(rawData) : {"data": rawData};
      onPrint("Parsed data=> $_data",
          data: _data,
          title:
              "${method.name.toUpperCase()}${json ? " from JSON" : ""} : $url");
    } catch (e) {
      throw DirectusErrorHttpJsonException();
    }
  }

  factory DirectusResponse.fromJson(String jsonData,
      Function(dynamic value, {dynamic data, dynamic title}) onPrint,
      {bool parseJson = false}) {
    try {
      if (jsonData.isEmpty) throw DirectusErrorHttpJsonException();
      final d = jsonDecode(jsonData);
      if (d is! Map<String, dynamic>) {
        throw DirectusErrorHttpJsonException();
      }

      return DirectusResponse.fromRequest(d["url"] ?? "", d["body"] ?? {},
          HttpMethod.get, onPrint, parseJson, d["status"],
          json: true);
    } catch (e) {
      throw DirectusErrorHttpJsonException();
    }
  }
}

import 'dart:convert';

import 'package:fcs_directus/src/errors/errors.dart';
import 'package:fcs_directus/src/request/directus_request.dart';

class DirectusResponse {
  Map<String, dynamic> _data = {};

  final HttpMethod method;
  final String url;
  final String rawData;
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
    });
  }

  DirectusResponse.fromRequest(
      this.url, String body, this.method, bool debugMode, bool parseJson)
      : rawData = body {
    if (body.isEmpty) return;
    try {
      _data = parseJson ? jsonDecode(rawData) : {"data": rawData};
      if (debugMode) print("Parsed data=> $_data");
    } catch (e) {
      throw DirectusErrorHttpJsonException();
    }
  }

  factory DirectusResponse.fromJson(String jsonData) {
    try {
      final d = jsonDecode(jsonData);
      if (d! is Map<String, dynamic>) {
        throw DirectusErrorHttpJsonException();
      }

      return DirectusResponse.fromRequest(
          d["url"] ?? "", d["body"] ?? {}, HttpMethod.get, false, false);
    } catch (e) {
      throw DirectusErrorHttpJsonException();
    }
  }
}

import 'dart:convert';

import 'package:fcs_directus/src/errors/errors.dart';
import 'package:fcs_directus/src/request/directus_request.dart';

class DirectusResponse {
  Map<String, dynamic> _data = {};

  final HttpMethod method;
  final String url;
  final String rawData;
  Map<String, dynamic> get data => _data;

  DirectusResponse.fromRequest(
      this.url, String body, this.method, bool debugMode, bool parseJson)
      : rawData = body {
    try {
      if (debugMode) print(data);
      _data = parseJson ? jsonDecode(rawData) : {"data": rawData};
    } catch (e) {
      print(e.toString());
      throw DirectusErrorHttpJsonException();
    }
  }
}

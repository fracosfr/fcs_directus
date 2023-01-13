import 'dart:convert';

import 'package:fcs_directus/src/errors/errors.dart';
import 'package:fcs_directus/src/request/directus_response.dart';
import 'package:http/http.dart' as http;

enum HttpMethod {
  get,
  post,
  search,
  //patch,
  //delete,
}

class DirectusRequest {
  final String? token;
  final String url;
  final Map<String, dynamic>? data;
  final HttpMethod method;
  Map<String, String> headers;

  DirectusRequest({
    required this.url,
    required this.method,
    this.data,
    this.token,
    this.headers = const {},
  }) {
    if (token != null) addHeader(key: "Authorization", value: "Bearer $token");
  }

  DirectusRequest.get({
    required this.url,
    this.data,
    this.token,
    this.headers = const {},
  }) : method = HttpMethod.get;

  DirectusRequest.post({
    required this.url,
    this.data,
    this.token,
    this.headers = const {},
  }) : method = HttpMethod.post;

  addHeader({required String key, required String value}) {
    headers[key] = value;
  }

  addMultiplesHeaders({required Map<String, String> headerList}) {
    headers.addAll(headerList);
  }

  removeHeader({required String key}) {
    headers.removeWhere(
      (k, v) => k == key,
    );
  }

  deleteAllHeaders() {
    headers = const {};
  }

  Future<DirectusResponse> execute() async {
    headers["Content-Type"] = "application/json";

    switch (method) {
      case HttpMethod.get:
        return _executeGetRequest();
      case HttpMethod.post:
        return _executePostRequest();
      case HttpMethod.search:
        return _executeSearchRequest();
    }
  }

  Future<DirectusResponse> _executeGetRequest() async {
    try {
      final res = await http.get(Uri.parse(url), headers: headers);
      return DirectusResponse.fromRequest(url, res.body, HttpMethod.get);
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
      return DirectusResponse.fromRequest(url, res.body, HttpMethod.post);
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
          url, await res.stream.bytesToString(), HttpMethod.post);
    } on DirectusErrorHttpJsonException catch (_) {
      rethrow;
    } catch (e) {
      throw DirectusErrorHttp(e.toString());
    }
  }
}

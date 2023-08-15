import 'dart:convert';

import 'package:fcs_directus/src/errors/errors.dart';
import 'package:fcs_directus/src/request/directus_response.dart';
import 'package:http/http.dart' as http;

enum HttpMethod {
  get,
  post,
  search,
  patch,
  delete,
}

class DirectusRequest {
  final String? token;
  final String url;
  final dynamic data;
  final HttpMethod method;
  final Function(dynamic value) onPrint;
  final bool parseJson;
  Map<String, String> headers;

  DirectusRequest({
    required this.url,
    required this.method,
    this.data,
    this.token,
    this.headers = const {},
    required this.onPrint,
    this.parseJson = true,
  }) {
    if (token != null) addHeader(key: "Authorization", value: "Bearer $token");
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
    //headers["Access-Control-Allow-Origin"] = "blue.fracos.fr";
    //headers["Access-Control-Allow-Credentials"] = "true";

    onPrint("$method => $url");
    if (data != null) onPrint("Body=> $data");

    switch (method) {
      case HttpMethod.get:
        return _executeGetRequest();
      case HttpMethod.post:
        return _executePostRequest();
      case HttpMethod.search:
        return _executeSearchRequest();
      case HttpMethod.patch:
        return _executePatchRequest();
      case HttpMethod.delete:
        return _executeDeleteRequest();
    }
  }

  Future<DirectusResponse> _executeGetRequest() async {
    try {
      final res = await http.get(Uri.parse(url), headers: headers);
      onPrint("GET RAW=> ${res.body}");
      return DirectusResponse.fromRequest(
        url,
        res.body,
        HttpMethod.get,
        onPrint,
        parseJson,
      );
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
      onPrint("POST RAW=> ${res.body}");
      return DirectusResponse.fromRequest(
          url, res.body, HttpMethod.post, onPrint, parseJson);
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
      onPrint("PATCH RAW=> ${res.body}");
      return DirectusResponse.fromRequest(
          url, res.body, HttpMethod.post, onPrint, parseJson);
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
      onPrint("DELETE RAW=> ${res.body}");
      return DirectusResponse.fromRequest(
        url,
        res.body,
        HttpMethod.delete,
        onPrint,
        parseJson,
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
      );
    } on DirectusErrorHttpJsonException catch (_) {
      rethrow;
    } catch (e) {
      throw DirectusErrorHttp(e.toString());
    }
  }
}

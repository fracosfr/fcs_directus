import 'dart:io';

import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/errors/errors.dart';
import 'package:fcs_directus/src/modules/auth/models/login_model.dart';
import 'package:fcs_directus/src/modules/auth/urls.dart';
import 'package:fcs_directus/src/request/directus_request.dart';
import 'package:fcs_directus/src/request/directus_response.dart';

class RequestManager {
  String? _token;
  String? _renewToken;
  String? _serverUrl;
  final String? clientName;
  bool _debugMode = false;
  Function(dynamic value, {dynamic data, dynamic title})? _onDebugPrint;
  final Function(bool isConnected) onConnexionChange;
  final Function(String? refreshKoken) onRefreshTokenChange;
  String get serverUrl => _serverUrl ?? "";
  String? get token => _token;
  final Map<String, String>? headers;
  final Directory? directory;
  final bool isWeb;

  RequestManager(this.onConnexionChange, this.onRefreshTokenChange,
      this.clientName, this.headers, this.directory, this.isWeb);

  bool get debugMode => _debugMode;

  bool get connected => (_token ?? "").isNotEmpty;

  void setStaticToken({required String? staticToken}) {
    _token = staticToken;
  }

  void setDebugMode(bool debug) {
    _debugMode = debug;
  }

  void setDebugPrintFunction(
      void Function(dynamic value, {dynamic data, dynamic title})
          printFunction) {
    _onDebugPrint = printFunction;
  }

  void debugPrint(dynamic value, {dynamic data, dynamic title}) {
    if (_debugMode) {
      if (_onDebugPrint != null) {
        _onDebugPrint!(value, data: data, title: title);
      } else {
        print(value);
      }
    }
  }

  void setServerUrl({required String? url}) {
    if (url == null) return;
    _serverUrl = url.endsWith("/") ? url.substring(0, url.length - 1) : url;
  }

  Future<DirectusResponse> uploadFile({
    required String url,
    dynamic data,
    bool authentification = true,
    bool parseJson = true,
    required String filePath,
  }) async {
    final request = DirectusRequest(
      url: "$_serverUrl$url",
      method: HttpMethod.upload,
      headers: {},
      token: authentification ? _token : null,
      onPrint: debugPrint,
      parseJson: parseJson,
      data: data,
      isWeb: isWeb,
    );

    request.addFileAttachement(filePath);
    final response = await request.execute();
    if (authentification) {
      final errorParser = ErrorParser(response?.toMap() ?? {});
      if (errorParser.errorDetected) {
        if (errorParser.code == "TOKEN_EXPIRED" ||
            errorParser.code == "INVALID_CREDENTIALS") {
          loginWithRefreshToken(_renewToken)
              .then((value) => onConnexionChange(value));
        } else {
          //onConnexionChange(false);
          errorParser.sendError();
        }
      }
    }
    return response ??
        DirectusResponse.fromJson(
          "{}",
          (value, {data, title}) => null,
        );
  }

  Future<DirectusResponse> executeRequest({
    required String url,
    dynamic data,
    Map<String, String>? headers,
    HttpMethod method = HttpMethod.get,
    bool authentification = true,
    bool parseJson = true,
    Duration? cache,
  }) async {
    final globalHeaders = this.headers ?? {};
    final Map<String, String> saltedHeader = (headers ?? {});
    saltedHeader.addAll(globalHeaders);

    if (clientName != null) {
      saltedHeader["user-agent"] = clientName ?? "FcsDirectus";
    }
    final request = DirectusRequest(
      url: "$_serverUrl$url",
      method: method,
      headers: saltedHeader,
      data: data,
      token: authentification ? _token : null,
      onPrint: debugPrint,
      parseJson: parseJson,
      cache: cache,
      directory: directory,
      isWeb: isWeb,
    );

    try {
      var response = await request.execute();

      if (authentification) {
        final errorParser = ErrorParser(response?.toMap() ?? {});

        if (errorParser.errorDetected) {
          if (errorParser.code == "TOKEN_EXPIRED" ||
              errorParser.code == "INVALID_CREDENTIALS") {
            await loginWithRefreshToken(_renewToken);
            await Future.delayed(const Duration(milliseconds: 250));
            request.renewToken(token);
            response = await request.execute();
          } else {
            //onConnexionChange(false);
            errorParser.sendError();
          }
        }
      }

      return response ??
          DirectusResponse.fromJson("{}", (value, {data, title}) => null);
    } on DirectusError catch (e) {
      print(e.message);
    }

    return DirectusResponse.fromJson("{}", (value, {data, title}) => null);
  }

  String? get refreshToken => _renewToken;

  Future<bool> login({
    required String login,
    required String password,
  }) async {
    final data = {"email": login, "password": password};
    final result = await executeRequest(
      url: AuthentificationUrls.login,
      data: data,
      authentification: false,
      method: HttpMethod.post,
    );

    final errorParser = ErrorParser(result.toMap());
    if (errorParser.errorDetected) {
      errorParser.sendError();
    }

    try {
      final m = LoginModel.fromResponse(result.toMap());
      _token = m.accessToken;
      _renewToken = m.refreshToken;
      if ((_token ?? "").isNotEmpty && (_renewToken ?? "").isNotEmpty) {
        onConnexionChange(true);
        onRefreshTokenChange(_renewToken);
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }

  void logout() {
    _token = null;
    _renewToken = null;
    onRefreshTokenChange(null);
    onConnexionChange(false);
  }

  Future<bool> loginWithRefreshToken(String? refreshToken) async {
    if (refreshToken != null) _renewToken = refreshToken;
    if (_renewToken == null) return false;

    final data = {"refresh_token": _renewToken, "mode": "json"};
    final result = await executeRequest(
      url: AuthentificationUrls.refresh,
      data: data,
      authentification: false,
      method: HttpMethod.post,
    );

    final errorParser = ErrorParser(result.toMap());
    if (errorParser.errorDetected) {
      errorParser.sendError();
    }

    try {
      final m = LoginModel.fromResponse(result.toMap());
      _token = m.accessToken;
      _renewToken = m.refreshToken;
      if ((_token ?? "").isNotEmpty && (_renewToken ?? "").isNotEmpty) {
        onConnexionChange(true);
        onRefreshTokenChange(_renewToken);
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }
}

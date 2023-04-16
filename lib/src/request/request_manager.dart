import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/modules/auth/models/login_model.dart';
import 'package:fcs_directus/src/modules/auth/urls.dart';
import 'package:fcs_directus/src/request/directus_request.dart';
import 'package:fcs_directus/src/request/directus_response.dart';

class RequestManager {
  String? _token;
  String? _renewToken;
  String? _serverUrl;
  bool _debugMode = false;
  final Function(bool isConnected) onConnexionChange;
  final Function(String? refreshKoken) onRefreshTokenChange;

  RequestManager(this.onConnexionChange, this.onRefreshTokenChange);

  bool get debugMode => _debugMode;

  bool get connected => (_token ?? "").isNotEmpty;

  void setStaticToken({required String? staticToken}) {
    _token = staticToken;
  }

  void setDebugMode(bool debug) {
    _debugMode = debug;
  }

  void setServerUrl({required String? url}) {
    if (url == null) return;
    _serverUrl = url.endsWith("/") ? url.substring(0, url.length - 1) : url;
  }

  Future<DirectusResponse> executeRequest({
    required String url,
    dynamic data,
    Map<String, String>? headers,
    HttpMethod method = HttpMethod.get,
    bool authentification = true,
    bool parseJson = true,
  }) async {
    final request = DirectusRequest(
      url: "$_serverUrl$url",
      method: method,
      headers: headers ?? {},
      data: data,
      token: authentification ? _token : null,
      debugMode: _debugMode,
      parseJson: parseJson,
    );

    final response = await request.execute();

    if (authentification) {
      final errorParser = ErrorParser(response.toMap());
      if (errorParser.errorDetected) {
        print("A TRAITER => ${errorParser.code}");
        onConnexionChange(false);
        errorParser.sendError();
      }
    }

    return response;
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

  Future<bool> loginWithRefreshToken(String? refreshToken) async {
    if (_renewToken != null) _renewToken = refreshToken;
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

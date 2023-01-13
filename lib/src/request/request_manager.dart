import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/modules/auth/models/login_model.dart';
import 'package:fcs_directus/src/modules/auth/urls.dart';
import 'package:fcs_directus/src/request/directus_request.dart';
import 'package:fcs_directus/src/request/directus_response.dart';

class RequestManager {
  String? _token;
  String? _renewToken;
  String? _serverUrl;

  void setStaticToken({required String? staticToken}) {
    _token = staticToken;
  }

  void setServerUrl({required String? url}) {
    if (url == null) return;
    _serverUrl = url.endsWith("/") ? url.substring(0, url.length - 1) : url;
  }

  bool _refreshToken() {
    print("REFRESH TOKEN");
    return false;
  }

  Future<DirectusResponse> executeRequest({
    required String url,
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    HttpMethod method = HttpMethod.get,
    bool authentification = true,
    bool debugMode = false,
  }) async {
    final request = DirectusRequest(
      url: "$_serverUrl$url",
      method: method,
      headers: headers ?? {},
      data: data,
      token: authentification ? _token : null,
    );

    final response = await request.execute();

    if (authentification) {
      final errorParser = ErrorParser(response.data);
      if (errorParser.errorDetected) {
        print("A TRAITER => ${errorParser.code}");
        errorParser.sendError();
      }
    }

    return response;
  }

  Future<bool> login({
    required String login,
    required String password,
    bool debugMode = false,
  }) async {
    final data = {"email": login, "password": password};
    final result = await executeRequest(
      url: AuthentificationUrls.login,
      data: data,
      authentification: false,
      method: HttpMethod.post,
      debugMode: debugMode,
    );

    try {
      final m = LoginModel.fromResponse(result);
      _token = m.accessToken;
      _renewToken = m.refreshToken;

      return true;
    } catch (e) {
      rethrow;
    }
  }
}

import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/request/directus_request.dart';
import 'package:fcs_directus/src/request/request_manager.dart';

class ModAuthentification {
  final RequestManager _requestManager;

  ModAuthentification(this._requestManager);

  void setToken({required String token}) {
    _requestManager.setStaticToken(staticToken: token);
  }

  bool get connected => _requestManager.connected;

  Future<bool> restoreSession(refreshToken) {
    try {
      return _requestManager.loginWithRefreshToken(refreshToken);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> login(
      {required String login, required String password, String? otp}) async {
    try {
      return await _requestManager.login(
          login: login, password: password, otp: otp);
    } catch (e) {
      rethrow;
    }
  }

  bool logout() {
    _requestManager.logout();
    return true;
  }

  Future<bool> requestPasswordReset(
      {required String email, String? resetUrl}) async {
    try {
      final response = await _requestManager.executeRequest(
        url: "/auth/password/request",
        authentification: false,
        method: HttpMethod.post,
        data: resetUrl != null
            ? {"email": email, "reset_url": resetUrl}
            : {"email": email},
      );

      ErrorParser(response).sendError();

      return response.rawData.isEmpty;
    } catch (e) {
      rethrow;
    }
  }

  String? get refreshToken => _requestManager.refreshToken;

  Future<bool> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await _requestManager.executeRequest(
        url: "/auth/password/reset",
        authentification: false,
        method: HttpMethod.post,
        data: {"token": resetToken, "password": newPassword},
      );

      ErrorParser(response).sendError();

      return response.rawData.isEmpty;
    } catch (e) {
      rethrow;
    }
  }
}

import 'package:fcs_directus/src/request/request_manager.dart';

class ModAuthentification {
  final RequestManager _requestManager;

  ModAuthentification(this._requestManager);

  void setToken({required String token}) {
    _requestManager.setStaticToken(staticToken: token);
  }

  bool get connected => _requestManager.connected;

  Future<bool> restoreSession(refreshToken) =>
      _requestManager.loginWithRefreshToken(refreshToken);

  Future<bool> login({required String login, required String password}) async {
    try {
      return await _requestManager.login(login: login, password: password);
    } catch (e) {
      rethrow;
    }
  }

  bool logout() {
    _requestManager.logout();
    return true;
  }

  bool requestPasswordReset({required String email}) {
    print("REQUEST PASSWORD RESET");
    return false;
  }

  String? get refreshToken => _requestManager.refreshToken;

  bool resetPassword({
    required String resetToken,
    required String newPassword,
  }) {
    print("RESET PASSWORD");
    return false;
  }
}

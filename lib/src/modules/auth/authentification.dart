import 'package:fcs_directus/src/request/request_manager.dart';

class ModAuthentification {
  final RequestManager _requestManager;

  ModAuthentification(this._requestManager);

  void setToken({required String token}) {
    _requestManager.setStaticToken(staticToken: token);
  }

  bool get connected => _requestManager.connected;

  Future<bool> restoreSession({required String refreshToken}) async => false;

  Future<bool> login({required String login, required String password}) async {
    try {
      return await _requestManager.login(login: login, password: password);
    } catch (e) {
      rethrow;
    }
  }

  bool logout() {
    print("LOGOUT");
    return false;
  }

  bool requestPasswordReset({required String email}) {
    print("REQUEST PASSWORD RESET");
    return false;
  }

  bool resetPassword({
    required String resetToken,
    required String newPassword,
  }) {
    print("RESET PASSWORD");
    return false;
  }
}

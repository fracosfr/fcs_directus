import 'package:fcs_directus/src/internal/request_manager.dart';

class FcsDirectusAuthentification {
  final FcsDirectusRequestManager _requestManager;

  FcsDirectusAuthentification(this._requestManager);

  void setToken({required String token}) {
    _requestManager.setToken(token: token);
  }

  bool login({required String login, required String password}) {
    print("LOGIN");
    return false;
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

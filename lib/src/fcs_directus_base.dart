import 'package:fcs_directus/src/internal/request_manager.dart';
import 'package:fcs_directus/src/modules/auth/authentification.dart';

class FcsDirectus {
  final FcsDirectusRequestManager _requestManager = FcsDirectusRequestManager();
  static FcsDirectus? _instance;

  /// Get an unique instance (singleton) of [FcsDirectus].
  factory FcsDirectus.instance() {
    _instance ??= FcsDirectus();
    return _instance!;
  }

  /// Initialise a new Instance of [FcsDirectus].
  /// [token] may be filled with a unique token, however for an login/password dont use this and call [auth.login(login: login, password: password)] method.
  FcsDirectus({String? token}) {
    if (token != null) _requestManager.setToken(token: token);
  }

  /// For authentification request
  FcsDirectusAuthentification get auth =>
      FcsDirectusAuthentification(_requestManager);
}

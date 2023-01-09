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
  /// [staticToken] may be filled with a unique token, however for an login/password dont use this and call [auth.login(login: login, password: password)] method.
  FcsDirectus({String? serverUrl, String? staticToken}) {
    _requestManager.setServerUrl(url: serverUrl);
    _requestManager.setStaticToken(staticToken: staticToken);
  }

  /// For authentification request
  FcsDirectusAuthentification get auth =>
      FcsDirectusAuthentification(_requestManager);

  /// Set the server url if you dont done it with constructor, or if you are using singleton.
  void setServerUrl({required String url}) {
    _requestManager.setServerUrl(url: url);
  }
}

import 'package:fcs_directus/src/modules/item/item.dart';
import 'package:fcs_directus/src/modules/object/object.dart';
import 'package:fcs_directus/src/modules/server/server.dart';
import 'package:fcs_directus/src/request/request_manager.dart';
import 'package:fcs_directus/src/modules/auth/authentification.dart';

class FcsDirectus {
  final RequestManager _requestManager = RequestManager();
  static FcsDirectus? _instance;

  /// Get an unique instance (singleton) of [FcsDirectus].
  factory FcsDirectus.instance() {
    _instance ??= FcsDirectus();
    return _instance!;
  }

  bool get debug => _requestManager.debugMode;
  set debug(bool v) {
    _requestManager.setDebugMode(v);
  }

  /// Initialise a new Instance of [FcsDirectus].
  /// [staticToken] may be filled with a unique token, however for an login/password dont use this and call [auth.login(login: login, password: password)] method.
  FcsDirectus({String? serverUrl, String? staticToken}) {
    _requestManager.setServerUrl(url: serverUrl);
    _requestManager.setStaticToken(staticToken: staticToken);
  }

  /// For authentification request
  ModAuthentification get auth => ModAuthentification(_requestManager);

  /// For items management
  ModItem item(String itemName) => ModItem(
        _requestManager,
        itemName,
      );

  /// For objects management
  ModObject get object => ModObject(_requestManager);

  /// Server utilities
  ModServer get server => ModServer(_requestManager);

  /// Set the server url if you dont done it with constructor, or if you are using singleton.
  void setServerUrl({required String url}) {
    _requestManager.setServerUrl(url: url);
  }
}

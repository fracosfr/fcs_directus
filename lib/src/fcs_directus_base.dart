import 'package:fcs_directus/src/modules/activity/activity.dart';
import 'package:fcs_directus/src/modules/files/file.dart';
import 'package:fcs_directus/src/modules/flow/flow.dart';
import 'package:fcs_directus/src/modules/item/item.dart';
import 'package:fcs_directus/src/modules/object/object.dart';
import 'package:fcs_directus/src/modules/realtime/realtime.dart';
import 'package:fcs_directus/src/modules/server/server.dart';
import 'package:fcs_directus/src/modules/user/user.dart';
import 'package:fcs_directus/src/request/request_manager.dart';
import 'package:fcs_directus/src/modules/auth/authentification.dart';

class FcsDirectus {
  static FcsDirectus? _instance;
  final Function(bool isConnected)? onConnexionChange;
  final Function(String? refreshKoken)? onRefreshTokenChange;
  late RequestManager _requestManager;
  final String? clientName;

  /// Get an unique instance (singleton) of [FcsDirectus].
  factory FcsDirectus.singleton({
    String? serverUrl,
    String? staticToken,
    String? clientName,
    Function(bool isConnected)? onConnexionChange,
    Function(String? refreshKoken)? onRefreshTokenChange,
  }) {
    _instance ??= FcsDirectus(
      serverUrl: serverUrl,
      staticToken: staticToken,
      clientName: clientName,
      onConnexionChange: onConnexionChange,
      onRefreshTokenChange: onRefreshTokenChange,
    );
    return _instance!;
  }

  /// Get an unique instance (singleton) of [FcsDirectus], for create singleton
  /// with parameters consider using [FcsDirectus.singleton] first.
  static FcsDirectus get instance => _instance ??= FcsDirectus.singleton();

  /// Enable debug print
  bool get debug => _requestManager.debugMode;
  set debug(bool v) {
    _requestManager.setDebugMode(v);
  }

  /// Custom print function for debug.
  void setDebugPrintFunction(void Function(dynamic value) printFunction) {
    _requestManager.setDebugPrintFunction(printFunction);
  }

  /// Initialise a new Instance of [FcsDirectus].
  /// [staticToken] may be filled with a unique token, however for an login/password dont use this and call [auth.login(login: login, password: password)] method.
  FcsDirectus({
    String? serverUrl,
    String? staticToken,
    this.clientName,
    this.onConnexionChange,
    this.onRefreshTokenChange,
  }) {
    _requestManager = RequestManager(onConnexionChange ?? (bool test) {},
        onRefreshTokenChange ?? (String? refreshKoken) {}, clientName);
    if (serverUrl != null) _requestManager.setServerUrl(url: serverUrl);
    if (staticToken != null) {
      _requestManager.setStaticToken(staticToken: staticToken);
    }
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

  /// User management
  ModUser get user => ModUser(_requestManager);

  ModFile get file => ModFile(_requestManager);

  ModFlow get flow => ModFlow(_requestManager);

  ModRealTime get realtime => ModRealTime(_requestManager);

  ModActivity get activity => ModActivity(_requestManager);

  /// Set the server url if you dont done it with constructor, or if you are using singleton.
  void setServerUrl({required String url}) {
    _requestManager.setServerUrl(url: url);
  }
}

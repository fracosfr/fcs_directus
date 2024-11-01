import 'package:fcs_directus/fcs_directus.dart';
import 'package:fcs_directus/src/request/request_manager.dart';

class ModRealTime {
  ModRealTime(this._requestManager);

  final RequestManager _requestManager;

  Future<DirectusWebsocket?> listen<T extends DirectusItemModel>(
      {required T Function(Map<String, dynamic> data) itemCreator,
      //{required dynamic itemCreator,
      DirectusParams? params,
      required Null Function(List<T> items, String event) parser,
      required Function() onClose,
      required Function(dynamic e) onError}) async {
    try {
      final ws = DirectusWebsocket<T>(
          _requestManager, itemCreator, params, parser, onClose, onError);
      await ws.connect();
      return ws.exist ? ws : null;
    } catch (_) {
      return null;
    }
  }
}

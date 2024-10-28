import 'dart:async';
import 'dart:convert';

import 'package:fcs_directus/fcs_directus.dart';
import 'package:fcs_directus/src/request/request_manager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DirectusWebsocket<T extends DirectusItemModel> {
  WebSocketChannel? _channel;
  final RequestManager _requestManager;
  StreamSubscription? _streamSubscription;
  final DirectusParams? params;
  late String objectName;
  final T Function(Map<String, dynamic> data) itemCreator;
  final Function(List<T> items, String event) parser;

  DirectusWebsocket(
      this._requestManager, this.itemCreator, this.params, this.parser) {
    final objTemp = itemCreator({});
    objectName = objTemp.itemName ?? "ERROR!!!";
    print("Ouverture de la connexion");
    final serverUrl = _requestManager.serverUrl
        .replaceAll("https://", "wss://")
        .replaceAll("http://", "ws://");
    _openConnexion("$serverUrl/websocket").then(
      (_) {},
    );
  }

  Future _openConnexion(String url) async {
    print(url);
    _channel = WebSocketChannel.connect(Uri.parse(url));
    //_channel?.sink.add(
    //    jsonEncode({"type": "auth", "access_token": _requestManager.token}));

    if (_channel == null) return;
    await _channel?.ready;

    //_channel?.sink.add(_prepareSendCommand("items", "read", objectName));
    _send("subscribe", data: {"collection": "public_config"});

    _streamSubscription = _channel?.stream.listen((event) {
      final mapEvent = jsonDecode(event);
      switch (mapEvent["type"] ?? "") {
        case "ping":
          _send("pong");
          break;
        case "subscription":
          _callbackFunction(mapEvent);
          break;
        default:
          print(mapEvent);
          break;
      }
    }, onDone: () {
      print("DONE");
    }, onError: (e) {
      print("ERROR ${e.toString()}");
    });
  }

  void _callbackFunction(dynamic mapEvent) {
    final String event = mapEvent["event"];
    final List<T> data = [];
    final List<dynamic> mapData = mapEvent['data'] ?? [];
    for (final item in mapData) {
      data.add(itemCreator(item));
    }
    parser(data, event);
  }

  void _send(String type, {Map<String, dynamic>? data}) {
    final mapData = data ?? {};
    mapData["type"] = type;
    final jsonData = jsonEncode(mapData);
    print("Send : $jsonData");
    _channel?.sink.add(jsonData);
  }

  void destroy() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }
}

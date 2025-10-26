import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logging/logging.dart';
import '../core/directus_config.dart';

/// Types d'événements WebSocket
enum DirectusWebSocketEvent {
  connect,
  disconnect,
  error,
  subscribe,
  unsubscribe,
  message,
}

/// Message WebSocket Directus
class DirectusWebSocketMessage {
  final String type;
  final Map<String, dynamic>? data;
  final String? uid;
  final String? event;

  DirectusWebSocketMessage({
    required this.type,
    this.data,
    this.uid,
    this.event,
  });

  factory DirectusWebSocketMessage.fromJson(Map<String, dynamic> json) {
    return DirectusWebSocketMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>?,
      uid: json['uid'] as String?,
      event: json['event'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (data != null) 'data': data,
      if (uid != null) 'uid': uid,
      if (event != null) 'event': event,
    };
  }
}

/// Client WebSocket pour Directus.
///
/// Permet de recevoir des mises à jour en temps réel depuis Directus.
///
/// Exemple d'utilisation:
/// ```dart
/// final wsClient = DirectusWebSocketClient(config, accessToken: 'token');
///
/// // Se connecter
/// await wsClient.connect();
///
/// // S'abonner à une collection
/// wsClient.subscribe(
///   collection: 'articles',
///   onMessage: (message) {
///     print('Nouveau message: $message');
///   },
/// );
///
/// // Se désabonner
/// await wsClient.unsubscribe('articles');
///
/// // Fermer la connexion
/// await wsClient.disconnect();
/// ```
class DirectusWebSocketClient {
  final DirectusConfig _config;
  final String? _accessToken;
  final Logger _logger;

  WebSocketChannel? _channel;
  bool _isConnected = false;
  int _messageId = 0;

  final Map<String, StreamSubscription> _subscriptions = {};
  final StreamController<DirectusWebSocketMessage> _messageController =
      StreamController.broadcast();

  /// Stream des messages reçus
  Stream<DirectusWebSocketMessage> get messages => _messageController.stream;

  /// Indique si le client est connecté
  bool get isConnected => _isConnected;

  /// Crée un nouveau client WebSocket
  DirectusWebSocketClient(this._config, {String? accessToken})
    : _accessToken = accessToken,
      _logger = Logger('DirectusWebSocketClient');

  /// Se connecte au serveur WebSocket
  Future<void> connect() async {
    if (_isConnected) {
      _logger.warning('Déjà connecté');
      return;
    }

    try {
      final wsUrl = _config.baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');

      final uri = Uri.parse('$wsUrl/websocket');

      _logger.info('Connexion à $uri');
      _channel = WebSocketChannel.connect(uri);

      // Écouter les messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _logger.severe('Erreur WebSocket', error);
          _messageController.addError(error);
        },
        onDone: () {
          _logger.info('Connexion WebSocket fermée');
          _isConnected = false;
        },
        cancelOnError: false,
      );

      // Authentification si token fourni
      if (_accessToken != null) {
        await _authenticate();
      }

      _isConnected = true;
      _logger.info('Connecté au WebSocket Directus');
    } catch (e) {
      _logger.severe('Erreur lors de la connexion', e);
      rethrow;
    }
  }

  /// Authentification via WebSocket
  Future<void> _authenticate() async {
    final message = DirectusWebSocketMessage(
      type: 'auth',
      data: {'access_token': _accessToken},
    );

    _send(message);
  }

  /// Gère les messages reçus
  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = DirectusWebSocketMessage.fromJson(json);

      _logger.fine('Message reçu: ${message.type}');
      _messageController.add(message);
    } catch (e) {
      _logger.severe('Erreur lors du parsing du message', e);
    }
  }

  /// S'abonne à une collection pour recevoir les mises à jour
  ///
  /// [collection] Nom de la collection
  /// [event] Type d'événement (create, update, delete) ou null pour tous
  /// [query] Paramètres de requête pour filtrer
  /// [onMessage] Callback appelé lors de la réception d'un message
  Future<String> subscribe({
    required String collection,
    String? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    if (!_isConnected) {
      throw Exception('Non connecté au WebSocket');
    }

    final uid = 'sub_${_messageId++}';

    // Créer la souscription locale
    final subscription = messages
        .where((msg) => msg.uid == uid || msg.data?['collection'] == collection)
        .listen(onMessage);

    _subscriptions[uid] = subscription;

    // Envoyer la demande de souscription au serveur
    final message = DirectusWebSocketMessage(
      type: 'subscribe',
      uid: uid,
      data: {
        'collection': collection,
        if (event != null) 'event': event,
        if (query != null) 'query': query,
      },
    );

    _send(message);
    _logger.info('Souscription à $collection avec uid=$uid');

    return uid;
  }

  /// Se désabonne d'une collection
  ///
  /// [uid] UID de la souscription retourné par subscribe()
  Future<void> unsubscribe(String uid) async {
    if (!_isConnected) {
      _logger.warning('Non connecté');
      return;
    }

    // Annuler la souscription locale
    await _subscriptions[uid]?.cancel();
    _subscriptions.remove(uid);

    // Envoyer la demande de désinscription au serveur
    final message = DirectusWebSocketMessage(type: 'unsubscribe', uid: uid);

    _send(message);
    _logger.info('Désinscription de uid=$uid');
  }

  /// Envoie un message au serveur
  void _send(DirectusWebSocketMessage message) {
    if (_channel == null) {
      throw Exception('Canal WebSocket non initialisé');
    }

    final json = jsonEncode(message.toJson());
    _channel!.sink.add(json);
    _logger.fine('Message envoyé: ${message.type}');
  }

  /// Envoie un ping au serveur
  void ping() {
    _send(DirectusWebSocketMessage(type: 'ping'));
  }

  /// Se déconnecte du serveur WebSocket
  Future<void> disconnect() async {
    if (!_isConnected) {
      return;
    }

    _logger.info('Déconnexion du WebSocket');

    // Annuler toutes les souscriptions
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    // Fermer le canal
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  /// Ferme le client et libère les ressources
  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
  }
}

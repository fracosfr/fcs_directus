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

/// Événements CRUD sur les items Directus
enum DirectusItemEvent {
  /// Un nouvel item a été créé
  create,

  /// Un item existant a été modifié
  update,

  /// Un item a été supprimé
  delete;

  /// Convertit une string en DirectusItemEvent
  static DirectusItemEvent? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'create':
        return DirectusItemEvent.create;
      case 'update':
        return DirectusItemEvent.update;
      case 'delete':
        return DirectusItemEvent.delete;
      default:
        return null;
    }
  }

  /// Convertit l'enum en string pour l'API
  String toApiString() {
    return name;
  }
}

/// Message WebSocket Directus
class DirectusWebSocketMessage {
  final String type;
  final Map<String, dynamic>? data;
  final String? uid;
  final DirectusItemEvent? event;

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
      event: DirectusItemEvent.fromString(json['event'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (data != null) 'data': data,
      if (uid != null) 'uid': uid,
      if (event != null) 'event': event!.toApiString(),
    };
  }
}

/// Client WebSocket pour Directus.
///
/// Permet de recevoir des mises à jour en temps réel depuis Directus.
/// Supporte les événements CRUD (create, update, delete) sur toutes les collections.
///
/// Collections système supportées:
/// - directus_users (Users)
/// - directus_files (Files)
/// - directus_folders (Folders)
/// - directus_activity (Activity)
/// - directus_notifications (Notifications)
/// - directus_comments (Comments)
/// - directus_revisions (Revisions)
/// - directus_shares (Shares)
/// - directus_versions (Versions)
/// - Et toutes les collections personnalisées
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
/// // S'abonner à un événement spécifique
/// wsClient.subscribe(
///   collection: 'articles',
///   event: 'create',
///   onMessage: (message) {
///     print('Nouvel article créé: ${message.data}');
///   },
/// );
///
/// // Utiliser les helpers pour les collections système
/// await wsClient.subscribeToUsers(onMessage: (msg) => print(msg));
/// await wsClient.subscribeToNotifications(onMessage: (msg) => print(msg));
///
/// // Se désabonner
/// await wsClient.unsubscribe('subscription-id');
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

      // Répondre automatiquement aux pings avec un pong
      if (message.type == 'ping') {
        _logger.fine('Ping reçu, envoi du pong');
        _send(DirectusWebSocketMessage(type: 'pong'));
      }

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
    DirectusItemEvent? event,
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
        if (event != null) 'event': event.toApiString(),
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

  /// Envoie un ping au serveur pour vérifier la connexion
  ///
  /// Le serveur enverra périodiquement des pings automatiquement,
  /// auxquels le client répondra automatiquement avec un pong.
  /// Cette méthode permet d'envoyer un ping manuellement si nécessaire.
  void ping() {
    _send(DirectusWebSocketMessage(type: 'ping'));
  }

  /// Envoie un pong au serveur en réponse à un ping
  ///
  /// Note: Les pongs sont automatiquement envoyés en réponse aux pings reçus.
  /// Cette méthode est disponible pour un contrôle manuel si nécessaire.
  void pong() {
    _send(DirectusWebSocketMessage(type: 'pong'));
  }

  // ============================================================================
  // Méthodes helper pour les collections système Directus
  // ============================================================================

  /// S'abonne aux mises à jour des utilisateurs (directus_users)
  ///
  /// [event] Type d'événement: create, update, delete ou null pour tous
  /// [query] Filtres optionnels pour limiter les événements
  /// [onMessage] Callback appelé lors de la réception d'un message
  ///
  /// Retourne l'UID de la souscription pour pouvoir se désabonner
  Future<String> subscribeToUsers({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_users',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des fichiers (directus_files)
  Future<String> subscribeToFiles({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_files',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des dossiers (directus_folders)
  Future<String> subscribeToFolders({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_folders',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour de l'activité (directus_activity)
  Future<String> subscribeToActivity({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_activity',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des notifications (directus_notifications)
  Future<String> subscribeToNotifications({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_notifications',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des commentaires (directus_comments)
  Future<String> subscribeToComments({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_comments',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des révisions (directus_revisions)
  Future<String> subscribeToRevisions({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_revisions',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des partages (directus_shares)
  Future<String> subscribeToShares({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_shares',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des versions (directus_versions)
  Future<String> subscribeToVersions({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_versions',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des traductions (directus_translations)
  Future<String> subscribeToTranslations({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_translations',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des permissions (directus_permissions)
  Future<String> subscribeToPermissions({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_permissions',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des préférences (directus_presets)
  Future<String> subscribeToPresets({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_presets',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des rôles (directus_roles)
  Future<String> subscribeToRoles({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_roles',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des politiques (directus_policies)
  Future<String> subscribeToPolicies({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_policies',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des dashboards (directus_dashboards)
  Future<String> subscribeToDashboards({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_dashboards',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des panneaux (directus_panels)
  Future<String> subscribeToPanels({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_panels',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des flows (directus_flows)
  Future<String> subscribeToFlows({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_flows',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne aux mises à jour des opérations (directus_operations)
  Future<String> subscribeToOperations({
    DirectusItemEvent? event,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: 'directus_operations',
      event: event,
      query: query,
      onMessage: onMessage,
    );
  }

  // ============================================================================
  // Méthodes helper pour événements spécifiques
  // ============================================================================

  /// S'abonne uniquement aux événements de création sur une collection
  ///
  /// [collection] Nom de la collection
  /// [query] Filtres optionnels
  /// [onMessage] Callback appelé lors de la réception d'un message
  Future<String> subscribeToCreate({
    required String collection,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: collection,
      event: DirectusItemEvent.create,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne uniquement aux événements de mise à jour sur une collection
  ///
  /// [collection] Nom de la collection
  /// [query] Filtres optionnels
  /// [onMessage] Callback appelé lors de la réception d'un message
  Future<String> subscribeToUpdate({
    required String collection,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: collection,
      event: DirectusItemEvent.update,
      query: query,
      onMessage: onMessage,
    );
  }

  /// S'abonne uniquement aux événements de suppression sur une collection
  ///
  /// [collection] Nom de la collection
  /// [query] Filtres optionnels
  /// [onMessage] Callback appelé lors de la réception d'un message
  Future<String> subscribeToDelete({
    required String collection,
    Map<String, dynamic>? query,
    required Function(DirectusWebSocketMessage) onMessage,
  }) async {
    return await subscribe(
      collection: collection,
      event: DirectusItemEvent.delete,
      query: query,
      onMessage: onMessage,
    );
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

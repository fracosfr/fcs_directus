# WebSocket (Temps réel)

Ce guide explique comment recevoir des mises à jour en temps réel et exécuter des opérations CRUD via le WebSocket Directus (`/websocket`).

> Prérequis serveur : `WEBSOCKETS_ENABLED=true` (et `WEBSOCKETS_REST_ENABLED=true` pour la souscription aux items). Depuis Directus 12.1, l'origine de la connexion est contrôlée par `CORS_ORIGIN`.

## Connexion

Le client WebSocket est fourni par `DirectusClient` et réutilise le token d'accès courant :

```dart
final client = DirectusClient(DirectusConfig(baseUrl: 'https://directus.example.com'));
await client.auth.login(email: 'user@example.com', password: 'secret');

final ws = client.websocket;      // créé à la demande avec le token courant
await ws.connect();               // ouvre wss://directus.example.com/websocket et s'authentifie
print(ws.isConnected);            // true

// ...
await ws.disconnect();
await ws.dispose();               // libère le flux de messages
```

Il peut aussi être instancié directement :

```dart
final ws = DirectusWebSocketClient(config, accessToken: 'token');
```

Le client répond automatiquement aux `ping` du serveur par un `pong`.

## Protocole

Les messages Directus sont **à plat** : les champs sont au même niveau que `type`.

```json
{"type": "auth", "access_token": "..."}
{"type": "subscribe", "collection": "articles", "query": {"fields": ["*"]}, "uid": "sub_0"}
{"type": "subscription", "event": "create", "data": [{"id": 1, "title": "..."}], "uid": "sub_0"}
```

La classe `DirectusWebSocketMessage` gère ce format :

| Membre | Description |
|--------|-------------|
| `type` | `auth`, `subscription`, `items`, `ping`, ... |
| `event` | `DirectusItemEvent.create / update / delete` (null pour `init`) |
| `uid` | Identifiant de la souscription / requête |
| `data` | Valeur brute de `data` (liste pour une souscription) |
| `items` | `List<Map<String, dynamic>>` : items reçus (`create`, `update`, `init`) |
| `ids` | Clés primaires reçues pour un `delete` |
| `isSubscriptionEvent` | `type == 'subscription'` |
| `isInit` | Premier message d'une souscription |
| `status`, `isError`, `error` | Statut d'une réponse (`ok` / `error`) |
| `raw` | Message JSON complet |

## S'abonner à une collection

```dart
final uid = await ws.subscribe(
  collection: 'articles',
  onMessage: (message) {
    if (!message.isSubscriptionEvent || message.isInit) return;

    switch (message.event) {
      case DirectusItemEvent.create:
        for (final item in message.items) {
          print('Créé : ${item['id']}');
        }
      case DirectusItemEvent.update:
        for (final item in message.items) {
          print('Modifié : ${item['id']}');
        }
      case DirectusItemEvent.delete:
        print('Supprimés : ${message.ids}');
      case null:
        break;
    }
  },
);
```

`subscribe` retourne l'`uid` de la souscription. Seuls les messages portant cet `uid` sont transmis à `onMessage`.

### Options

| Paramètre | Description |
|-----------|-------------|
| `event` | Ne recevoir qu'un type d'événement (`DirectusItemEvent.create`, ...) |
| `query` | `QueryParameters` ou `Map` : `fields`, `filter`... |
| `item` | Ne suivre qu'un item (clé primaire) |

```dart
await ws.subscribe(
  collection: 'articles',
  event: DirectusItemEvent.update,
  item: 15,
  query: QueryParameters(
    fields: ['id', 'title', 'status', 'author.first_name'],
    filter: Filter.field('status').equals('published'),
  ),
  onMessage: (message) => print(message.items),
);
```

Raccourcis par événement : `subscribeToCreate`, `subscribeToUpdate`, `subscribeToDelete` (leur `query` est une `Map`).

### Collections système

Helpers disponibles : `subscribeToUsers`, `subscribeToFiles`, `subscribeToFolders`, `subscribeToActivity`, `subscribeToNotifications`, `subscribeToComments`, `subscribeToRevisions`, `subscribeToShares`, `subscribeToVersions`, `subscribeToTranslations`, `subscribeToPermissions`, `subscribeToPresets`, `subscribeToRoles`, `subscribeToPolicies`, `subscribeToDashboards`, `subscribeToPanels`, `subscribeToFlows`, `subscribeToOperations`.

```dart
await ws.subscribeToNotifications(
  onMessage: (message) {
    for (final data in message.items) {
      final notification = DirectusNotification(data);
      print(notification.subject.value);
    }
  },
);
```

## Se désabonner

```dart
await ws.unsubscribe(uid);
```

## Opérations CRUD via WebSocket

`items()` envoie un message `items` et attend la réponse portant le même `uid` :

```dart
final created = await ws.items(
  collection: 'articles',
  action: 'create',
  data: {'title': 'Créé en temps réel'},
);
print(created.items.first['id']);

final read = await ws.items(
  collection: 'articles',
  action: 'read',
  query: {'filter': {'status': {'_eq': 'published'}}, 'limit': 10},
);

await ws.items(collection: 'articles', action: 'update', id: 1, data: {'title': 'Modifié'});
await ws.items(collection: 'articles', action: 'delete', ids: [1, 2]);
```

Une réponse `status: error` lève une `Exception` contenant l'erreur du serveur. Le délai d'attente par défaut est de 30 s (paramètre `timeout`).

## Flux brut des messages

Tous les messages reçus sont diffusés sur `ws.messages` (stream broadcast) :

```dart
ws.messages.listen((message) {
  if (message.type == 'auth' && message.isError) {
    // ex: TOKEN_EXPIRED → se reconnecter avec un nouveau token
  }
});
```

## Exemple : service de chat

```dart
class ChatService {
  ChatService(this._client);

  final DirectusClient _client;
  String? _uid;

  void Function(Map<String, dynamic>)? onNewMessage;
  void Function(List<Object>)? onMessagesDeleted;

  Future<void> start() async {
    final ws = _client.websocket;
    await ws.connect();
    _uid = await ws.subscribe(
      collection: 'messages',
      query: QueryParameters(fields: ['id', 'content', 'author.first_name']),
      onMessage: (message) {
        if (message.event == DirectusItemEvent.create) {
          message.items.forEach(onNewMessage ?? (_) {});
        } else if (message.event == DirectusItemEvent.delete) {
          onMessagesDeleted?.call(message.ids);
        }
      },
    );
  }

  Future<void> stop() async {
    if (_uid != null) await _client.websocket.unsubscribe(_uid!);
    await _client.websocket.disconnect();
  }
}
```

## Limites connues

- Pas de reconnexion automatique : écouter la fin de connexion (`isConnected`) et rappeler `connect()` puis les `subscribe()`.
- Le token est transmis à la connexion ; après un refresh, reconnecter le WebSocket pour utiliser le nouveau token.
- Les abonnements aux logs serveur (`type: logs`) ne sont pas exposés.

## Bonnes pratiques

1. Se désabonner dans `dispose()` des widgets.
2. Filtrer côté serveur (`query.filter`) plutôt que côté client.
3. Limiter `fields` aux champs affichés.
4. Ignorer le message `init` si l'état initial est déjà chargé en REST.

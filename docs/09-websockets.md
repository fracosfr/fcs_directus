# WebSockets

Guide du support WebSocket pour la communication temps réel avec Directus.

## 📡 Introduction

Les WebSockets permettent de recevoir des mises à jour en temps réel lorsque des données changent dans Directus. Le client WebSocket est intégré directement dans `DirectusClient` et utilise automatiquement votre authentification.

**Cas d'usage :**
- Tableaux de bord en temps réel
- Notifications instantanées
- Collaboration en temps réel
- Synchronisation de données
- Chat et messaging

## 🔧 Configuration

### Authentification requise

Le WebSocket nécessite une authentification préalable :

```dart
import 'package:fcs_directus/fcs_directus.dart';

final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
  ),
);

// Authentification requise pour WebSocket
await directus.auth.login(
  email: 'user@example.com',
  password: 'password',
);

// Connexion WebSocket (utilise automatiquement le token)
await directus.websocket.connect();
print('Connecté: ${directus.websocket.isConnected}');
```

### Connexion automatique du token

Le client WebSocket récupère automatiquement le token d'authentification depuis le `DirectusClient`, vous n'avez donc rien à configurer manuellement.

## 📨 Abonnements (Subscriptions)

### S'abonner à une collection

```dart
// S'abonner à tous les événements sur une collection
final subscriptionId = await directus.websocket.subscribe(
  collection: 'articles',
  onMessage: (message) {
    print('Type: ${message.type}');
    print('Event: ${message.event?.name}'); // create, update, delete
    print('Data: ${message.data}');
  },
);
```

### Types d'événements

Directus envoie 3 types d'événements CRUD :

```dart
await directus.websocket.subscribe(
  collection: 'articles',
  onMessage: (message) {
    switch (message.event) {
      case DirectusItemEvent.create:
        print('✨ Nouvel article créé: ${message.data}');
        break;
      case DirectusItemEvent.update:
        print('📝 Article modifié: ${message.data}');
        break;
      case DirectusItemEvent.delete:
        print('🗑️  Article supprimé: ${message.data}');
        break;
      default:
        print('Message: ${message.type}');
    }
  },
);
```

### S'abonner à un événement spécifique

```dart
// Uniquement les créations
await directus.websocket.subscribe(
  collection: 'articles',
  event: DirectusItemEvent.create,
  onMessage: (message) {
    print('Nouvel article: ${message.data}');
  },
);

// Uniquement les modifications
await directus.websocket.subscribe(
  collection: 'articles',
  event: DirectusItemEvent.update,
  onMessage: (message) {
    print('Article modifié: ${message.data}');
  },
);

// Uniquement les suppressions
await directus.websocket.subscribe(
  collection: 'articles',
  event: DirectusItemEvent.delete,
  onMessage: (message) {
    print('Article supprimé: ${message.data}');
  },
);
```

### S'abonner avec filtre (query)

Vous pouvez filtrer les événements reçus avec des paramètres de requête :

```dart
// Seulement les articles publiés
await directus.websocket.subscribe(
  collection: 'articles',
  query: {
    'filter': {
      'status': {'_eq': 'published'},
    },
  },
  onMessage: (message) {
    print('Article publié modifié: ${message.data}');
  },
);

// Articles d'un auteur spécifique
await directus.websocket.subscribe(
  collection: 'articles',
  query: {
    'filter': {
      'author': {'_eq': 'user-id'},
    },
  },
  onMessage: (message) {
    print('Article de l\'auteur: ${message.data}');
  },
);
```

## 🎯 Helpers pour collections système

Le client fournit des méthodes raccourcies pour les collections système Directus :

### Notifications

```dart
await directus.websocket.subscribeToNotifications(
  onMessage: (message) {
    print('🔔 Nouvelle notification: ${message.data}');
  },
);
```

### Fichiers

```dart
await directus.websocket.subscribeToFiles(
  event: DirectusItemEvent.create,
  onMessage: (message) {
    print('📎 Nouveau fichier: ${message.data}');
  },
);
```

### Utilisateurs

```dart
await directus.websocket.subscribeToUsers(
  event: DirectusItemEvent.update,
  onMessage: (message) {
    print('👤 Utilisateur modifié: ${message.data}');
  },
);
```

### Activité système

```dart
await directus.websocket.subscribeToActivity(
  onMessage: (message) {
    print('📊 Activité: ${message.data}');
  },
);
```

### Autres collections système

Toutes les collections système ont un helper dédié :

- `subscribeToUsers()` - directus_users
- `subscribeToFiles()` - directus_files
- `subscribeToFolders()` - directus_folders
- `subscribeToActivity()` - directus_activity
- `subscribeToNotifications()` - directus_notifications
- `subscribeToComments()` - directus_comments
- `subscribeToRevisions()` - directus_revisions
- `subscribeToShares()` - directus_shares
- `subscribeToVersions()` - directus_versions
- `subscribeToTranslations()` - directus_translations
- `subscribeToPermissions()` - directus_permissions
- `subscribeToPresets()` - directus_presets
- `subscribeToRoles()` - directus_roles
- `subscribeToPolicies()` - directus_policies
- `subscribeToDashboards()` - directus_dashboards
- `subscribeToPanels()` - directus_panels
- `subscribeToFlows()` - directus_flows
- `subscribeToOperations()` - directus_operations

## 🔕 Se désabonner

### Désabonnement spécifique

```dart
// Garder l'ID de souscription
final subId = await directus.websocket.subscribe(
  collection: 'articles',
  onMessage: (msg) => print(msg),
);

// Se désabonner plus tard
await directus.websocket.unsubscribe(subId);
```

### Déconnexion complète

```dart
// Déconnecte le WebSocket et annule toutes les souscriptions
await directus.websocket.disconnect();
```

## 📬 Messages

### Structure d'un message

```dart
class DirectusWebSocketMessage {
  final String type;                  // Type de message
  final DirectusItemEvent? event;     // create, update, delete
  final Map<String, dynamic>? data;   // Données de l'événement
  final String? uid;                  // ID de la souscription
}
```

### Types de messages

| Type | Description |
|------|-------------|
| `subscription` | Événement de données (create/update/delete) |
| `ping` | Keepalive du serveur |
| `pong` | Réponse au ping |
| `auth` | Résultat de l'authentification |

### Gestion des messages

```dart
await directus.websocket.subscribe(
  collection: 'products',
  onMessage: (message) {
    print('Type: ${message.type}');
    print('Event: ${message.event?.name}');
    print('Data: ${message.data}');
    print('UID: ${message.uid}');
  },
);
```

### Ping/Pong automatiques

Le client gère automatiquement les ping/pong pour maintenir la connexion active. Le serveur envoie des pings périodiques et le client répond automatiquement avec un pong.

## 🎯 Exemples pratiques

### Chat en temps réel

```dart
class ChatService {
  final DirectusClient directus;
  final StreamController<ChatMessage> _messagesController = StreamController.broadcast();
  String? _subscriptionId;
  
  Stream<ChatMessage> get messages => _messagesController.stream;
  
  ChatService(this.directus);
  
  Future<void> initialize() async {
    await directus.websocket.connect();
    
    _subscriptionId = await directus.websocket.subscribe(
      collection: 'messages',
      event: DirectusItemEvent.create,
      onMessage: (wsMessage) {
        final message = ChatMessage.fromJson(wsMessage.data!);
        _messagesController.add(message);
      },
    );
  }
  
  Future<void> sendMessage(String content, String userId) async {
    await directus.items('messages').createOne({
      'content': content,
      'user_id': userId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> dispose() async {
    if (_subscriptionId != null) {
      await directus.websocket.unsubscribe(_subscriptionId!);
    }
    await _messagesController.close();
  }
}

class ChatMessage {
  final String id;
  final String content;
  final String userId;
  final DateTime timestamp;
  
  ChatMessage({
    required this.id,
    required this.content,
    required this.userId,
    required this.timestamp,
  });
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      userId: json['user_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
```

### Notifications en temps réel

```dart
class NotificationService {
  final DirectusClient directus;
  String? _subscriptionId;
  
  Future<void> listenToNotifications(String userId) async {
    await directus.websocket.connect();
    
    _subscriptionId = await directus.websocket.subscribeToNotifications(
      query: {
        'filter': {
          'recipient': {'_eq': userId},
          'read': {'_eq': false},
        },
      },
      onMessage: (message) {
        if (message.event == DirectusItemEvent.create) {
          _showNotification(message.data!);
        }
      },
    );
  }
  
  void _showNotification(Map<String, dynamic> data) {
    // Afficher la notification dans l'UI
    print('🔔 ${data['title']}: ${data['message']}');
  }
  
  Future<void> stop() async {
    if (_subscriptionId != null) {
      await directus.websocket.unsubscribe(_subscriptionId!);
    }
  }
}
```

### Dashboard en direct (Flutter)

```dart
class LiveDashboard extends StatefulWidget {
  @override
  _LiveDashboardState createState() => _LiveDashboardState();
}

class _LiveDashboardState extends State<LiveDashboard> {
  final List<Order> _orders = [];
  String? _subscriptionId;
  
  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }
  
  Future<void> _initializeWebSocket() async {
    await widget.directus.websocket.connect();
    
    // Charger les données initiales
    final response = await widget.directus.items('orders').readMany();
    setState(() {
      _orders.addAll(response.data.map((e) => Order.fromJson(e)).toList());
    });
    
    // S'abonner aux mises à jour temps réel
    _subscriptionId = await widget.directus.websocket.subscribe(
      collection: 'orders',
      onMessage: (message) {
        switch (message.event) {
          case DirectusItemEvent.create:
            setState(() {
              _orders.insert(0, Order.fromJson(message.data!));
            });
            break;
          case DirectusItemEvent.update:
            _updateOrder(message.data!);
            break;
          case DirectusItemEvent.delete:
            setState(() {
              _orders.removeWhere((o) => o.id == message.data!['id']);
            });
            break;
          default:
            break;
        }
      },
    );
  }
  
  void _updateOrder(Map<String, dynamic> data) {
    setState(() {
      final index = _orders.indexWhere((o) => o.id == data['id']);
      if (index != -1) {
        _orders[index] = Order.fromJson(data);
      }
    });
  }
  
  @override
  void dispose() {
    if (_subscriptionId != null) {
      widget.directus.websocket.unsubscribe(_subscriptionId!);
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return ListTile(
          title: Text(order.customerName),
          subtitle: Text('Total: \$${order.total}'),
          trailing: Text(order.status),
        );
      },
    );
  }
}
```

### Synchronisation de données

```dart
class DataSyncManager {
  final DirectusClient directus;
  final Map<String, String> _subscriptions = {};
  
  DataSyncManager(this.directus);
  
  /// Synchronise une collection avec un état local
  Future<void> syncCollection<T>({
    required String collection,
    required List<T> localData,
    required T Function(Map<String, dynamic>) fromJson,
    required void Function(List<T>) onUpdate,
  }) async {
    await directus.websocket.connect();
    
    final subId = await directus.websocket.subscribe(
      collection: collection,
      onMessage: (message) {
        switch (message.event) {
          case DirectusItemEvent.create:
            localData.add(fromJson(message.data!));
            break;
          case DirectusItemEvent.update:
            final id = message.data!['id'];
            final index = localData.indexWhere((item) {
              return (item as dynamic).id == id;
            });
            if (index != -1) {
              localData[index] = fromJson(message.data!);
            }
            break;
          case DirectusItemEvent.delete:
            final id = message.data!['id'];
            localData.removeWhere((item) => (item as dynamic).id == id);
            break;
          default:
            break;
        }
        onUpdate(localData);
      },
    );
    
    _subscriptions[collection] = subId;
  }
  
  /// Arrête la synchronisation d'une collection
  Future<void> stopSync(String collection) async {
    final subId = _subscriptions[collection];
    if (subId != null) {
      await directus.websocket.unsubscribe(subId);
      _subscriptions.remove(collection);
    }
  }
  
  /// Arrête toutes les synchronisations
  Future<void> stopAll() async {
    for (final subId in _subscriptions.values) {
      await directus.websocket.unsubscribe(subId);
    }
    _subscriptions.clear();
  }
}
```

## 🔐 Sécurité

### Authentification

Le WebSocket utilise automatiquement le token d'authentification du `DirectusClient`. Assurez-vous d'être authentifié avant de vous connecter :

```dart
// ❌ Mauvais - pas authentifié
await directus.websocket.connect(); // Peut échouer

// ✅ Bon - authentifié d'abord
await directus.auth.login(email: '...', password: '...');
await directus.websocket.connect();
```

### Permissions

Les événements WebSocket respectent les permissions Directus. Vous ne recevrez que les événements pour lesquels l'utilisateur a les droits de lecture.

## 🛠️ Gestion des erreurs

### Reconnexion automatique

Le client ne gère pas automatiquement la reconnexion. Vous devez implémenter votre propre logique :

```dart
Future<void> connectWithRetry({int maxRetries = 3}) async {
  for (var i = 0; i < maxRetries; i++) {
    try {
      await directus.websocket.connect();
      print('✓ Connecté');
      return;
    } catch (e) {
      print('❌ Échec de connexion (tentative ${i + 1}/$maxRetries)');
      if (i < maxRetries - 1) {
        await Future.delayed(Duration(seconds: 2 * (i + 1)));
      }
    }
  }
  throw Exception('Impossible de se connecter après $maxRetries tentatives');
}
```

### Gestion des déconnexions

```dart
// Écouter les erreurs
directus.websocket.messages.listen(
  (message) {
    print('Message: $message');
  },
  onError: (error) {
    print('Erreur WebSocket: $error');
    // Tenter une reconnexion
    _reconnect();
  },
  onDone: () {
    print('Connexion fermée');
    _reconnect();
  },
);
```

## 💡 Bonnes pratiques

### 1. Toujours nettoyer les souscriptions

```dart
// ✅ Bon
final subId = await directus.websocket.subscribe(...);
// Utiliser la souscription
await directus.websocket.unsubscribe(subId);

// ❌ Mauvais - fuite de mémoire
await directus.websocket.subscribe(...); // ID perdu
```

### 2. Combiner données initiales + temps réel

```dart
// Charger les données existantes
final initialData = await directus.items('articles').readMany();

// Puis s'abonner aux mises à jour
await directus.websocket.subscribe(
  collection: 'articles',
  onMessage: (msg) => handleUpdate(msg),
);
```

### 3. Filtrer dès la souscription

```dart
// ✅ Bon - filtrage serveur
await directus.websocket.subscribe(
  collection: 'articles',
  query: {'filter': {'status': {'_eq': 'published'}}},
  onMessage: (msg) => print(msg),
);

// ❌ Moins efficace - filtrage client
await directus.websocket.subscribe(
  collection: 'articles',
  onMessage: (msg) {
    if (msg.data?['status'] == 'published') {
      print(msg);
    }
  },
);
```

### 4. Gérer le cycle de vie

```dart
class MyService {
  String? _subId;
  
  Future<void> start() async {
    _subId = await directus.websocket.subscribe(...);
  }
  
  Future<void> stop() async {
    if (_subId != null) {
      await directus.websocket.unsubscribe(_subId!);
      _subId = null;
    }
  }
}
```

## 📊 Limitations

- **Pas de reconnexion automatique** : Vous devez implémenter votre propre logique
- **Authentification requise** : Le WebSocket nécessite un token valide
- **Pas de file d'attente** : Les messages perdus pendant une déconnexion ne sont pas récupérés
- **Permissions strictes** : Seuls les événements autorisés sont envoyés

## 🔗 Voir aussi

- [Exemple complet WebSocket](../example/example_websocket.dart)
- [Documentation Directus WebSocket](https://docs.directus.io/guides/real-time/getting-started/websockets.html)
- [API Reference - DirectusWebSocketClient](api-reference/websocket/client.md)
        orders[index] = Order.fromJson(data);
      }
    });
  }
  
  @override
  void dispose() {
    directus.websocket.disconnect();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return ListTile(
          title: Text('Commande #${order.id}'),
          subtitle: Text(order.status),
        );
      },
    );
  }
}
```

## ⚙️ Configuration avancée

### Reconnexion automatique

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    websocketConfig: WebSocketConfig(
      autoReconnect: true,
      reconnectInterval: Duration(seconds: 5),
      maxReconnectAttempts: 10,
    ),
  ),
);
```

### Gestion des événements de connexion

```dart
directus.websocket.onConnected = () {
  print('✅ WebSocket connecté');
};

directus.websocket.onDisconnected = () {
  print('❌ WebSocket déconnecté');
};

directus.websocket.onError = (error) {
  print('⚠️ Erreur WebSocket: $error');
};
```

## 💡 Bonnes pratiques

### 1. Toujours se déconnecter

```dart
@override
void dispose() {
  directus.websocket.disconnect();
  super.dispose();
}
```

### 2. Gérer les erreurs de connexion

```dart
try {
  await directus.websocket.connect();
} catch (e) {
  print('Impossible de se connecter au WebSocket: $e');
  // Fallback sur polling ou autre méthode
}
```

### 3. Utiliser des streams pour Flutter

```dart
class RealtimeService {
  final StreamController<Article> _controller = StreamController.broadcast();
  
  Stream<Article> get articles => _controller.stream;
  
  void startListening() {
    directus.websocket.subscribe(
      collection: 'articles',
      onMessage: (message) {
        if (message.event == 'create' || message.event == 'update') {
          _controller.add(Article.fromJson(message.data!));
        }
      },
    );
  }
  
  void dispose() {
    _controller.close();
  }
}
```

### 4. Filtrer les événements côté client

```dart
directus.websocket.subscribe(
  collection: 'articles',
  onMessage: (message) {
    // Ignorer les événements delete
    if (message.event == 'delete') return;
    
    // Traiter seulement create et update
    handleArticleChange(message.data!);
  },
);
```

## ⚠️ Limitations

- Authentification requise pour utiliser les WebSockets
- Le serveur Directus doit avoir les WebSockets activés
- Consommation de batterie sur mobile (utiliser avec modération)
- Limite du nombre de connexions simultanées (selon configuration serveur)

## 🔗 Prochaines étapes

- [**File Management**](10-file-management.md) - Gestion fichiers
- [**Error Handling**](11-error-handling.md) - Gestion erreurs
- [**Services**](08-services.md) - Services disponibles

## 📚 Référence API

- [WebSocketService](api-reference/services/websocket-service.md)
- [DirectusWebSocketMessage](api-reference/models/websocket-message.md)

# WebSocket (Temps réel)

Ce guide explique comment utiliser les WebSockets pour recevoir des mises à jour en temps réel.

## Introduction

Les WebSockets permettent de s'abonner aux changements sur les collections Directus :
- Création d'items
- Modification d'items
- Suppression d'items

## Configuration

### Créer le client WebSocket

```dart
import 'package:fcs_directus/fcs_directus.dart';

final wsClient = DirectusWebSocketClient(
  config,                    // DirectusConfig
  accessToken: 'your-token', // Token d'authentification
);
```

### Connexion

```dart
await wsClient.connect();

// Vérifier l'état
print(wsClient.isConnected);  // true
```

### Déconnexion

```dart
await wsClient.disconnect();

// Libérer les ressources
await wsClient.dispose();
```

## S'abonner aux collections

### Abonnement basique

```dart
final uid = await wsClient.subscribe(
  collection: 'articles',
  onMessage: (message) {
    print('Événement: ${message.event}');
    print('Données: ${message.data}');
  },
);

// uid est un identifiant unique pour gérer l'abonnement
```

### Événements disponibles

```dart
await wsClient.subscribe(
  collection: 'articles',
  onMessage: (message) {
    switch (message.event) {
      case DirectusItemEvent.create:
        print('Nouvel article créé: ${message.data['id']}');
        break;
      case DirectusItemEvent.update:
        print('Article modifié: ${message.data['id']}');
        break;
      case DirectusItemEvent.delete:
        print('Article supprimé: ${message.data}');
        break;
    }
  },
);
```

### Abonnement à un événement spécifique

```dart
// Seulement les créations
await wsClient.subscribeToCreate(
  collection: 'notifications',
  onMessage: (message) {
    showNotification(message.data);
  },
);

// Seulement les mises à jour
await wsClient.subscribeToUpdate(
  collection: 'tasks',
  onMessage: (message) {
    updateTask(message.data);
  },
);

// Seulement les suppressions
await wsClient.subscribeToDelete(
  collection: 'items',
  onMessage: (message) {
    removeItem(message.data);
  },
);
```

### Avec filtre

```dart
final uid = await wsClient.subscribe(
  collection: 'articles',
  query: QueryParameters(
    filter: Filter.field('status').equals('published'),
  ),
  onMessage: (message) {
    // Reçoit uniquement les événements sur les articles publiés
  },
);
```

### Avec sélection de champs

```dart
final uid = await wsClient.subscribe(
  collection: 'articles',
  query: QueryParameters(
    fields: ['id', 'title', 'status', 'author.name'],
  ),
  onMessage: (message) {
    // message.data contient uniquement les champs demandés
  },
);
```

## Se désabonner

```dart
// Désabonner un abonnement spécifique
await wsClient.unsubscribe(uid);

// Désabonner tous les abonnements
await wsClient.unsubscribeAll();
```

## Collections système

Des helpers sont fournis pour les collections système Directus :

```dart
// Utilisateurs
await wsClient.subscribeToUsers(
  onMessage: (message) {
    print('Changement utilisateur: ${message.event}');
  },
);

// Fichiers
await wsClient.subscribeToFiles(
  onMessage: (message) {
    print('Fichier ${message.event}: ${message.data['filename']}');
  },
);

// Notifications
await wsClient.subscribeToNotifications(
  onMessage: (message) {
    showLocalNotification(message.data);
  },
);

// Dossiers
await wsClient.subscribeToFolders(onMessage: handleFolderChange);

// Activité
await wsClient.subscribeToActivity(onMessage: handleActivity);

// Rôles
await wsClient.subscribeToRoles(onMessage: handleRoleChange);
```

## Gestion des erreurs

### Callback d'erreur

```dart
await wsClient.subscribe(
  collection: 'articles',
  onMessage: (message) {
    // Handle message
  },
  onError: (error) {
    print('Erreur WebSocket: $error');
  },
);
```

### Reconnexion automatique

Le client gère automatiquement les reconnexions. Vous pouvez écouter les changements d'état :

```dart
wsClient.connectionState.listen((state) {
  switch (state) {
    case WebSocketState.connected:
      print('Connecté');
      break;
    case WebSocketState.disconnected:
      print('Déconnecté');
      break;
    case WebSocketState.reconnecting:
      print('Reconnexion en cours...');
      break;
  }
});
```

## Exemple complet : Chat en temps réel

```dart
class ChatService {
  final DirectusClient _client;
  DirectusWebSocketClient? _wsClient;
  String? _subscriptionUid;
  
  ChatService(this._client);
  
  Future<void> connect() async {
    final token = _client.auth.accessToken;
    if (token == null) throw Exception('Non authentifié');
    
    _wsClient = DirectusWebSocketClient(
      _client.config,
      accessToken: token,
    );
    
    await _wsClient!.connect();
    
    _subscriptionUid = await _wsClient!.subscribe(
      collection: 'messages',
      query: QueryParameters(
        fields: ['id', 'content', 'author.first_name', 'date_created'],
        sort: ['-date_created'],
      ),
      onMessage: _handleMessage,
      onError: (error) => print('WebSocket error: $error'),
    );
  }
  
  void _handleMessage(DirectusWebSocketMessage message) {
    switch (message.event) {
      case DirectusItemEvent.create:
        onNewMessage?.call(ChatMessage.fromJson(message.data));
        break;
      case DirectusItemEvent.update:
        onMessageUpdated?.call(ChatMessage.fromJson(message.data));
        break;
      case DirectusItemEvent.delete:
        onMessageDeleted?.call(message.data['id']);
        break;
    }
  }
  
  // Callbacks
  void Function(ChatMessage)? onNewMessage;
  void Function(ChatMessage)? onMessageUpdated;
  void Function(String)? onMessageDeleted;
  
  Future<void> disconnect() async {
    if (_subscriptionUid != null) {
      await _wsClient?.unsubscribe(_subscriptionUid!);
    }
    await _wsClient?.disconnect();
    await _wsClient?.dispose();
  }
}
```

## Exemple complet : Notifications en temps réel

```dart
class NotificationService {
  final DirectusClient _client;
  DirectusWebSocketClient? _wsClient;
  
  final _notificationsController = StreamController<Notification>.broadcast();
  Stream<Notification> get notifications => _notificationsController.stream;
  
  NotificationService(this._client);
  
  Future<void> init() async {
    _wsClient = DirectusWebSocketClient(
      _client.config,
      accessToken: _client.auth.accessToken!,
    );
    
    await _wsClient!.connect();
    
    await _wsClient!.subscribeToNotifications(
      onMessage: (message) {
        if (message.event == DirectusItemEvent.create) {
          _notificationsController.add(
            Notification.fromJson(message.data),
          );
        }
      },
    );
  }
  
  Future<void> dispose() async {
    await _wsClient?.disconnect();
    await _wsClient?.dispose();
    await _notificationsController.close();
  }
}

// Utilisation avec Flutter
class NotificationWidget extends StatelessWidget {
  final NotificationService service;
  
  const NotificationWidget({required this.service});
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Notification>(
      stream: service.notifications,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Afficher la notification
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(snapshot.data!.message)),
            );
          });
        }
        return const SizedBox.shrink();
      },
    );
  }
}
```

## Exemple : Dashboard en temps réel

```dart
class DashboardService {
  final DirectusClient _client;
  DirectusWebSocketClient? _wsClient;
  final List<String> _subscriptions = [];
  
  // Streams pour chaque métrique
  final _ordersController = StreamController<int>.broadcast();
  final _revenueController = StreamController<double>.broadcast();
  
  Stream<int> get ordersCount => _ordersController.stream;
  Stream<double> get revenue => _revenueController.stream;
  
  DashboardService(this._client);
  
  Future<void> startRealTimeUpdates() async {
    _wsClient = DirectusWebSocketClient(
      _client.config,
      accessToken: _client.auth.accessToken!,
    );
    
    await _wsClient!.connect();
    
    // Écouter les nouvelles commandes
    final ordersUid = await _wsClient!.subscribeToCreate(
      collection: 'orders',
      onMessage: (_) async {
        // Rafraîchir le compte
        final count = await _fetchOrdersCount();
        _ordersController.add(count);
        
        // Rafraîchir le revenu
        final revenue = await _fetchTotalRevenue();
        _revenueController.add(revenue);
      },
    );
    _subscriptions.add(ordersUid);
  }
  
  Future<int> _fetchOrdersCount() async {
    final response = await _client.items('orders').readMany(
      query: QueryParameters(
        aggregate: Aggregate()..count(['*']),
        filter: Filter.field('status').equals('completed'),
      ),
    );
    return int.parse(response.data.first['count']['*'].toString());
  }
  
  Future<double> _fetchTotalRevenue() async {
    final response = await _client.items('orders').readMany(
      query: QueryParameters(
        aggregate: Aggregate()..sum(['total']),
        filter: Filter.field('status').equals('completed'),
      ),
    );
    return double.parse(response.data.first['sum']['total'].toString());
  }
  
  Future<void> dispose() async {
    for (final uid in _subscriptions) {
      await _wsClient?.unsubscribe(uid);
    }
    await _wsClient?.disconnect();
    await _wsClient?.dispose();
    await _ordersController.close();
    await _revenueController.close();
  }
}
```

## Bonnes pratiques

### 1. Gérer le cycle de vie

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  DirectusWebSocketClient? _wsClient;
  
  @override
  void initState() {
    super.initState();
    _initWebSocket();
  }
  
  @override
  void dispose() {
    _wsClient?.disconnect();
    _wsClient?.dispose();
    super.dispose();
  }
  
  // ...
}
```

### 2. Réabonner après reconnexion

```dart
wsClient.connectionState.listen((state) {
  if (state == WebSocketState.connected) {
    // Réabonner à toutes les collections
    _resubscribeAll();
  }
});
```

### 3. Limiter les abonnements

N'abonnez que les collections nécessaires pour l'écran actuel :

```dart
@override
void initState() {
  super.initState();
  // Abonner
  _subscribe();
}

@override
void dispose() {
  // Désabonner
  _unsubscribe();
  super.dispose();
}
```

### 4. Utiliser des filtres

Réduisez le bruit en filtrant les événements côté serveur :

```dart
// ❌ Reçoit tous les articles, filtre côté client
await wsClient.subscribe(
  collection: 'articles',
  onMessage: (msg) {
    if (msg.data['status'] == 'published') {
      // ...
    }
  },
);

// ✅ Filtre côté serveur
await wsClient.subscribe(
  collection: 'articles',
  query: QueryParameters(
    filter: Filter.field('status').equals('published'),
  ),
  onMessage: (msg) {
    // Reçoit uniquement les articles publiés
  },
);
```

### 5. Gérer la charge

Pour les collections très actives :

```dart
// Debounce les mises à jour UI
Timer? _debounce;

void _handleMessage(DirectusWebSocketMessage message) {
  _debounce?.cancel();
  _debounce = Timer(Duration(milliseconds: 300), () {
    setState(() {
      // Mettre à jour l'UI
    });
  });
}
```

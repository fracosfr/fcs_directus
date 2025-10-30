# WebSockets

Guide du support WebSocket pour la communication temps réel avec Directus.

## 📡 Introduction

Les WebSockets permettent de recevoir des mises à jour en temps réel lorsque des données changent dans Directus.

## 🔧 Configuration

```dart
import 'package:fcs_directus/fcs_directus.dart';

final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
  ),
);

// Authentification requise
await directus.auth.login(email: '...', password: '...');

// Connexion WebSocket
await directus.websocket.connect();
```

## 📨 Abonnements (Subscriptions)

### S'abonner à une collection

```dart
// S'abonner aux modifications d'articles
directus.websocket.subscribe(
  collection: 'articles',
  onMessage: (message) {
    print('Type: ${message.type}');
    print('Event: ${message.event}');
    print('Data: ${message.data}');
  },
);
```

### Types d'événements

```dart
directus.websocket.subscribe(
  collection: 'articles',
  onMessage: (message) {
    switch (message.event) {
      case 'create':
        print('Nouvel article créé: ${message.data}');
        break;
      case 'update':
        print('Article modifié: ${message.data}');
        break;
      case 'delete':
        print('Article supprimé: ${message.data}');
        break;
    }
  },
);
```

### S'abonner avec filtre

```dart
// Seulement les articles publiés
directus.websocket.subscribe(
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
```

## 🔕 Se désabonner

```dart
// Se désabonner d'une collection
await directus.websocket.unsubscribe(collection: 'articles');

// Se désabonner de tout
await directus.websocket.unsubscribeAll();

// Déconnexion WebSocket
await directus.websocket.disconnect();
```

## 📬 Messages

### Structure d'un message

```dart
class DirectusWebSocketMessage {
  final String type;        // 'subscription', 'ping', 'pong'
  final String? event;      // 'create', 'update', 'delete'
  final Map<String, dynamic>? data;
  final String? uid;        // ID de la souscription
  
  // ...
}
```

### Gestion des messages

```dart
directus.websocket.subscribe(
  collection: 'products',
  onMessage: (message) {
    if (message.type == 'subscription') {
      // Événement de données
      handleDataEvent(message);
    } else if (message.type == 'ping') {
      // Keepalive ping
      print('Ping reçu');
    }
  },
);
```

## 🎯 Exemples pratiques

### Chat en temps réel

```dart
class ChatService {
  final DirectusClient directus;
  final StreamController<Message> _messagesController = StreamController();
  
  Stream<Message> get messages => _messagesController.stream;
  
  ChatService(this.directus);
  
  Future<void> initialize() async {
    await directus.websocket.connect();
    
    directus.websocket.subscribe(
      collection: 'messages',
      onMessage: (wsMessage) {
        if (wsMessage.event == 'create') {
          final message = Message.fromJson(wsMessage.data!);
          _messagesController.add(message);
        }
      },
    );
  }
  
  Future<void> sendMessage(String content) async {
    await directus.items('messages').createOne(item: {
      'content': content,
      'user': directus.auth.userId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  void dispose() {
    directus.websocket.unsubscribe(collection: 'messages');
    _messagesController.close();
  }
}
```

### Notifications en temps réel

```dart
class NotificationService {
  final DirectusClient directus;
  
  Future<void> listenToNotifications(String userId) async {
    await directus.websocket.connect();
    
    directus.websocket.subscribe(
      collection: 'notifications',
      query: {
        'filter': {
          'recipient': {'_eq': userId},
          'read': {'_eq': false},
        },
      },
      onMessage: (message) {
        if (message.event == 'create') {
          showNotification(message.data!);
        }
      },
    );
  }
  
  void showNotification(Map<String, dynamic> data) {
    // Afficher la notification dans l'UI
    print('Nouvelle notification: ${data['title']}');
  }
}
```

### Dashboard en direct

```dart
class LiveDashboard extends StatefulWidget {
  @override
  _LiveDashboardState createState() => _LiveDashboardState();
}

class _LiveDashboardState extends State<LiveDashboard> {
  List<Order> orders = [];
  
  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }
  
  Future<void> _initializeWebSocket() async {
    await directus.websocket.connect();
    
    // S'abonner aux nouvelles commandes
    directus.websocket.subscribe(
      collection: 'orders',
      onMessage: (message) {
        if (message.event == 'create') {
          setState(() {
            orders.insert(0, Order.fromJson(message.data!));
          });
        } else if (message.event == 'update') {
          _updateOrder(message.data!);
        }
      },
    );
  }
  
  void _updateOrder(Map<String, dynamic> data) {
    setState(() {
      final index = orders.indexWhere((o) => o.id == data['id']);
      if (index != -1) {
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

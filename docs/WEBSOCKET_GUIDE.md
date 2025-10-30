# Guide WebSocket Directus

## Vue d'ensemble

Le `DirectusWebSocketClient` permet de recevoir des mises à jour en temps réel depuis Directus via WebSocket. Il supporte tous les événements CRUD (Create, Read, Update, Delete) sur toutes les collections, incluant les collections système et personnalisées.

---

## Collections supportées

### Collections système Directus

Toutes les collections système Directus supportent les WebSockets :

| Collection | Méthode helper | Description |
|------------|----------------|-------------|
| `directus_users` | `subscribeToUsers()` | Utilisateurs |
| `directus_files` | `subscribeToFiles()` | Fichiers |
| `directus_folders` | `subscribeToFolders()` | Dossiers |
| `directus_activity` | `subscribeToActivity()` | Activité |
| `directus_notifications` | `subscribeToNotifications()` | Notifications |
| `directus_comments` | `subscribeToComments()` | Commentaires |
| `directus_revisions` | `subscribeToRevisions()` | Révisions |
| `directus_shares` | `subscribeToShares()` | Partages |
| `directus_versions` | `subscribeToVersions()` | Versions |
| `directus_translations` | `subscribeToTranslations()` | Traductions |
| `directus_permissions` | `subscribeToPermissions()` | Permissions |
| `directus_presets` | `subscribeToPresets()` | Préférences |
| `directus_roles` | `subscribeToRoles()` | Rôles |
| `directus_policies` | `subscribeToPolicies()` | Politiques |
| `directus_dashboards` | `subscribeToDashboards()` | Dashboards |
| `directus_panels` | `subscribeToPanels()` | Panneaux |
| `directus_flows` | `subscribeToFlows()` | Flows |
| `directus_operations` | `subscribeToOperations()` | Opérations |

### Collections personnalisées

Toutes vos collections personnalisées supportent également les WebSockets via la méthode générique `subscribe()`.

---

## Installation et configuration

### 1. Configuration de base

```dart
import 'package:fcs_directus/fcs_directus.dart';

final config = DirectusConfig(
  baseUrl: 'https://your-directus-instance.com',
  enableLogging: true, // Pour debug
);

final client = DirectusClient(config);
```

### 2. Authentification

```dart
// Authentification pour obtenir un access token
final authResponse = await client.auth.login(
  email: 'user@example.com',
  password: 'password',
);

// Créer le client WebSocket avec le token
final wsClient = DirectusWebSocketClient(
  config,
  accessToken: authResponse.accessToken,
);
```

### 3. Connexion

```dart
await wsClient.connect();
print('Connecté au WebSocket Directus');
```

---

## Utilisation

### Souscription basique à une collection

```dart
final subscriptionId = await wsClient.subscribe(
  collection: 'articles',
  onMessage: (message) {
    print('Type: ${message.type}');
    print('Event: ${message.event}');
    print('Data: ${message.data}');
  },
);
```

### Souscription à un événement spécifique

```dart
// Uniquement les créations
final createSubId = await wsClient.subscribe(
  collection: 'articles',
  event: 'create',
  onMessage: (message) {
    print('Nouvel article créé: ${message.data}');
  },
);

// Uniquement les mises à jour
final updateSubId = await wsClient.subscribe(
  collection: 'articles',
  event: 'update',
  onMessage: (message) {
    print('Article mis à jour: ${message.data}');
  },
);

// Uniquement les suppressions
final deleteSubId = await wsClient.subscribe(
  collection: 'articles',
  event: 'delete',
  onMessage: (message) {
    print('Article supprimé: ${message.data}');
  },
);
```

### Souscription avec filtres

```dart
// Recevoir uniquement les articles publiés
final filteredSubId = await wsClient.subscribe(
  collection: 'articles',
  query: {
    'filter': {
      'status': {'_eq': 'published'}
    }
  },
  onMessage: (message) {
    print('Article publié modifié: ${message.data}');
  },
);
```

---

## Méthodes helper pour collections système

### Notifications en temps réel

```dart
// S'abonner aux notifications de l'utilisateur
final notifSubId = await wsClient.subscribeToNotifications(
  onMessage: (message) {
    if (message.event == 'create') {
      // Nouvelle notification
      final notification = message.data;
      showNotification(notification['subject'], notification['message']);
    }
  },
);
```

### Activité en temps réel

```dart
// Surveiller l'activité du système
final activitySubId = await wsClient.subscribeToActivity(
  onMessage: (message) {
    print('Activité: ${message.data}');
    logActivity(message.data);
  },
);
```

### Fichiers en temps réel

```dart
// Détecter les nouveaux uploads
final filesSubId = await wsClient.subscribeToFiles(
  event: 'create',
  onMessage: (message) {
    print('Nouveau fichier uploadé: ${message.data['filename_download']}');
  },
);
```

### Commentaires en temps réel

```dart
// Recevoir les nouveaux commentaires
final commentsSubId = await wsClient.subscribeToComments(
  onMessage: (message) {
    if (message.event == 'create') {
      final comment = message.data;
      displayComment(comment);
    }
  },
);
```

### Utilisateurs en temps réel

```dart
// Surveiller les connexions/créations d'utilisateurs
final usersSubId = await wsClient.subscribeToUsers(
  onMessage: (message) {
    if (message.event == 'create') {
      print('Nouvel utilisateur: ${message.data['email']}');
    }
  },
);
```

### Versions et révisions

```dart
// Surveiller les nouvelles versions (brouillons)
final versionsSubId = await wsClient.subscribeToVersions(
  query: {
    'filter': {
      'collection': {'_eq': 'articles'}
    }
  },
  onMessage: (message) {
    print('Nouvelle version créée: ${message.data['name']}');
  },
);

// Surveiller les révisions (historique)
final revisionsSubId = await wsClient.subscribeToRevisions(
  onMessage: (message) {
    print('Révision: ${message.data}');
  },
);
```

### Partages

```dart
// Détecter les nouveaux partages
final sharesSubId = await wsClient.subscribeToShares(
  event: 'create',
  onMessage: (message) {
    print('Nouveau partage créé: ${message.data}');
  },
);
```

### Permissions et sécurité

```dart
// Surveiller les changements de permissions
final permsSubId = await wsClient.subscribeToPermissions(
  onMessage: (message) {
    print('Permissions modifiées: ${message.data}');
    // Recharger les permissions de l'utilisateur
    refreshUserPermissions();
  },
);

// Surveiller les rôles
final rolesSubId = await wsClient.subscribeToRoles(
  onMessage: (message) {
    print('Rôle modifié: ${message.data}');
  },
);
```

### Dashboards et analytics

```dart
// Surveiller les dashboards
final dashboardsSubId = await wsClient.subscribeToDashboards(
  onMessage: (message) {
    print('Dashboard modifié');
    refreshDashboard();
  },
);

// Surveiller les panneaux
final panelsSubId = await wsClient.subscribeToPanels(
  onMessage: (message) {
    print('Panneau modifié');
  },
);
```

### Flows et automatisation

```dart
// Surveiller les flows
final flowsSubId = await wsClient.subscribeToFlows(
  onMessage: (message) {
    print('Flow modifié: ${message.data}');
  },
);

// Surveiller les opérations
final opsSubId = await wsClient.subscribeToOperations(
  onMessage: (message) {
    print('Opération modifiée: ${message.data}');
  },
);
```

---

## Méthodes helper pour événements

### Écouter uniquement les créations

```dart
final createSubId = await wsClient.subscribeToCreate(
  collection: 'products',
  onMessage: (message) {
    print('Nouveau produit: ${message.data}');
    addProductToList(message.data);
  },
);
```

### Écouter uniquement les mises à jour

```dart
final updateSubId = await wsClient.subscribeToUpdate(
  collection: 'products',
  onMessage: (message) {
    print('Produit mis à jour: ${message.data}');
    updateProductInList(message.data);
  },
);
```

### Écouter uniquement les suppressions

```dart
final deleteSubId = await wsClient.subscribeToDelete(
  collection: 'products',
  onMessage: (message) {
    print('Produit supprimé: ${message.data}');
    removeProductFromList(message.data['id']);
  },
);
```

---

## Désinscription

```dart
// Se désabonner d'une souscription spécifique
await wsClient.unsubscribe(subscriptionId);

// Se désabonner de toutes les souscriptions et fermer la connexion
await wsClient.disconnect();
```

---

## Structure des messages

### Message reçu

```dart
class DirectusWebSocketMessage {
  final String type;           // Type de message ('subscription', 'ping', etc.)
  final Map<String, dynamic>? data;  // Données de l'événement
  final String? uid;           // UID de la souscription
  final String? event;         // Type d'événement ('create', 'update', 'delete')
}
```

### Exemple de message

```json
{
  "type": "subscription",
  "uid": "sub_1",
  "event": "create",
  "data": {
    "id": "123",
    "title": "Nouvel article",
    "status": "published",
    "date_created": "2025-10-30T12:00:00Z"
  }
}
```

---

## Patterns d'utilisation avancés

### 1. Chat en temps réel

```dart
class ChatService {
  final DirectusWebSocketClient wsClient;
  String? _subscriptionId;

  ChatService(this.wsClient);

  Future<void> startListening(String roomId) async {
    _subscriptionId = await wsClient.subscribe(
      collection: 'messages',
      query: {
        'filter': {
          'room_id': {'_eq': roomId}
        }
      },
      onMessage: (message) {
        if (message.event == 'create') {
          onNewMessage(message.data!);
        }
      },
    );
  }

  void onNewMessage(Map<String, dynamic> messageData) {
    // Afficher le message dans l'interface
    print('${messageData['user']}: ${messageData['text']}');
  }

  Future<void> stopListening() async {
    if (_subscriptionId != null) {
      await wsClient.unsubscribe(_subscriptionId!);
    }
  }
}
```

### 2. Notifications push en temps réel

```dart
class NotificationManager {
  final DirectusWebSocketClient wsClient;
  final String userId;

  NotificationManager(this.wsClient, this.userId);

  Future<void> initialize() async {
    await wsClient.subscribeToNotifications(
      query: {
        'filter': {
          'recipient': {'_eq': userId},
          'status': {'_eq': 'inbox'}
        }
      },
      onMessage: (message) {
        if (message.event == 'create') {
          showPushNotification(message.data!);
        }
      },
    );
  }

  void showPushNotification(Map<String, dynamic> notification) {
    // Afficher une notification système
    print('🔔 ${notification['subject']}');
  }
}
```

### 3. Dashboard avec données live

```dart
class LiveDashboard {
  final DirectusWebSocketClient wsClient;
  final List<String> _subscriptionIds = [];

  Future<void> initialize() async {
    // Surveiller les nouvelles commandes
    final ordersSubId = await wsClient.subscribeToCreate(
      collection: 'orders',
      onMessage: (msg) => updateOrdersCount(),
    );
    _subscriptionIds.add(ordersSubId);

    // Surveiller les nouveaux utilisateurs
    final usersSubId = await wsClient.subscribeToCreate(
      collection: 'directus_users',
      onMessage: (msg) => updateUsersCount(),
    );
    _subscriptionIds.add(usersSubId);

    // Surveiller l'activité
    final activitySubId = await wsClient.subscribeToActivity(
      onMessage: (msg) => updateActivityFeed(msg.data),
    );
    _subscriptionIds.add(activitySubId);
  }

  void updateOrdersCount() {
    // Mettre à jour le compteur
  }

  void updateUsersCount() {
    // Mettre à jour le compteur
  }

  void updateActivityFeed(Map<String, dynamic>? activity) {
    // Ajouter à la liste d'activité
  }

  Future<void> dispose() async {
    for (final id in _subscriptionIds) {
      await wsClient.unsubscribe(id);
    }
  }
}
```

### 4. Synchronisation bidirectionnelle

```dart
class SyncManager {
  final DirectusClient client;
  final DirectusWebSocketClient wsClient;
  
  Future<void> setupSync(String collection) async {
    // Recevoir les modifications depuis le serveur
    await wsClient.subscribe(
      collection: collection,
      onMessage: (message) {
        if (message.event == 'update') {
          updateLocalData(message.data!);
        } else if (message.event == 'delete') {
          deleteLocalData(message.data!['id']);
        }
      },
    );
  }

  void updateLocalData(Map<String, dynamic> data) {
    // Mettre à jour le cache local / BDD locale
    print('Sync: ${data['id']} updated');
  }

  void deleteLocalData(String id) {
    // Supprimer du cache local
    print('Sync: $id deleted');
  }
}
```

---

## Gestion des erreurs

```dart
try {
  await wsClient.connect();
  
  final subId = await wsClient.subscribe(
    collection: 'articles',
    onMessage: (message) {
      print(message.data);
    },
  );
} catch (e) {
  if (e is WebSocketException) {
    print('Erreur WebSocket: $e');
    // Réessayer la connexion
  } else {
    print('Erreur: $e');
  }
}
```

---

## Bonnes pratiques

### 1. Toujours authentifier avant de se connecter

```dart
// ✅ Bon
final auth = await client.auth.login(email: '...', password: '...');
final wsClient = DirectusWebSocketClient(config, accessToken: auth.accessToken);
await wsClient.connect();

// ❌ Mauvais - Sans authentification, vous ne recevrez que les données publiques
final wsClient = DirectusWebSocketClient(config);
await wsClient.connect();
```

### 2. Gérer la désinscription

```dart
// ✅ Bon - Toujours se désabonner pour libérer les ressources
final subId = await wsClient.subscribe(...);
// ... utilisation ...
await wsClient.unsubscribe(subId);

// ❌ Mauvais - Laisser les souscriptions actives
final subId = await wsClient.subscribe(...);
// Oubli de se désabonner
```

### 3. Utiliser les helpers pour les collections système

```dart
// ✅ Bon - Méthode helper spécifique
await wsClient.subscribeToNotifications(onMessage: (msg) => ...);

// ⚠️ Moins lisible - Méthode générique
await wsClient.subscribe(
  collection: 'directus_notifications',
  onMessage: (msg) => ...,
);
```

### 4. Filtrer côté serveur

```dart
// ✅ Bon - Filtrer au niveau du serveur
await wsClient.subscribe(
  collection: 'articles',
  query: {
    'filter': {'status': {'_eq': 'published'}}
  },
  onMessage: (msg) => print(msg),
);

// ❌ Mauvais - Recevoir tout et filtrer côté client
await wsClient.subscribe(
  collection: 'articles',
  onMessage: (msg) {
    if (msg.data['status'] == 'published') {
      print(msg);
    }
  },
);
```

### 5. Gérer la reconnexion

```dart
class WebSocketManager {
  final DirectusWebSocketClient wsClient;
  bool _shouldReconnect = true;

  Future<void> connectWithRetry() async {
    while (_shouldReconnect) {
      try {
        await wsClient.connect();
        print('Connecté');
        break;
      } catch (e) {
        print('Échec de connexion, réessai dans 5s...');
        await Future.delayed(Duration(seconds: 5));
      }
    }
  }

  void stopReconnecting() {
    _shouldReconnect = false;
  }
}
```

---

## Limitations et considérations

### 1. Performance

- Les WebSockets consomment une connexion persistante
- Limitez le nombre de souscriptions actives simultanées
- Utilisez des filtres pour limiter les données reçues

### 2. Sécurité

- Les permissions Directus s'appliquent aux WebSockets
- Un utilisateur ne reçoit que les événements pour lesquels il a les permissions
- Toujours utiliser un access token valide

### 3. Collections non supportées

Certaines collections/endpoints Directus ne supportent PAS les WebSockets :
- `/server/*` - Informations serveur
- `/schema/*` - Schéma de la BDD
- `/settings` - Paramètres globaux
- `/utils/*` - Utilitaires
- `/metrics` - Métriques

Ces endpoints sont en lecture seule ou ne changent pas fréquemment.

---

## Debugging

### Activer les logs

```dart
final config = DirectusConfig(
  baseUrl: '...',
  enableLogging: true,  // Active les logs
);
```

### Écouter tous les messages

```dart
wsClient.messages.listen((message) {
  print('Message: type=${message.type}, event=${message.event}');
  print('Data: ${message.data}');
});
```

### Ping pour vérifier la connexion

```dart
wsClient.ping();  // Envoie un ping au serveur
```

---

## Exemple complet

```dart
import 'package:fcs_directus/fcs_directus.dart';

Future<void> main() async {
  // 1. Configuration
  final config = DirectusConfig(
    baseUrl: 'https://directus.example.com',
    enableLogging: true,
  );
  
  final client = DirectusClient(config);
  
  // 2. Authentification
  final auth = await client.auth.login(
    email: 'user@example.com',
    password: 'password',
  );
  
  // 3. Créer le client WebSocket
  final wsClient = DirectusWebSocketClient(
    config,
    accessToken: auth.accessToken,
  );
  
  // 4. Se connecter
  await wsClient.connect();
  print('✅ Connecté au WebSocket');
  
  // 5. S'abonner aux notifications
  final notifSubId = await wsClient.subscribeToNotifications(
    onMessage: (message) {
      if (message.event == 'create') {
        print('🔔 Nouvelle notification: ${message.data!['subject']}');
      }
    },
  );
  
  // 6. S'abonner à une collection personnalisée
  final articlesSubId = await wsClient.subscribe(
    collection: 'articles',
    event: 'create',
    query: {
      'filter': {'status': {'_eq': 'published'}}
    },
    onMessage: (message) {
      print('📝 Nouvel article publié: ${message.data!['title']}');
    },
  );
  
  // 7. Attendre 60 secondes
  await Future.delayed(Duration(seconds: 60));
  
  // 8. Se désabonner et fermer
  await wsClient.unsubscribe(notifSubId);
  await wsClient.unsubscribe(articlesSubId);
  await wsClient.disconnect();
  
  client.dispose();
  print('✨ Terminé');
}
```

---

## Références

- [Documentation Directus WebSocket](https://docs.directus.io/guides/real-time/)
- [API Reference WebSocket](https://docs.directus.io/reference/websocket.html)
- Code source : `lib/src/websocket/directus_websocket_client.dart`
- Exemple : `example/websocket_example.dart`

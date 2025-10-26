# Architecture de fcs_directus

Ce document décrit l'architecture de la librairie fcs_directus.

## 📁 Structure du projet

```
fcs_directus/
├── lib/
│   ├── fcs_directus.dart          # Point d'entrée principal (exports)
│   └── src/
│       ├── core/                   # Composants centraux
│       │   ├── directus_client.dart       # Client principal
│       │   ├── directus_config.dart       # Configuration
│       │   └── directus_http_client.dart  # Wrapper HTTP (Dio)
│       │
│       ├── services/               # Services API
│       │   ├── auth_service.dart          # Authentification
│       │   ├── items_service.dart         # CRUD sur collections
│       │   ├── collections_service.dart   # Gestion collections
│       │   ├── users_service.dart         # Gestion utilisateurs
│       │   └── files_service.dart         # Gestion fichiers
│       │
│       ├── exceptions/             # Exceptions personnalisées
│       │   └── directus_exception.dart    # Hiérarchie d'exceptions
│       │
│       ├── websocket/              # Support WebSocket
│       │   └── directus_websocket_client.dart
│       │
│       ├── models/                 # Modèles de données (vide pour l'instant)
│       └── utils/                  # Utilitaires (vide pour l'instant)
│
├── example/                        # Exemples d'utilisation
│   ├── basic_usage.dart
│   ├── custom_model.dart
│   ├── websocket_example.dart
│   └── README.md
│
├── test/                           # Tests unitaires
│   └── fcs_directus_test.dart
│
└── openapi/                        # Spécifications OpenAPI Directus
    ├── index.yaml
    ├── components/
    └── paths/
```

## 🏗️ Composants principaux

### 1. DirectusClient (Point d'entrée)

Le `DirectusClient` est le point d'entrée principal de la librairie. Il:
- Prend une `DirectusConfig` en paramètre
- Initialise le `DirectusHttpClient`
- Expose tous les services (auth, collections, users, files)
- Fournit une méthode `items<T>()` pour accéder aux collections custom

```dart
final client = DirectusClient(config);
await client.auth.login(...);
final articles = client.items('articles');
```

### 2. DirectusHttpClient (Couche HTTP)

Wrapper autour de Dio qui:
- Gère les headers et l'authentification (Bearer token)
- Intercepte les erreurs et les convertit en exceptions Directus
- Fournit les méthodes CRUD (get, post, patch, delete)
- Stocke les tokens d'accès et de rafraîchissement
- Gère le logging

### 3. Services

Chaque service encapsule une partie de l'API Directus:

#### AuthService
- `login()` - Authentification email/password
- `loginWithToken()` - Authentification avec token statique
- `refresh()` - Rafraîchissement du token
- `logout()` - Déconnexion
- `requestPasswordReset()` - Réinitialisation mot de passe
- `resetPassword()` - Définir nouveau mot de passe

#### ItemsService<T>
Service générique pour toute collection:
- `readMany()` - Liste avec filtres, tri, pagination
- `readOne()` - Récupération par ID
- `createOne()` / `createMany()` - Création
- `updateOne()` / `updateMany()` - Mise à jour
- `deleteOne()` / `deleteMany()` - Suppression

Support des modèles personnalisés via le paramètre `fromJson`.

#### CollectionsService
- `getCollections()` - Liste des collections
- `getCollection()` - Détails d'une collection
- `createCollection()` - Créer une collection
- `updateCollection()` - Modifier une collection
- `deleteCollection()` - Supprimer une collection

#### UsersService
- `getUsers()` - Liste des utilisateurs
- `getUser()` - Détails d'un utilisateur
- `me()` - Utilisateur connecté
- `updateMe()` - Mettre à jour son profil
- `inviteUsers()` - Inviter de nouveaux utilisateurs
- `acceptInvite()` - Accepter une invitation

#### FilesService
- `uploadFile()` - Upload depuis fichier local
- `uploadFileFromBytes()` - Upload depuis bytes
- `importFile()` - Import depuis URL
- `getFileUrl()` - Générer l'URL d'un fichier
- `getThumbnailUrl()` - Générer l'URL d'un thumbnail

### 4. DirectusWebSocketClient

Client WebSocket indépendant pour les mises à jour temps réel:
- `connect()` - Connexion au serveur
- `subscribe()` - S'abonner aux événements d'une collection
- `unsubscribe()` - Se désabonner
- `disconnect()` - Fermer la connexion
- Stream de messages pour écouter les événements

### 5. Système d'exceptions

Hiérarchie d'exceptions typées pour une gestion d'erreurs précise:

```
DirectusException (base)
├── DirectusAuthException (401)
├── DirectusPermissionException (403)
├── DirectusNotFoundException (404)
├── DirectusValidationException (400)
├── DirectusNetworkException (timeout, connexion)
└── DirectusServerException (5xx)
```

## 🔄 Flux d'utilisation typique

1. **Configuration**
   ```dart
   final config = DirectusConfig(baseUrl: '...');
   final client = DirectusClient(config);
   ```

2. **Authentification**
   ```dart
   await client.auth.login(email: '...', password: '...');
   ```

3. **Opérations CRUD**
   ```dart
   final service = client.items('ma_collection');
   final items = await service.readMany();
   ```

4. **Temps réel (optionnel)**
   ```dart
   final ws = DirectusWebSocketClient(config, accessToken: token);
   await ws.connect();
   await ws.subscribe(collection: '...', onMessage: (msg) {...});
   ```

5. **Nettoyage**
   ```dart
   await ws.disconnect();
   client.dispose();
   ```

## 🎯 Patterns de conception utilisés

1. **Factory Pattern** - Configuration et création d'instances
2. **Service Layer Pattern** - Séparation des responsabilités
3. **Repository Pattern** - ItemsService comme repository générique
4. **Observer Pattern** - WebSocket avec Streams
5. **Wrapper Pattern** - DirectusHttpClient encapsule Dio
6. **Strategy Pattern** - fromJson pour personnaliser la désérialisation

## 🔮 Extensions futures possibles

1. **Cache** - Mise en cache des requêtes
2. **Offline** - Support mode hors ligne
3. **Pagination automatique** - Helper pour pagination infinie
4. **GraphQL** - Support de l'API GraphQL de Directus
5. **Services additionnels** - Roles, Permissions, Flows, etc.
6. **Retry logic** - Retry automatique des requêtes échouées
7. **Request interceptors** - Middleware personnalisable
8. **Code generation** - Génération automatique de modèles depuis le schéma

## 📚 Références

- [Documentation Directus](https://docs.directus.io/)
- [API Reference](https://docs.directus.io/reference/api/)
- [WebSocket Protocol](https://docs.directus.io/guides/real-time/)

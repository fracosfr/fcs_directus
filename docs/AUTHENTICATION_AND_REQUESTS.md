# Analyse : Authentification et Requêtes HTTP

Ce document analyse en profondeur le fonctionnement de l'authentification et des requêtes HTTP dans la librairie `fcs_directus`.

## Table des matières

1. [Architecture globale](#architecture-globale)
2. [Configuration](#configuration)
3. [Client HTTP](#client-http)
4. [Authentification](#authentification)
5. [Flux des requêtes](#flux-des-requêtes)
6. [Gestion des erreurs](#gestion-des-erreurs)
7. [Gestion du code 204 No Content](#gestion-du-code-204-no-content)

---

## Architecture globale

L'architecture du système d'authentification et de requêtes suit un pattern en couches :

```
┌─────────────────────────────────────────┐
│        DirectusClient (Façade)          │
│  - Point d'entrée unique                │
│  - Initialise tous les services         │
└──────────────┬──────────────────────────┘
               │
               ├── AuthService
               ├── ItemsService
               ├── UsersService
               └── ... (autres services)
                       │
                       ▼
         ┌─────────────────────────┐
         │  DirectusHttpClient      │
         │  - Gestion des tokens    │
         │  - Intercepteurs Dio     │
         │  - Méthodes HTTP         │
         └──────────┬───────────────┘
                    │
                    ▼
         ┌─────────────────────────┐
         │    Dio (HTTP Client)     │
         │  - Requêtes réseau       │
         └──────────────────────────┘
```

### Composants principaux

1. **DirectusClient** : Façade principale qui expose tous les services
2. **DirectusHttpClient** : Gestionnaire HTTP centralisé avec gestion des tokens
3. **AuthService** : Service dédié à l'authentification
4. **Services métiers** : Utilisent DirectusHttpClient pour effectuer les requêtes

---

## Configuration

### DirectusConfig

La configuration est définie dans `lib/src/core/directus_config.dart` :

```dart
class DirectusConfig {
  final String baseUrl;           // URL de l'instance Directus
  final Duration timeout;         // Timeout des requêtes (défaut: 30s)
  final Map<String, String>? headers; // Headers personnalisés
  final bool enableLogging;       // Active les logs
}
```

**Exemple d'utilisation :**

```dart
final config = DirectusConfig(
  baseUrl: 'https://directus.example.com',
  timeout: Duration(seconds: 45),
  enableLogging: true,
  headers: {
    'X-Custom-Header': 'value',
  },
);

final client = DirectusClient(config);
```

**Points clés :**
- Validation automatique de l'URL (doit commencer par `http://` ou `https://`)
- Timeout configurable pour s'adapter aux besoins réseau
- Headers personnalisés ajoutés à toutes les requêtes
- Logging optionnel pour le debugging

---

## Client HTTP

### DirectusHttpClient

Le `DirectusHttpClient` est le cœur du système de communication. Il encapsule Dio et gère :
- L'ajout automatique des tokens d'authentification
- Les intercepteurs de requêtes
- La gestion des erreurs
- Le traitement des réponses 204 No Content

**Fichier :** `lib/src/core/directus_http_client.dart`

### Initialisation

```dart
DirectusHttpClient(this._config)
  : _dio = Dio(
      BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: _config.timeout,
        receiveTimeout: _config.timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ..._config.headers ?? {},
        },
      ),
    ),
    _logger = Logger('DirectusHttpClient') {
  _setupInterceptors();
}
```

**Configuration Dio :**
- `baseUrl` : URL de base pour toutes les requêtes
- `connectTimeout` et `receiveTimeout` : Délais d'attente
- Headers par défaut : `Content-Type` et `Accept` en JSON
- Fusion avec les headers personnalisés du config

### Gestion des tokens

Le client stocke deux types de tokens :

```dart
String? _accessToken;      // Token d'accès (courte durée)
String? _refreshToken;     // Token de rafraîchissement (longue durée)
```

**Méthode pour définir les tokens :**

```dart
void setTokens({String? accessToken, String? refreshToken}) {
  _accessToken = accessToken;
  _refreshToken = refreshToken;
}
```

**Accesseurs publics :**

```dart
String? get accessToken => _accessToken;
String? get refreshToken => _refreshToken;
```

### Intercepteurs Dio

Les intercepteurs sont configurés dans `_setupInterceptors()` :

#### 1. Intercepteur de requête (`onRequest`)

**Rôle :** Ajouter automatiquement le token d'authentification à chaque requête

```dart
onRequest: (options, handler) {
  // Ajouter le token d'authentification si disponible
  if (_accessToken != null) {
    options.headers['Authorization'] = 'Bearer $_accessToken';
  }

  if (_config.enableLogging) {
    _logger.info('→ ${options.method} ${options.uri}');
    if (options.data != null) {
      _logger.fine('  Data: ${options.data}');
    }
  }

  return handler.next(options);
}
```

**Processus :**
1. Vérifie si un `_accessToken` existe
2. Si oui, ajoute le header `Authorization: Bearer <token>`
3. Log la requête si le logging est activé
4. Passe la requête au handler suivant

#### 2. Intercepteur de réponse (`onResponse`)

**Rôle :** Logger les réponses réussies

```dart
onResponse: (response, handler) {
  if (_config.enableLogging) {
    _logger.info(
      '← ${response.statusCode} ${response.requestOptions.uri}',
    );
  }
  return handler.next(response);
}
```

#### 3. Intercepteur d'erreur (`onError`)

**Rôle :** Convertir les erreurs Dio en exceptions Directus typées

```dart
onError: (error, handler) {
  if (_config.enableLogging) {
    _logger.severe('✗ ${error.requestOptions.uri}', error);
  }
  
  final directusError = _handleError(error);
  _logger.warning('Converted to: $directusError');
  return handler.next(error);
}
```

### Méthodes HTTP

Le client expose 4 méthodes HTTP principales : `GET`, `POST`, `PATCH`, `DELETE`.

#### Méthode GET

```dart
Future<Response<T>> get<T>(
  String path, {
  Map<String, dynamic>? queryParameters,
  Options? options,
}) async {
  try {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  } on DioException catch (e) {
    throw _handleError(e);
  }
}
```

**Utilisation :**
- Lecture de ressources
- Pas de traitement spécial du 204 (les GET ne retournent généralement pas 204)

#### Méthodes POST, PATCH, DELETE

Ces méthodes ont un traitement spécial pour le code 204 :

```dart
Future<Response<T>> post<T>(
  String path, {
  dynamic data,
  Map<String, dynamic>? queryParameters,
  Options? options,
}) async {
  try {
    final result = await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    
    // Traitement spécial pour 204 No Content
    if (result.statusCode == 204) {
      return Response<T>(
        requestOptions: result.requestOptions,
        statusCode: 204,
        data: null,
      );
    }
    
    return result;
  } on DioException catch (e) {
    throw _handleError(e);
  }
}
```

**Pourquoi ce traitement ?**
- Directus peut retourner 204 No Content sans body
- Dio peut avoir un comportement incohérent avec `response.data`
- On normalise en retournant explicitement `data: null`

---

## Authentification

### AuthService

Le service d'authentification gère toutes les opérations liées aux tokens et à la connexion.

**Fichier :** `lib/src/services/auth_service.dart`

### Modes d'authentification

Directus supporte 3 modes d'authentification :

```dart
enum AuthMode {
  json,      // Tokens retournés en JSON (défaut)
  cookie,    // Refresh token dans cookie httpOnly
  session;   // Tous les tokens dans cookies httpOnly
}
```

### Réponse d'authentification

```dart
class AuthResponse {
  final String accessToken;     // Token d'accès
  final int expiresIn;         // Durée de validité (secondes)
  final String? refreshToken;  // Token de rafraîchissement (optionnel)
}
```

### Flux de connexion (login)

#### 1. Requête de login

```dart
Future<AuthResponse> login({
  required String email,
  required String password,
  String? otp,
  AuthMode mode = AuthMode.json,
}) async {
  final response = await _httpClient.post(
    '/auth/login',
    data: {
      'email': email,
      'password': password,
      if (otp != null) 'otp': otp,
      'mode': mode.toApiValue(),
    },
  );

  final authResponse = AuthResponse.fromJson(
    response.data['data'] as Map<String, dynamic>,
  );

  // Stocker les tokens dans le client HTTP
  _httpClient.setTokens(
    accessToken: authResponse.accessToken,
    refreshToken: authResponse.refreshToken,
  );

  return authResponse;
}
```

**Processus complet :**

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ 1. login(email, password)
       ▼
┌─────────────┐
│ AuthService │
└──────┬──────┘
       │ 2. POST /auth/login {email, password, mode}
       ▼
┌──────────────────┐
│ DirectusHttpClient│
└──────┬───────────┘
       │ 3. Ajoute headers (Content-Type, etc.)
       │ 4. Pas de token Authorization (première connexion)
       ▼
┌──────────────┐
│     Dio      │
└──────┬───────┘
       │ 5. Requête HTTP POST
       ▼
┌──────────────┐
│   Directus   │
│    Server    │
└──────┬───────┘
       │ 6. Validation credentials
       │ 7. Génération tokens
       ▼
┌──────────────────┐
│ Response 200 OK  │
│ {                │
│   data: {        │
│     access_token,│
│     refresh_token│
│     expires      │
│   }              │
│ }                │
└──────┬───────────┘
       │ 8. Réponse JSON
       ▼
┌──────────────────┐
│ DirectusHttpClient│
└──────┬───────────┘
       │ 9. Intercepteur onResponse
       │ 10. Pas de conversion (succès)
       ▼
┌─────────────┐
│ AuthService │
└──────┬──────┘
       │ 11. Extraction AuthResponse
       │ 12. _httpClient.setTokens(access, refresh)
       ▼
┌──────────────────┐
│ DirectusHttpClient│
│ _accessToken = xxx│
│ _refreshToken= yyy│
└───────────────────┘
       │ 13. Retour AuthResponse
       ▼
┌─────────────┐
│   Client    │
│ Authentifié │
└─────────────┘
```

**Points clés :**
1. Le login **ne nécessite pas** de token existant
2. Les tokens sont **automatiquement stockés** dans `DirectusHttpClient`
3. Toutes les requêtes suivantes **incluront automatiquement** le token via l'intercepteur

#### 2. Connexion avec token statique

```dart
Future<void> loginWithToken(String token) async {
  _httpClient.setTokens(accessToken: token);
}
```

**Utilisation :**
- Authentification avec un token d'API permanent
- Pas de requête réseau, stockage direct du token

#### 3. Rafraîchissement du token

```dart
Future<AuthResponse> refresh({
  String? refreshToken,
  AuthMode mode = AuthMode.json,
}) async {
  final token = refreshToken ?? _httpClient.refreshToken;

  if (token == null) {
    throw Exception('Aucun refresh token disponible');
  }

  final response = await _httpClient.post(
    '/auth/refresh',
    data: {'refresh_token': token, 'mode': mode.toApiValue()},
  );

  final authResponse = AuthResponse.fromJson(
    response.data['data'] as Map<String, dynamic>,
  );

  // Mettre à jour les tokens
  _httpClient.setTokens(
    accessToken: authResponse.accessToken,
    refreshToken: authResponse.refreshToken ?? token,
  );

  return authResponse;
}
```

**Quand rafraîchir ?**
- Quand l'access token expire (durée définie par `expiresIn`)
- Sur erreur 401 (non géré automatiquement pour l'instant)

#### 4. Déconnexion

```dart
Future<void> logout({AuthMode mode = AuthMode.json}) async {
  final refreshToken = _httpClient.refreshToken;

  if (refreshToken != null) {
    try {
      await _httpClient.post(
        '/auth/logout',
        data: {'refresh_token': refreshToken, 'mode': mode.toApiValue()},
      );
    } catch (e) {
      // Ignorer les erreurs de déconnexion
    }
  }

  // Supprimer les tokens localement
  _httpClient.setTokens();
}
```

**Processus :**
1. Invalide le refresh token côté serveur
2. Supprime les tokens localement (même si la requête échoue)
3. Les requêtes suivantes n'auront plus de header `Authorization`

### Authentification OAuth

Le service supporte également OAuth :

```dart
// 1. Lister les providers disponibles
final providers = await client.auth.listOAuthProviders();

// 2. Générer l'URL OAuth
final oauthUrl = client.auth.getOAuthUrl('google', 
  redirect: 'https://myapp.com/callback');

// 3. Rediriger l'utilisateur vers oauthUrl

// 4. Après callback, finaliser l'authentification
final authResponse = await client.auth.loginWithOAuth(
  provider: 'google',
  code: 'code-from-redirect',
);
```

### Réinitialisation de mot de passe

```dart
// 1. Demander la réinitialisation
await client.auth.requestPasswordReset('user@example.com');

// 2. Utilisateur reçoit un email avec un token

// 3. Réinitialiser le mot de passe
await client.auth.resetPassword(
  token: 'token-from-email',
  password: 'new-password',
);
```

---

## Flux des requêtes

### Requête authentifiée standard

Prenons l'exemple d'une lecture d'items :

```dart
final articles = await client.items('articles').readMany();
```

**Flux détaillé :**

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ 1. client.items('articles').readMany()
       ▼
┌─────────────┐
│ItemsService │
└──────┬──────┘
       │ 2. _httpClient.get('/items/articles')
       ▼
┌──────────────────┐
│DirectusHttpClient│
└──────┬───────────┘
       │ 3. Intercepteur onRequest
       │    → Ajoute "Authorization: Bearer xxx"
       │    → Log la requête
       ▼
┌──────────────┐
│     Dio      │
└──────┬───────┘
       │ 4. HTTP GET https://directus.example.com/items/articles
       │    Headers:
       │      Authorization: Bearer xxx
       │      Content-Type: application/json
       │      Accept: application/json
       ▼
┌──────────────┐
│   Directus   │
│    Server    │
└──────┬───────┘
       │ 5. Validation du token
       │ 6. Vérification des permissions
       │ 7. Query sur la base de données
       ▼
┌──────────────────┐
│ Response 200 OK  │
│ {                │
│   data: [        │
│     {...},       │
│     {...}        │
│   ]              │
│ }                │
└──────┬───────────┘
       │ 8. Réponse JSON
       ▼
┌──────────────────┐
│DirectusHttpClient│
└──────┬───────────┘
       │ 9. Intercepteur onResponse
       │    → Log la réponse
       │ 10. Retour Response<dynamic>
       ▼
┌─────────────┐
│ItemsService │
└──────┬──────┘
       │ 11. Extraction response.data['data']
       │ 12. Conversion en List<Map>
       ▼
┌─────────────┐
│   Client    │
│ articles =  │
│ [...]       │
└─────────────┘
```

### Requête avec paramètres

```dart
final articles = await client.items('articles').readMany(
  query: QueryParameters(
    filter: Filter.eq('status', 'published'),
    fields: ['id', 'title', 'content'],
    sort: ['-created_at'],
    limit: 10,
  ),
);
```

**Transformation des paramètres :**

```dart
// QueryParameters.toQueryParameters() génère :
{
  'filter': {'status': {'_eq': 'published'}},
  'fields': 'id,title,content',
  'sort': '-created_at',
  'limit': 10
}

// Dio encode en query string :
// ?filter[status][_eq]=published&fields=id,title,content&sort=-created_at&limit=10
```

**URL finale :**
```
GET /items/articles?filter[status][_eq]=published&fields=id,title,content&sort=-created_at&limit=10
```

---

## Gestion des erreurs

### Conversion des erreurs Dio

La méthode `_handleError()` convertit les `DioException` en exceptions Directus typées.

#### Hiérarchie des exceptions

```
DirectusException (classe de base)
├── DirectusAuthException (401)
├── DirectusPermissionException (403)
├── DirectusNotFoundException (404)
├── DirectusValidationException (400)
├── DirectusServerException (5xx)
└── DirectusNetworkException (timeout, connexion)
```

#### Logique de conversion

```dart
DirectusException _handleError(DioException error) {
  final response = error.response;
  final statusCode = response?.statusCode;
  final data = response?.data;

  String message = 'Une erreur est survenue';

  // Extraction du message d'erreur
  if (data is Map<String, dynamic>) {
    message = data['message']?.toString() ?? 
              data['error']?.toString() ?? 
              message;
  }

  // Extraction du code d'erreur Directus
  String? errorCode;
  Map<String, dynamic>? extensions;

  if (data is Map<String, dynamic>) {
    if (data.containsKey('errors') &&
        data['errors'] is List &&
        (data['errors'] as List).isNotEmpty) {
      final firstError = (data['errors'] as List).first;
      if (firstError is Map<String, dynamic>) {
        extensions = firstError['extensions'] as Map<String, dynamic>?;
        errorCode = extensions?['code'] as String?;
        message = firstError['message'] as String? ?? message;
      }
    }
  }

  // Si on a un code d'erreur Directus, utiliser fromJson
  if (errorCode != null) {
    return DirectusException.fromJson({
      'message': message,
      'extensions': extensions,
    });
  }

  // Sinon, mapper selon le code HTTP
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return DirectusNetworkException(...);

    case DioExceptionType.badResponse:
      switch (statusCode) {
        case 400:
          return DirectusValidationException(...);
        case 401:
          return DirectusAuthException(...);
        case 403:
          return DirectusPermissionException(...);
        case 404:
          return DirectusNotFoundException(...);
        case >= 500:
          return DirectusServerException(...);
        default:
          return DirectusException(...);
      }

    case DioExceptionType.cancel:
      return DirectusException(message: 'Requête annulée');

    case DioExceptionType.connectionError:
      return DirectusNetworkException(...);

    default:
      return DirectusException(...);
  }
}
```

### Gestion des erreurs dans les services

Les services n'ont **pas besoin** de gérer les erreurs elles-mêmes car :
1. Les erreurs Dio sont interceptées par `DirectusHttpClient`
2. Converties en exceptions typées
3. Propagées automatiquement au client

**Exemple d'utilisation :**

```dart
try {
  final articles = await client.items('articles').readMany();
} on DirectusAuthException catch (e) {
  print('Non authentifié: ${e.message}');
  // Rediriger vers login
} on DirectusPermissionException catch (e) {
  print('Permission refusée: ${e.message}');
  // Afficher message d'erreur
} on DirectusNetworkException catch (e) {
  print('Erreur réseau: ${e.message}');
  // Réessayer plus tard
} on DirectusException catch (e) {
  print('Erreur Directus: ${e.message}');
  // Gestion générique
}
```

---

## Gestion du code 204 No Content

### Problème

Directus peut retourner **HTTP 204 No Content** (sans body) dans certaines situations :
- Création/modification d'items avec certaines configurations
- Opérations qui ne nécessitent pas de retour de données
- Endpoints spécifiques (register, logout, etc.)

**Erreur rencontrée :**
```
NoSuchMethodError: The method '[]' was called on null.
```

**Cause :**
Le code accédait à `response.data['data']` alors que `response.data` était `null`.

### Solution

#### 1. Dans DirectusHttpClient

Normalisation des réponses 204 dans les méthodes POST, PATCH, DELETE :

```dart
Future<Response<T>> post<T>(...) async {
  try {
    final result = await _dio.post<T>(...);
    
    // Normaliser les réponses 204
    if (result.statusCode == 204) {
      return Response<T>(
        requestOptions: result.requestOptions,
        statusCode: 204,
        data: null,  // Explicitement null
      );
    }
    
    return result;
  } on DioException catch (e) {
    throw _handleError(e);
  }
}
```

#### 2. Dans les services

Vérification avant d'accéder à `response.data['data']` :

```dart
Future<T?> createOne<T>(Map<String, dynamic> data) async {
  final response = await _httpClient.post(
    '/items/$collection',
    data: data,
  );

  // Vérifier si Directus a retourné 204 No Content
  if (response.data == null || !response.data.containsKey('data')) {
    return null;  // Pas de données retournées
  }

  // Traiter la réponse normalement
  final responseData = response.data['data'];
  // ...
}
```

#### 3. Changement des types de retour

Les méthodes susceptibles de recevoir 204 retournent maintenant des types **nullables** :

**Avant :**
```dart
Future<T> createOne<T>(...);
Future<List<T>> createMany<T>(...);
```

**Après :**
```dart
Future<T?> createOne<T>(...);        // Peut retourner null
Future<List<T>?> createMany<T>(...); // Peut retourner null
```

### Services affectés

Tous les services CRUD ont été mis à jour :
- `ItemsService` : `createOne()`, `updateOne()`
- `ItemActiveService` : `createOne()`, `updateOne()`
- `UsersService` : `me()`, `updateMe()`, `createUser()`, `updateUser()`, `createUsers()`, `updateUsers()`

### Documentation

Un guide complet a été créé : [`docs/204_NO_CONTENT.md`](./204_NO_CONTENT.md)

---

## Résumé

### Points clés de l'authentification

1. **Tokens gérés centralement** dans `DirectusHttpClient`
2. **Ajout automatique** du header `Authorization` via intercepteur
3. **Modes multiples** : JSON, cookie, session
4. **Support OAuth** pour authentification externe
5. **Rafraîchissement manuel** du token (pas encore automatique sur 401)

### Points clés des requêtes

1. **Encapsulation Dio** dans `DirectusHttpClient`
2. **Intercepteurs** pour logging et authentification
3. **Gestion centralisée des erreurs** avec exceptions typées
4. **Traitement spécial du 204** pour éviter les erreurs
5. **QueryParameters** typés pour construire les requêtes complexes

### Flux de données

```
Client App
    ↓
DirectusClient (façade)
    ↓
Services métiers (auth, items, users...)
    ↓
DirectusHttpClient (tokens + intercepteurs)
    ↓
Dio (requêtes HTTP)
    ↓
Directus Server
```

### Sécurité

- Les tokens ne sont **jamais exposés** directement au client
- Stockage en mémoire uniquement (pas de persistance automatique)
- Headers sécurisés automatiquement ajoutés
- Validation côté serveur à chaque requête

---

## Améliorations possibles

### 1. ✅ Rafraîchissement automatique du token (IMPLÉMENTÉ)

Le rafraîchissement automatique du token est maintenant **implémenté** dans `DirectusHttpClient` !

**Fonctionnement :**

Lorsqu'une requête reçoit une erreur `TOKEN_EXPIRED`, le client :
1. Détecte automatiquement l'erreur dans l'intercepteur `onError`
2. Tente de rafraîchir le token avec le refresh token stocké
3. Rejoue la requête originale avec le nouveau token
4. Retourne le résultat comme si rien ne s'était passé

**Implémentation :**

```dart
onError: (error, handler) async {
  final directusError = _handleError(error);
  
  // Détecter TOKEN_EXPIRED
  if (directusError is DirectusAuthException &&
      directusError.errorCode == 'TOKEN_EXPIRED' &&
      _refreshToken != null) {
    
    try {
      // Rafraîchir le token
      await _refreshAccessToken();
      
      // Rejouer la requête avec le nouveau token
      final opts = error.requestOptions;
      opts.headers['Authorization'] = 'Bearer $_accessToken';
      final response = await _dio.fetch(opts);
      
      return handler.resolve(response);
    } catch (refreshError) {
      // Le refresh a échoué, propager l'erreur originale
      return handler.next(error);
    }
  }
  
  return handler.next(error);
}
```

**Mécanismes de protection :**

1. **Éviter les requêtes multiples simultanées** : Utilisation d'un `Future` partagé
   ```dart
   Future<void>? _refreshFuture;
   
   Future<void> _refreshAccessToken() async {
     if (_refreshFuture != null) {
       return _refreshFuture!; // Attendre le refresh en cours
     }
     _refreshFuture = _performRefresh();
     // ...
   }
   ```

2. **Éviter les boucles infinies** : Tracking des requêtes en retry
   ```dart
   final Set<String> _retryingRequests = {};
   
   if (_retryingRequests.contains(requestId)) {
     // Déjà tenté, échouer
     return handler.next(error);
   }
   _retryingRequests.add(requestId);
   ```

3. **Isolation du refresh** : Le refresh n'utilise pas les intercepteurs
   ```dart
   final response = await _dio.post<Map<String, dynamic>>(
     '/auth/refresh',
     options: Options(
       headers: {...}, // Headers explicites
     ),
   );
   ```

**Avantages :**

- ✅ Transparent pour l'utilisateur
- ✅ Réduction du code boilerplate
- ✅ Gestion automatique des requêtes parallèles
- ✅ Protection contre les boucles infinies
- ✅ Thread-safe (un seul refresh même avec plusieurs requêtes)

**Exemple d'utilisation :**

```dart
try {
  // Pas besoin de gérer TOKEN_EXPIRED manuellement !
  final articles = await client.items('articles').readMany();
  print('Récupéré ${articles.data.length} articles');
} on DirectusAuthException catch (e) {
  // On arrive ici uniquement si le refresh a échoué
  if (e.errorCode == 'TOKEN_EXPIRED') {
    print('Session expirée, reconnexion nécessaire');
    // Rediriger vers login
  }
}
```

Voir [`example/example_auto_refresh.dart`](../example/example_auto_refresh.dart) pour un exemple complet.

### 2. Persistance des tokens

Ajouter un mécanisme de persistance optionnel :

```dart
abstract class TokenStorage {
  Future<void> saveTokens(String access, String? refresh);
  Future<TokenPair?> loadTokens();
  Future<void> clearTokens();
}

// Implémentation avec shared_preferences, secure_storage, etc.
```

### 3. Gestion du cycle de vie des tokens

Implémenter une vérification automatique de l'expiration :

```dart
class TokenManager {
  DateTime? _expiresAt;
  
  bool get isExpired => 
    _expiresAt != null && DateTime.now().isAfter(_expiresAt);
    
  void setExpiration(int expiresIn) {
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
  }
}
```

### 4. Support des requêtes en parallèle avec retry

Éviter de rafraîchir le token plusieurs fois si plusieurs requêtes échouent simultanément :

```dart
Future<String>? _refreshFuture;

Future<String> _ensureValidToken() async {
  if (_refreshFuture != null) {
    return _refreshFuture!;
  }
  
  if (_isTokenExpired()) {
    _refreshFuture = _refreshToken().then((token) {
      _refreshFuture = null;
      return token;
    });
    return _refreshFuture!;
  }
  
  return _accessToken!;
}
```

---

**Dernière mise à jour :** 5 novembre 2025

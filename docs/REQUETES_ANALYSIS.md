# Analyse du fonctionnement des requêtes vers Directus

## 📋 Table des matières

1. [Architecture globale](#architecture-globale)
2. [Couche HTTP - DirectusHttpClient](#couche-http---directushttpclient)
3. [Services Directus](#services-directus)
4. [Flux de requête complet](#flux-de-requête-complet)
5. [Gestion des erreurs](#gestion-des-erreurs)
6. [Authentification et tokens](#authentification-et-tokens)
7. [Paramètres de requête](#paramètres-de-requête)
8. [Exemples pratiques](#exemples-pratiques)

---

## Architecture globale

Le projet **fcs_directus** utilise une architecture en couches pour communiquer avec l'API Directus :

```
┌─────────────────────────────────────────────────────────────┐
│                    DirectusClient                           │
│  (Point d'entrée principal - Orchestrateur)                 │
└──────────────────┬──────────────────────────────────────────┘
                   │
      ┌────────────┴────────────┐
      │                         │
      ▼                         ▼
┌──────────────┐         ┌──────────────────┐
│   Services   │         │ DirectusConfig   │
│              │         │ (Configuration)  │
│ - AuthService│         └──────────────────┘
│ - ItemsService
│ - UsersService
│ - FilesService
│ - etc. (30+)
└──────┬───────┘
       │
       ▼
┌─────────────────────────────────────┐
│    DirectusHttpClient               │
│  (Couche HTTP avec Dio)             │
│                                     │
│  - Intercepteurs                    │
│  - Gestion des tokens               │
│  - Auto-refresh                     │
│  - Gestion des erreurs              │
└──────────────┬──────────────────────┘
               │
               ▼
         ┌──────────┐
         │   Dio    │
         │ (HTTP)   │
         └────┬─────┘
              │
              ▼
       ┌────────────┐
       │  Directus  │
       │   Server   │
       └────────────┘
```

---

## Couche HTTP - DirectusHttpClient

### Responsabilités

Le `DirectusHttpClient` est la **couche d'abstraction HTTP** qui encapsule **Dio** et fournit :

1. ✅ **Configuration de base** (BaseURL, timeout, headers)
2. ✅ **Gestion des tokens** (access + refresh)
3. ✅ **Auto-refresh des tokens** (quand expiré)
4. ✅ **Intercepteurs** pour logging et erreurs
5. ✅ **Conversion des erreurs** Dio → DirectusException
6. ✅ **Méthodes HTTP** typées (GET, POST, PATCH, DELETE)

### Configuration initiale

```dart
DirectusHttpClient(DirectusConfig config)
  : _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.timeout,
        receiveTimeout: config.timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...config.headers ?? {},  // Headers personnalisés
        },
      ),
    )
```

**Points clés** :
- BaseURL configurée une seule fois
- Headers par défaut : JSON
- Timeout configurable
- Support des headers personnalisés (important pour reverse proxies)

### Intercepteurs

Le client configure **3 intercepteurs Dio** :

#### 1. **onRequest** - Avant l'envoi

```dart
onRequest: (options, handler) {
  // Ajouter le token d'authentification si disponible
  if (_accessToken != null) {
    options.headers['Authorization'] = 'Bearer $_accessToken';
  }

  if (_config.enableLogging) {
    _logger.info('→ ${options.method} ${options.uri}');
  }

  return handler.next(options);
}
```

**Rôle** :
- Injecte automatiquement le header `Authorization: Bearer <token>`
- Log les requêtes sortantes (si activé)

#### 2. **onResponse** - Après réception

```dart
onResponse: (response, handler) {
  if (_config.enableLogging) {
    _logger.info('← ${response.statusCode} ${response.requestOptions.uri}');
  }
  return handler.next(response);
}
```

**Rôle** :
- Log les réponses réussies

#### 3. **onError** - Gestion des erreurs

```dart
onError: (error, handler) async {
  // 1. Convertir l'erreur Dio en DirectusException
  final directusError = _handleError(error);

  // 2. Vérifier si c'est TOKEN_EXPIRED
  if (directusError is DirectusAuthException &&
      directusError.errorCode == 'TOKEN_EXPIRED' &&
      _refreshToken != null) {
    
    // 3. Éviter les boucles infinies
    if (_retryingRequests.contains(requestId)) {
      return handler.next(error);
    }

    // 4. Tenter le refresh
    await _refreshAccessToken();

    // 5. Retry la requête avec le nouveau token
    final response = await _dio.fetch(opts);
    return handler.resolve(response);
  }

  return handler.next(error);
}
```

**Rôle CRUCIAL** :
- ✅ Détecte automatiquement `TOKEN_EXPIRED`
- ✅ Refresh le token en arrière-plan
- ✅ **Retry automatiquement** la requête originale
- ✅ Évite les boucles infinies avec `_retryingRequests`
- ✅ Transparent pour l'utilisateur (aucune intervention nécessaire)

### Auto-refresh des tokens

#### Mécanisme de refresh

```dart
Future<void> _refreshAccessToken() async {
  // Si un refresh est déjà en cours, attendre
  if (_refreshFuture != null) {
    await _refreshFuture!;
    return;
  }

  // Démarrer un nouveau refresh
  _refreshFuture = _performRefresh();

  try {
    await _refreshFuture!;
    _refreshFuture = null;
  } catch (e) {
    _refreshFuture = null;
    rethrow;
  }
}
```

**Avantages** :
- **Thread-safe** : Un seul refresh à la fois
- **Optimisation** : Requêtes parallèles partagent le même refresh
- **Robuste** : Gestion des erreurs et nettoyage

#### Refresh effectif

```dart
Future<void> _performRefresh() async {
  // Créer un Dio TEMPORAIRE sans intercepteurs
  // pour éviter une boucle infinie
  final tempDio = Dio(
    BaseOptions(
      baseUrl: _config.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ..._config.headers ?? {},  // IMPORTANT pour reverse proxies
      },
    ),
  );

  final response = await tempDio.post(
    '/auth/refresh',
    data: {'refresh_token': _refreshToken, 'mode': 'json'},
  );

  // Mettre à jour les tokens
  _accessToken = newAccessToken;
  _refreshToken = newRefreshToken;

  // Notifier l'application via callback
  if (_config.onTokenRefreshed != null) {
    await _config.onTokenRefreshed!(_accessToken!, _refreshToken);
  }
}
```

**Points critiques** :
- ⚠️ Utilise un **Dio temporaire** sans intercepteurs
- ✅ Inclut les **headers personnalisés** (fix pour reverse proxies)
- ✅ **Callback optionnel** pour persister les nouveaux tokens
- ✅ Gestion des erreurs 401/403 (token invalide)

### Méthodes HTTP

#### GET

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

#### POST

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
    
    // Gestion spéciale du 204 No Content
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

**Spécificité** : Gestion du **204 No Content** (réponse sans body)

#### PATCH & DELETE

Même principe que POST avec gestion du 204.

---

## Services Directus

### Architecture des services

Chaque service encapsule la logique métier pour un endpoint Directus spécifique :

```
AuthService       → /auth/*
ItemsService      → /items/{collection}
UsersService      → /users/*
FilesService      → /files/*
...
```

### Deux approches pour les items

#### 1. ItemsService - Approche générique

```dart
class ItemsService<T> {
  Future<DirectusResponse<dynamic>> readMany({
    QueryParameters? query,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await _httpClient.get(
      '/items/$collection',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data['data'] as List;
    final items = fromJson != null
        ? data.map((item) => fromJson(item)).toList()
        : data;

    return DirectusResponse(data: items, meta: meta);
  }
}
```

**Utilisation** :
```dart
final items = client.items('articles');
final articles = await items.readMany();
// Retourne List<Map<String, dynamic>>
```

**Avantages** :
- ✅ Simple et rapide
- ✅ Pas besoin de créer des classes
- ✅ Flexible

**Inconvénients** :
- ❌ Pas de type-safety
- ❌ Manipulation de Map

#### 2. ItemActiveService - Approche typée (Active Record)

```dart
class ItemActiveService<T extends DirectusModel> {
  Future<DirectusResponse<T>> readMany({QueryParameters? query}) async {
    final response = await _httpClient.get(
      '/items/$collection',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data['data'] as List;
    final factory = _getModelFactory();
    final items = data.map((item) => factory(item)).toList();

    return DirectusResponse(data: items, meta: meta);
  }

  Future<T?> createOne(T model) async {
    final response = await _httpClient.post(
      '/items/$collection',
      data: model.toJson(),  // Serialization automatique
    );

    final responseData = response.data!['data'];
    return factory(responseData);
  }

  Future<T?> updateOne(T model) async {
    final response = await _httpClient.patch(
      '/items/$collection/${model.id}',
      data: model.toJsonDirty(),  // Seulement les champs modifiés !
    );

    return factory(response.data!['data']);
  }
}
```

**Utilisation** :
```dart
// 1. Définir le modèle
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  late final title = stringValue('title');
  late final status = enumValue<Status>('status', Status.draft, Status.values);
}

// 2. Enregistrer la factory
DirectusModel.registerFactory<Article>((data) => Article(data));

// 3. Utiliser
final articles = client.itemsOf<Article>();
final list = await articles.readMany();
// Retourne List<Article> - Type-safe !

// 4. Modification
final article = list.data.first;
article.title.set('Nouveau titre');
article.status.set(Status.published);

await articles.updateOne(article);
// Envoie seulement {"title": "...", "status": "published"} grâce à toJsonDirty()
```

**Avantages** :
- ✅ **Type-safe**
- ✅ **Active Record pattern**
- ✅ **Dirty tracking** (optimisation automatique)
- ✅ **Property wrappers** (API intuitive)
- ✅ **Enums** support

**Inconvénients** :
- ❌ Nécessite de créer des classes
- ❌ Nécessite d'enregistrer les factories

---

## Flux de requête complet

### Exemple : Lecture d'articles avec filtre

```dart
// 1. Configuration
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://directus.example.com',
    enableLogging: true,
  ),
);

// 2. Authentification
await client.auth.login(
  email: 'user@example.com',
  password: 'password',
);
```

**Flux interne** :
```
1. AuthService.login()
   └─> DirectusHttpClient.post('/auth/login', data: {...})
       └─> Dio.post()
           └─> Interceptor onRequest (ajoute headers)
           └─> HTTP POST → Directus
           └─> Interceptor onResponse (log)
       └─> Parse response → AuthResponse
       └─> DirectusHttpClient.setTokens(access, refresh)
```

```dart
// 3. Requête avec filtre
final articles = await client.items('articles').readMany(
  query: QueryParameters(
    filter: Filter.and([
      Filter.field('status').equals('published'),
      Filter.field('author.name').contains('John'),
    ]),
    fields: ['id', 'title', 'author.name'],
    sort: ['-date_created'],
    limit: 10,
  ),
);
```

**Flux interne détaillé** :

```
1. ItemsService.readMany(query)
   │
   ├─> QueryParameters.toQueryParameters()
   │   └─> Convertit Filter en JSON
   │       {
   │         "filter": {
   │           "_and": [
   │             {"status": {"_eq": "published"}},
   │             {"author": {"name": {"_contains": "John"}}}
   │           ]
   │         },
   │         "fields": "id,title,author.name",
   │         "sort": "-date_created",
   │         "limit": 10
   │       }
   │
   ├─> DirectusHttpClient.get('/items/articles', queryParams)
   │   │
   │   ├─> Interceptor onRequest
   │   │   └─> Ajoute: Authorization: Bearer <access_token>
   │   │
   │   ├─> Dio.get('https://directus.example.com/items/articles?filter=...')
   │   │
   │   ├─> Si erreur TOKEN_EXPIRED:
   │   │   └─> Interceptor onError
   │   │       ├─> _refreshAccessToken()
   │   │       │   ├─> Créer Dio temporaire
   │   │       │   ├─> POST /auth/refresh
   │   │       │   ├─> Mettre à jour _accessToken & _refreshToken
   │   │       │   └─> Callback onTokenRefreshed (si configuré)
   │   │       │
   │   │       └─> Retry la requête originale avec nouveau token
   │   │           └─> Dio.fetch(originalRequest)
   │   │
   │   └─> Response {
   │         "data": [...],
   │         "meta": {"total_count": 42}
   │       }
   │
   └─> Parse response
       ├─> data = response.data['data'] as List
       ├─> meta = DirectusMeta.fromJson(response.data['meta'])
       └─> return DirectusResponse(data: items, meta: meta)
```

---

## Gestion des erreurs

### Conversion Dio → DirectusException

```dart
DirectusException _handleError(DioException error) {
  final response = error.response;
  final statusCode = response?.statusCode;
  final data = response?.data;

  // 1. Extraire le code d'erreur Directus
  String? errorCode;
  if (data is Map<String, dynamic> && data.containsKey('errors')) {
    final errors = data['errors'] as List;
    final firstError = errors.first as Map<String, dynamic>;
    errorCode = firstError['extensions']?['code'];
  }

  // 2. Mapper selon le code HTTP ou le code Directus
  switch (statusCode) {
    case 400:
      return DirectusValidationException(...);
    case 401:
      return DirectusAuthException(...);
    case 403:
      return DirectusPermissionException(...);
    case 404:
      return DirectusNotFoundException(...);
    case 5xx:
      return DirectusServerException(...);
    default:
      return DirectusException(...);
  }
}
```

### Hiérarchie des exceptions

```
DirectusException (base)
├─> DirectusAuthException          (401, TOKEN_EXPIRED, etc.)
├─> DirectusPermissionException    (403)
├─> DirectusNotFoundException      (404)
├─> DirectusValidationException    (400)
├─> DirectusServerException        (500+)
├─> DirectusNetworkException       (timeout, connection)
└─> DirectusRateLimitException     (429)
```

### Utilisation

```dart
try {
  final articles = await client.items('articles').readMany();
} on DirectusAuthException catch (e) {
  if (e.errorCode == 'TOKEN_EXPIRED') {
    // Normalement géré automatiquement
  } else if (e.isInvalidCredentials) {
    print('Identifiants incorrects');
  }
} on DirectusPermissionException catch (e) {
  print('Accès refusé: ${e.message}');
} on DirectusNotFoundException catch (e) {
  print('Ressource non trouvée');
} on DirectusException catch (e) {
  print('Erreur Directus: ${e.message}');
}
```

---

## Authentification et tokens

### Workflow complet

```
1. Login
   ├─> POST /auth/login
   └─> Receive { access_token, refresh_token, expires }
       └─> DirectusHttpClient.setTokens()

2. Requête normale
   ├─> Interceptor ajoute: Authorization: Bearer <access_token>
   └─> Requête réussie

3. Token expire (après X secondes)
   ├─> Requête suivante → 401 TOKEN_EXPIRED
   └─> Interceptor onError détecte
       ├─> _refreshAccessToken()
       │   ├─> POST /auth/refresh { refresh_token }
       │   └─> Receive new tokens
       │       └─> setTokens(new_access, new_refresh)
       │           └─> onTokenRefreshed callback
       │
       └─> Retry requête originale avec nouveau token
           └─> Succès transparent

4. Refresh token expire
   ├─> Refresh échoue (401/403)
   └─> clearTokens()
       └─> Utilisateur doit se reconnecter
```

### Callback onTokenRefreshed

```dart
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://directus.example.com',
    onTokenRefreshed: (accessToken, refreshToken) async {
      // Sauvegarder dans un storage persistant
      await storage.write(key: 'access_token', value: accessToken);
      if (refreshToken != null) {
        await storage.write(key: 'refresh_token', value: refreshToken);
      }
    },
  ),
);
```

**Avantages** :
- ✅ Persistance automatique des nouveaux tokens
- ✅ Survit aux redémarrages de l'app
- ✅ Aucune intervention manuelle

---

## Paramètres de requête

### QueryParameters

```dart
class QueryParameters {
  final dynamic filter;      // Filter ou Map
  final List<String>? fields;
  final List<String>? sort;
  final int? limit;
  final int? offset;
  final int? page;
  final String? search;
  final dynamic deep;        // Deep ou Map
  final dynamic aggregate;   // Aggregate ou Map
  final dynamic groupBy;     // GroupBy, List<String> ou Map

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    
    if (filter != null) {
      params['filter'] = filter is Filter
        ? (filter as Filter).toJson()
        : filter;
    }
    
    if (fields != null) {
      params['fields'] = fields!.join(',');
    }
    
    // ... conversion de tous les paramètres
    
    return params;
  }
}
```

### Filtres type-safe

```dart
// Création
final filter = Filter.and([
  Filter.field('status').equals('published'),
  Filter.field('price').between(100, 1000),
  Filter.or([
    Filter.field('category').inList(['electronics', 'computers']),
    Filter.field('featured').isTrue(),
  ]),
]);

// Conversion en JSON
filter.toJson();
// {
//   "_and": [
//     {"status": {"_eq": "published"}},
//     {"price": {"_between": [100, 1000]}},
//     {
//       "_or": [
//         {"category": {"_in": ["electronics", "computers"]}},
//         {"featured": {"_eq": true}}
//       ]
//     }
//   ]
// }
```

### Relations (Deep)

```dart
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery()
      .fields(['id', 'name', 'email'])
      .filter(Filter.field('status').equals('active')),
    'comments': DeepQuery()
      .fields(['id', 'text', 'user.name'])
      .limit(5),
  }),
);

// Génère:
// {
//   "deep": {
//     "author": {
//       "fields": ["id", "name", "email"],
//       "filter": {"status": {"_eq": "active"}}
//     },
//     "comments": {
//       "fields": ["id", "text", "user.name"],
//       "limit": 5
//     }
//   }
// }
```

---

## Exemples pratiques

### Exemple 1 : CRUD complet avec Active Record

```dart
// Définir le modèle
enum ArticleStatus { draft, review, published, archived }

class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  late final title = stringValue('title');
  late final content = stringValue('content');
  late final status = enumValue<ArticleStatus>(
    'status',
    ArticleStatus.draft,
    ArticleStatus.values,
  );
  late final viewCount = intValue('view_count');
}

// Enregistrer la factory
DirectusModel.registerFactory<Article>((data) => Article(data));

// Utiliser
final articles = client.itemsOf<Article>();

// CREATE
final newArticle = Article.empty()
  ..title.set('Mon article')
  ..content.set('Contenu...')
  ..status.set(ArticleStatus.published);

final created = await articles.createOne(newArticle);

// READ
final list = await articles.readMany(
  query: QueryParameters(
    filter: Filter.field('status').equals(ArticleStatus.published.name),
    sort: ['-date_created'],
    limit: 10,
  ),
);

// UPDATE
final article = list.data.first;
article.title.set('Titre modifié');
article.viewCount.incrementBy(1);

await articles.updateOne(article);
// Envoie seulement: {"title": "Titre modifié", "view_count": 43}

// DELETE
await articles.deleteOne(article);
```

### Exemple 2 : Requête complexe avec filtres et relations

```dart
final products = await client.items('products').readMany(
  query: QueryParameters(
    filter: Filter.and([
      Filter.field('status').equals('active'),
      Filter.field('stock').greaterThan(0),
      Filter.or([
        Filter.field('category.name').inList(['Electronics', 'Computers']),
        Filter.field('featured').isTrue(),
      ]),
      Filter.field('price').between(100, 5000),
    ]),
    fields: [
      'id',
      'name',
      'price',
      'stock',
      'category.name',
      'manufacturer.name',
    ],
    deep: Deep({
      'category': DeepQuery().fields(['id', 'name']),
      'manufacturer': DeepQuery().fields(['id', 'name', 'country']),
      'reviews': DeepQuery()
        .fields(['id', 'rating', 'comment', 'user.name'])
        .filter(Filter.field('approved').isTrue())
        .sort(['-date_created'])
        .limit(5),
    }),
    sort: ['-featured', '-date_created'],
    limit: 20,
    page: 1,
  ),
);
```

**Requête HTTP générée** :
```
GET /items/products?
  filter={"_and":[{"status":{"_eq":"active"}},{"stock":{"_gt":0}},...]}
  &fields=id,name,price,stock,category.name,manufacturer.name
  &deep={"category":{"fields":["id","name"]},...}
  &sort=-featured,-date_created
  &limit=20
  &page=1
```

### Exemple 3 : Gestion automatique du refresh

```dart
// Configuration avec callback de persistance
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://directus.example.com',
    onTokenRefreshed: (accessToken, refreshToken) async {
      await storage.write(key: 'access_token', value: accessToken);
      if (refreshToken != null) {
        await storage.write(key: 'refresh_token', value: refreshToken);
      }
      print('Tokens sauvegardés automatiquement');
    },
  ),
);

// Login initial
await client.auth.login(email: 'user@example.com', password: 'pass');

// Attendre que le token expire (ex: après 15 minutes)
await Future.delayed(Duration(minutes: 16));

// Cette requête va:
// 1. Recevoir 401 TOKEN_EXPIRED
// 2. Refresh automatiquement le token
// 3. Appeler onTokenRefreshed pour sauvegarder
// 4. Retry la requête avec le nouveau token
// 5. Retourner les données comme si de rien n'était
final articles = await client.items('articles').readMany();
// ✅ Succès transparent !
```

---

## Optimisations et bonnes pratiques

### 1. Dirty Tracking

```dart
final article = await articles.readOne('123');
article.markClean(); // Marquer comme propre après chargement

article.title.set('Nouveau titre');
// Seulement 'title' est marqué dirty

await articles.updateOne(article);
// Envoie seulement: {"title": "Nouveau titre"}
// Au lieu de tout le modèle
```

### 2. Batch Operations

```dart
// Au lieu de:
for (final article in articlesList) {
  await articles.updateOne(article);  // N requêtes HTTP
}

// Faire:
await articles.updateMany(articlesList);  // 1 seule requête HTTP
```

### 3. Sélection de champs

```dart
// Au lieu de charger tout:
final articles = await articles.readMany();

// Sélectionner seulement ce dont vous avez besoin:
final articles = await articles.readMany(
  query: QueryParameters(
    fields: ['id', 'title', 'status'],  // Moins de données transférées
  ),
);
```

### 4. Pagination

```dart
// Charger par pages de 20
for (int page = 1; page <= totalPages; page++) {
  final response = await articles.readMany(
    query: QueryParameters(
      limit: 20,
      page: page,
    ),
  );
  
  processArticles(response.data);
}
```

---

## Conclusion

Le système de requêtes de **fcs_directus** est :

✅ **Robuste** : Gestion automatique des erreurs et du refresh  
✅ **Transparent** : Auto-refresh invisible pour l'utilisateur  
✅ **Type-safe** : Filtres, modèles et enums typés  
✅ **Optimisé** : Dirty tracking, batch operations  
✅ **Flexible** : Approche générique ou Active Record  
✅ **Complet** : Support de tous les endpoints Directus  
✅ **Bien architecturé** : Séparation des responsabilités  

L'architecture en couches permet une maintenance facile et des extensions futures sans breaking changes.

# Advanced

Fonctionnalités avancées et optimisations pour fcs_directus.

## 🚀 Performance

### Batch Operations

Créer, mettre à jour ou supprimer plusieurs items en une seule requête.

```dart
// Créer plusieurs items
await directus.items('articles').createMany(items: [
  {'title': 'Article 1', 'status': 'published'},
  {'title': 'Article 2', 'status': 'published'},
  {'title': 'Article 3', 'status': 'draft'},
]);

// Mettre à jour plusieurs items par IDs
await directus.items('articles').updateMany(
  keys: ['id1', 'id2', 'id3'],
  data: {'status': 'published'},
);

// Mettre à jour plusieurs items par filtre
await directus.items('articles').updateMany(
  filter: Filter.equals('category', 'news'),
  data: {'featured': true},
);

// Mettre à jour tous les items de la collection
await directus.items('articles').updateMany(
  data: {'archived': false},
);

// Supprimer plusieurs items par IDs
await directus.items('articles').deleteMany(
  keys: ['id1', 'id2', 'id3'],
);

// Supprimer plusieurs items par filtre
await directus.items('articles').deleteMany(
  filter: Filter.equals('status', 'archived'),
);

// Supprimer tous les items de la collection
await directus.items('articles').deleteMany();
```

### Limiter les champs retournés

```dart
// ❌ Charge tous les champs (lourd)
await directus.items('articles').readMany();

// ✅ Charge uniquement les champs nécessaires
await directus.items('articles').readMany(
  query: QueryParameters(
    fields: ['id', 'title', 'status'],
  ),
);
```

### Pagination efficace

```dart
class PaginatedLoader {
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  
  Future<List<Article>> loadNextPage() async {
    if (!_hasMore) return [];
    
    final result = await directus.items('articles').readMany(
      query: QueryParameters(
        limit: _pageSize,
        page: _currentPage,
        meta: '*',
      ),
    );
    
    final items = result.data ?? [];
    final total = result.meta?.totalCount ?? 0;
    
    _hasMore = (_currentPage * _pageSize) < total;
    _currentPage++;
    
    return items.map((d) => Article(d)).toList();
  }
}
```

## 💾 Cache

### Cache en mémoire

```dart
class CachedService {
  final Map<String, dynamic> _cache = {};
  final Duration cacheDuration = Duration(minutes: 5);
  
  Future<List<Article>> getArticles({bool forceRefresh = false}) async {
    final cacheKey = 'articles';
    final cached = _cache[cacheKey];
    
    if (!forceRefresh && cached != null) {
      final cacheTime = cached['time'] as DateTime;
      if (DateTime.now().difference(cacheTime) < cacheDuration) {
        return cached['data'] as List<Article>;
      }
    }
    
    // Charger depuis API
    final result = await directus.items('articles').readMany();
    final articles = result.data?.map((d) => Article(d)).toList() ?? [];
    
    // Mettre en cache
    _cache[cacheKey] = {
      'data': articles,
      'time': DateTime.now(),
    };
    
    return articles;
  }
  
  void clearCache() => _cache.clear();
}
```

### Cache persistant avec Hive

```dart
import 'package:hive/hive.dart';

class PersistentCache {
  late Box _cacheBox;
  
  Future<void> init() async {
    _cacheBox = await Hive.openBox('directus_cache');
  }
  
  Future<List<Article>?> getCachedArticles() async {
    final cached = _cacheBox.get('articles');
    if (cached == null) return null;
    
    final cacheTime = DateTime.parse(cached['time'] as String);
    if (DateTime.now().difference(cacheTime).inMinutes > 5) {
      return null; // Cache expiré
    }
    
    return (cached['data'] as List)
        .map((d) => Article(d as Map<String, dynamic>))
        .toList();
  }
  
  Future<void> cacheArticles(List<Article> articles) async {
    await _cacheBox.put('articles', {
      'data': articles.map((a) => a.toJson()).toList(),
      'time': DateTime.now().toIso8601String(),
    });
  }
}
```

## 🔧 Configuration avancée

### Timeout personnalisé

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    timeout: Duration(seconds: 30),
  ),
);
```

### Headers personnalisés

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    headers: {
      'X-Custom-Header': 'value',
      'X-API-Key': 'api-key',
    },
  ),
);
```

### Intercepteurs HTTP

```dart
class LoggingInterceptor {
  void onRequest(RequestOptions options) {
    print('→ ${options.method} ${options.path}');
    print('  Headers: ${options.headers}');
    print('  Data: ${options.data}');
  }
  
  void onResponse(Response response) {
    print('← ${response.statusCode} ${response.requestOptions.path}');
    print('  Data: ${response.data}');
  }
  
  void onError(DioException error) {
    print('✗ ${error.requestOptions.method} ${error.requestOptions.path}');
    print('  Error: ${error.message}');
  }
}

// Utilisation avec Dio directement
final dio = directus.http.dio;
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    loggingInterceptor.onRequest(options);
    handler.next(options);
  },
  onResponse: (response, handler) {
    loggingInterceptor.onResponse(response);
    handler.next(response);
  },
  onError: (error, handler) {
    loggingInterceptor.onError(error);
    handler.next(error);
  },
));
```

## 📊 Logging

### Logger personnalisé

```dart
import 'package:logging/logging.dart';

class DirectusLogger {
  final Logger _logger = Logger('DirectusClient');
  
  void init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }
  
  void logRequest(String method, String path) {
    _logger.info('$method $path');
  }
  
  void logResponse(int statusCode, String path, Duration duration) {
    _logger.info('$statusCode $path (${duration.inMilliseconds}ms)');
  }
  
  void logError(String message, [dynamic error]) {
    _logger.severe(message, error);
  }
}
```

### Debug mode

```dart
class DebugConfig {
  static const bool enableLogging = true;
  static const bool enableRequestLogging = true;
  static const bool enableResponseLogging = true;
  
  static void log(String message) {
    if (enableLogging) {
      print('[Directus] $message');
    }
  }
}
```

## 🔒 Sécurité

### Stockage sécurisé des tokens

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  final _storage = FlutterSecureStorage();
  
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
  }
  
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }
  
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }
  
  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
```

### Validation des entrées

```dart
class InputValidator {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= 8 &&
           password.contains(RegExp(r'[A-Z]')) &&
           password.contains(RegExp(r'[0-9]'));
  }
  
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email requis';
    }
    if (!isValidEmail(value)) {
      return 'Email invalide';
    }
    return null;
  }
}
```

## 🧪 Testing

### Mock du client

```dart
import 'package:mockito/mockito.dart';

class MockDirectusClient extends Mock implements DirectusClient {}
class MockItemsService extends Mock implements ItemsService {}

void main() {
  group('ArticleService', () {
    late MockDirectusClient mockDirectus;
    late MockItemsService mockItems;
    
    setUp(() {
      mockDirectus = MockDirectusClient();
      mockItems = MockItemsService();
      
      when(mockDirectus.items('articles')).thenReturn(mockItems);
    });
    
    test('getArticles returns list of articles', () async {
      when(mockItems.readMany()).thenAnswer((_) async => DirectusResponse(
        data: [
          {'id': '1', 'title': 'Article 1'},
          {'id': '2', 'title': 'Article 2'},
        ],
      ));
      
      final service = ArticleService(mockDirectus);
      final articles = await service.getArticles();
      
      expect(articles.length, 2);
      expect(articles[0].title, 'Article 1');
    });
  });
}
```

## 🎯 Patterns avancés

### Repository Pattern

```dart
abstract class Repository<T> {
  Future<List<T>> findAll();
  Future<T?> findById(String id);
  Future<T> create(T item);
  Future<T> update(String id, T item);
  Future<void> delete(String id);
}

class ArticleRepository implements Repository<Article> {
  final DirectusClient directus;
  
  ArticleRepository(this.directus);
  
  @override
  Future<List<Article>> findAll() async {
    final result = await directus.items('articles').readMany();
    return result.data?.map((d) => Article(d)).toList() ?? [];
  }
  
  @override
  Future<Article?> findById(String id) async {
    try {
      final result = await directus.items('articles').readOne(id: id);
      return result.data != null ? Article(result.data!) : null;
    } on DirectusNotFoundException {
      return null;
    }
  }
  
  @override
  Future<Article> create(Article item) async {
    final result = await directus.items('articles').createOne(
      item: item.toJson(),
    );
    return Article(result.data!);
  }
  
  @override
  Future<Article> update(String id, Article item) async {
    final result = await directus.items('articles').updateOne(
      id: id,
      item: item.toJson(),
    );
    return Article(result.data!);
  }
  
  @override
  Future<void> delete(String id) async {
    await directus.items('articles').deleteOne(id: id);
  }
}
```

### Service Layer Pattern

```dart
class ArticleService {
  final ArticleRepository _repository;
  final CacheService _cache;
  final Logger _logger;
  
  ArticleService(this._repository, this._cache, this._logger);
  
  Future<Result<List<Article>>> getPublishedArticles() async {
    try {
      // Vérifier cache
      final cached = _cache.get<List<Article>>('published_articles');
      if (cached != null) {
        _logger.info('Returning cached articles');
        return Result.success(cached);
      }
      
      // Charger depuis API
      final articles = await _repository.findAll();
      final published = articles
          .where((a) => a.status == 'published')
          .toList();
      
      // Mettre en cache
      _cache.set('published_articles', published);
      
      return Result.success(published);
    } catch (e) {
      _logger.error('Failed to get articles', e);
      return Result.failure(e.toString());
    }
  }
}
```

## 🔄 Synchronisation offline

### Détection de connexion

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  Stream<bool> get isOnline =>
      _connectivity.onConnectivityChanged.map(
        (result) => result != ConnectivityResult.none,
      );
  
  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

### Queue de requêtes offline

```dart
class OfflineQueue {
  final List<PendingRequest> _queue = [];
  
  void addRequest(PendingRequest request) {
    _queue.add(request);
    _saveQueue();
  }
  
  Future<void> processQueue() async {
    final isOnline = await connectivityService.checkConnection();
    if (!isOnline) return;
    
    for (final request in List.from(_queue)) {
      try {
        await request.execute();
        _queue.remove(request);
      } catch (e) {
        print('Failed to process request: $e');
      }
    }
    
    _saveQueue();
  }
  
  void _saveQueue() {
    // Sauvegarder dans le stockage local
  }
}
```

## 📱 Optimisations mobile

### Images optimisées

```dart
String getOptimizedImageUrl(String fileId) {
  final isLowEnd = Platform.isAndroid; // Simplification
  
  return directus.files.getFileUrl(
    fileId,
    transform: AssetTransform(
      width: isLowEnd ? 400 : 800,
      format: AssetFormat.webp,
      quality: isLowEnd ? 75 : 85,
    ),
  );
}
```

### Prefetching

```dart
class DataPrefetcher {
  Future<void> prefetchData() async {
    // Précharger les données fréquemment utilisées
    Future.wait([
      directus.items('categories').readMany(),
      directus.items('featured_articles').readMany(),
      directus.settings.read(),
    ]);
  }
}
```

## 💡 Bonnes pratiques

1. **Utiliser des repositories** pour séparer la logique métier de l'accès aux données
2. **Implémenter du caching** pour réduire les requêtes réseau
3. **Logger les erreurs** pour faciliter le debugging
4. **Tester avec des mocks** pour des tests rapides et fiables
5. **Valider les entrées** côté client avant d'envoyer au serveur
6. **Gérer l'offline** pour une meilleure expérience utilisateur
7. **Optimiser les images** selon le device
8. **Utiliser la pagination** pour les grandes listes

## 🔗 Ressources

- [Getting Started](01-getting-started.md)
- [Core Concepts](02-core-concepts.md)
- [Error Handling](11-error-handling.md)
- [API Reference](api-reference/)

## 📚 Référence API

- [DirectusClient](api-reference/directus-client.md)
- [DirectusConfig](api-reference/directus-config.md)
- [Cache Utilities](api-reference/cache-utilities.md)

import '../core/directus_http_client.dart';

/// Service pour les utilitaires Directus.
///
/// Ce service fournit des fonctions utilitaires diverses pour:
/// - Générer des hashs
/// - Générer des valeurs aléatoires
/// - Trier des items
/// - Gérer le cache
/// - Importer/Exporter des données
///
/// Exemple d'utilisation:
/// ```dart
/// // Générer un hash
/// final hash = await client.utilities.hash.generate('password123');
/// print('Hash: $hash');
///
/// // Vérifier un hash
/// final isValid = await client.utilities.hash.verify('password123', hash);
///
/// // Générer une chaîne aléatoire
/// final random = await client.utilities.random.string(length: 32);
///
/// // Vider le cache
/// await client.utilities.cache.clear();
///
/// // Exporter des données
/// final export = await client.utilities.export('articles', format: 'json');
///
/// // Importer des données
/// await client.utilities.import('articles', data);
/// ```
class UtilitiesService {
  final DirectusHttpClient _httpClient;
  late final HashUtility hash;
  late final RandomUtility random;
  late final CacheUtility cache;
  late final SortUtility sort;

  UtilitiesService(this._httpClient) {
    hash = HashUtility(_httpClient);
    random = RandomUtility(_httpClient);
    cache = CacheUtility(_httpClient);
    sort = SortUtility(_httpClient);
  }

  /// Exporte des données d'une collection
  ///
  /// [collection] Nom de la collection à exporter
  /// [format] Format d'export: 'json', 'csv', 'xml' (défaut: 'json')
  /// [query] Paramètres de requête optionnels pour filtrer les données
  ///
  /// Retourne les données exportées dans le format demandé
  Future<dynamic> export(
    String collection, {
    String format = 'json',
    Map<String, dynamic>? query,
  }) async {
    return await _httpClient.get(
      '/utils/export/$collection',
      queryParameters: {'format': format, if (query != null) ...query},
    );
  }

  /// Importe des données dans une collection
  ///
  /// [collection] Nom de la collection cible
  /// [data] Données à importer
  /// [format] Format des données: 'json', 'csv', 'xml' (défaut: 'json')
  ///
  /// Retourne le résultat de l'import avec le nombre d'items créés
  Future<dynamic> import(
    String collection,
    dynamic data, {
    String format = 'json',
  }) async {
    return await _httpClient.post(
      '/utils/import/$collection',
      data: data,
      queryParameters: {'format': format},
    );
  }
}

/// Utilitaires pour la génération et vérification de hashs
class HashUtility {
  final DirectusHttpClient _httpClient;

  HashUtility(this._httpClient);

  /// Génère un hash à partir d'une chaîne
  ///
  /// [string] Chaîne à hasher
  ///
  /// Retourne le hash généré
  Future<String> generate(String string) async {
    final response = await _httpClient.post(
      '/utils/hash/generate',
      data: {'string': string},
    );
    return response.data['data'] as String;
  }

  /// Vérifie si une chaîne correspond à un hash
  ///
  /// [string] Chaîne originale
  /// [hash] Hash à vérifier
  ///
  /// Retourne true si la chaîne correspond au hash
  Future<bool> verify(String string, String hash) async {
    final response = await _httpClient.post(
      '/utils/hash/verify',
      data: {'string': string, 'hash': hash},
    );
    return response.data['data'] as bool;
  }
}

/// Utilitaires pour la génération de valeurs aléatoires
class RandomUtility {
  final DirectusHttpClient _httpClient;

  RandomUtility(this._httpClient);

  /// Génère une chaîne aléatoire
  ///
  /// [length] Longueur de la chaîne (défaut: 32)
  ///
  /// Retourne une chaîne aléatoire
  Future<String> string({int length = 32}) async {
    final response = await _httpClient.get(
      '/utils/random/string',
      queryParameters: {'length': length},
    );
    return response.data['data'] as String;
  }
}

/// Utilitaires pour la gestion du cache
class CacheUtility {
  final DirectusHttpClient _httpClient;

  CacheUtility(this._httpClient);

  /// Vide tout le cache
  Future<void> clear() async {
    await _httpClient.post('/utils/cache/clear');
  }

  /// Vide le cache d'une collection spécifique
  ///
  /// [collection] Nom de la collection
  Future<void> clearCollection(String collection) async {
    await _httpClient.post(
      '/utils/cache/clear',
      data: {'collection': collection},
    );
  }
}

/// Utilitaires pour le tri des items
class SortUtility {
  final DirectusHttpClient _httpClient;

  SortUtility(this._httpClient);

  /// Réordonne les items d'une collection
  ///
  /// [collection] Nom de la collection
  /// [itemId] ID de l'item à déplacer
  /// [to] Nouvelle position (index)
  ///
  /// Cet endpoint est utile pour les collections ayant un champ 'sort'
  /// qui définit l'ordre d'affichage.
  Future<void> reorder(String collection, String itemId, int to) async {
    await _httpClient.post(
      '/utils/sort/$collection',
      data: {'item': itemId, 'to': to},
    );
  }
}

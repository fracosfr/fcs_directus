import '../core/directus_http_client.dart';
import '../models/directus_filter.dart';
import 'items_service.dart';

/// Service pour gérer les versions de contenu dans Directus.
///
/// Les versions permettent de créer des brouillons et des variantes
/// de contenu avant publication (Content Versioning).
///
/// Exemple d'utilisation:
/// ```dart
/// // Récupérer toutes les versions
/// final versions = await client.versions.getVersions();
///
/// // Créer une version d'un item
/// final version = await client.versions.createVersion({
///   'collection': 'articles',
///   'item': 'article-id',
///   'name': 'Version brouillon',
/// });
///
/// // Récupérer les versions d'un item
/// final itemVersions = await client.versions.getItemVersions('articles', 'article-id');
///
/// // Promouvoir une version (la rendre principale)
/// await client.versions.promoteVersion(version-id);
/// ```
class VersionsService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  VersionsService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_versions');
  }

  /// Récupère la liste de toutes les versions
  Future<DirectusResponse<dynamic>> getVersions({
    QueryParameters? query,
  }) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère une version par son ID
  Future<Map<String, dynamic>> getVersion(
    String id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id, query: query);
  }

  /// Crée une nouvelle version
  ///
  /// [data] Données de la version:
  /// - collection: Collection de l'item (requis)
  /// - item: ID de l'item (requis)
  /// - name: Nom de la version
  /// - key: Clé unique de la version
  /// - delta: Modifications par rapport à la version principale
  /// - user_created: Utilisateur créateur
  /// - date_created: Date de création
  /// - user_updated: Utilisateur qui a modifié
  /// - date_updated: Date de modification
  Future<Map<String, dynamic>> createVersion(Map<String, dynamic> data) async {
    return await _itemsService.createOne(data);
  }

  /// Met à jour une version existante
  Future<Map<String, dynamic>> updateVersion(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Supprime une version
  Future<void> deleteVersion(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Supprime plusieurs versions
  Future<void> deleteVersions(List<String> ids) async {
    await _itemsService.deleteMany(keys: ids);
  }

  // === Méthodes helper ===

  /// Récupère les versions d'un item spécifique
  Future<DirectusResponse<dynamic>> getItemVersions(
    String collection,
    String itemId, {
    QueryParameters? query,
  }) async {
    final filter = Filter.and([
      Filter.field('collection').equals(collection),
      Filter.field('item').equals(itemId),
    ]);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['-date_created'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getVersions(query: mergedQuery);
  }

  /// Récupère les versions d'une collection
  Future<DirectusResponse<dynamic>> getCollectionVersions(
    String collection, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('collection').equals(collection);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['-date_created'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getVersions(query: mergedQuery);
  }

  /// Récupère les versions créées par un utilisateur
  Future<DirectusResponse<dynamic>> getUserVersions(
    String userId, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('user_created').equals(userId);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['-date_created'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getVersions(query: mergedQuery);
  }

  /// Promouvoir une version (endpoint spécial)
  ///
  /// Rend une version comme version principale de l'item.
  /// Cette opération applique les modifications (delta) de la version
  /// sur l'item principal.
  ///
  /// Note: Cet endpoint pourrait nécessiter une route spéciale selon
  /// la version de Directus. Vérifiez la documentation de votre version.
  Future<dynamic> promoteVersion(String versionId) async {
    return await _httpClient.post('/versions/$versionId/promote');
  }

  /// Sauvegarde l'état actuel d'un item comme nouvelle version
  ///
  /// [collection] Collection de l'item
  /// [itemId] ID de l'item
  /// [name] Nom de la version (optionnel)
  Future<dynamic> saveItemAsVersion(
    String collection,
    String itemId, {
    String? name,
  }) async {
    final response = await _httpClient.post(
      '/versions/save',
      data: {
        'collection': collection,
        'item': itemId,
        if (name != null) 'name': name,
      },
    );
    return response.data['data'];
  }

  /// Compare deux versions
  ///
  /// [versionId1] ID de la première version
  /// [versionId2] ID de la deuxième version
  ///
  /// Retourne les différences entre les deux versions
  Future<dynamic> compareVersions(String versionId1, String versionId2) async {
    return await _httpClient.get(
      '/versions/compare',
      queryParameters: {'version1': versionId1, 'version2': versionId2},
    );
  }
}

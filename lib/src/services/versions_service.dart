import '../core/directus_http_client.dart';
import '../models/directus_filter.dart';
import '../models/directus_version.dart';
import 'items_service.dart';
import 'system_items_service.dart';

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
class VersionsService extends DirectusSystemService<DirectusVersion> {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  VersionsService(this._httpClient)
    : super(_httpClient, 'directus_versions', DirectusVersion.factory) {
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

  /// Compare une version avec l'item principal (`GET /versions/{id}/compare`).
  ///
  /// Retourne `outdated` (l'item principal a changé depuis la création),
  /// `mainHash` (à passer à [promote]), `current` (delta de la version) et
  /// `main` (état actuel de l'item).
  Future<Map<String, dynamic>> compare(String versionId) async {
    final response = await _httpClient.get('/versions/$versionId/compare');
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// Enregistre des modifications dans une version
  /// (`POST /versions/{id}/save`). [data] est fusionné au delta existant.
  ///
  /// Retourne l'item tel qu'il apparaît avec la version appliquée.
  Future<Map<String, dynamic>?> save(
    String versionId,
    Map<String, dynamic> data,
  ) async {
    final response = await _httpClient.post(
      '/versions/$versionId/save',
      data: data,
    );
    final result = response.data?['data'];
    return result == null ? null : Map<String, dynamic>.from(result as Map);
  }

  /// Applique une version à l'item principal (`POST /versions/{id}/promote`).
  ///
  /// [mainHash] Hash retourné par [compare] (détection de conflit)
  /// [fields] Ne promouvoir que ces champs
  ///
  /// Retourne la clé primaire de l'item mis à jour.
  Future<dynamic> promote(
    String versionId, {
    String? mainHash,
    List<String>? fields,
  }) async {
    final response = await _httpClient.post(
      '/versions/$versionId/promote',
      data: {
        if (mainHash != null) 'mainHash': mainHash,
        if (fields != null) 'fields': fields,
      },
    );
    return response.data?['data'];
  }

  /// Ancien nom de [promote].
  @Deprecated('Utiliser promote(versionId, mainHash: ...).')
  Future<dynamic> promoteVersion(String versionId) => promote(versionId);

  /// Créait une version via une route inexistante (`/versions/save`).
  @Deprecated(
    'Créer la version avec createOne(DirectusVersion) puis save(id, data).',
  )
  Future<dynamic> saveItemAsVersion(
    String collection,
    String itemId, {
    String? name,
  }) async {
    final version = await createOne(
      DirectusVersion.empty()
        ..collection.set(collection)
        ..item.set(itemId)
        ..key.set(name ?? 'draft')
        ..name.set(name ?? 'Draft'),
    );
    return version?.toMap();
  }

  /// Directus compare une version à l'item principal, pas deux versions.
  @Deprecated('Utiliser compare(versionId).')
  Future<dynamic> compareVersions(String versionId1, String versionId2) =>
      compare(versionId1);
}

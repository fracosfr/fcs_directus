import '../core/directus_http_client.dart';
import '../models/directus_filter.dart';
import 'items_service.dart';

/// Service pour gérer les presets (signets et préférences) dans Directus.
///
/// Les presets stockent les préférences utilisateur pour les collections.
///
/// Exemple d'utilisation:
/// ```dart
/// // Créer un signet
/// await client.presets.createPreset({
///   'collection': 'articles',
///   'bookmark': 'Articles publiés',
///   'search': 'published',
///   'layout': 'tabular',
///   'layout_query': {'sort': ['-published_on']},
/// });
///
/// // Récupérer les signets d'un utilisateur
/// final bookmarks = await client.presets.getBookmarks('user-id');
/// ```
class PresetsService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  PresetsService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_presets');
  }

  /// Récupère la liste de tous les presets
  Future<DirectusResponse<dynamic>> getPresets({QueryParameters? query}) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère un preset par son ID
  Future<Map<String, dynamic>> getPreset(
    int id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id.toString(), query: query);
  }

  /// Crée un nouveau preset
  Future<Map<String, dynamic>> createPreset(Map<String, dynamic> data) async {
    return await _itemsService.createOne(data);
  }

  /// Crée plusieurs presets en une seule requête
  Future<List<dynamic>> createPresets(
    List<Map<String, dynamic>> presets,
  ) async {
    return await _itemsService.createMany(presets);
  }

  /// Met à jour un preset existant
  Future<Map<String, dynamic>> updatePreset(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Met à jour plusieurs presets
  Future<List<dynamic>> updatePresets(
    List<String> ids,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateMany(ids, data);
  }

  /// Supprime un preset
  Future<void> deletePreset(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Supprime plusieurs presets
  Future<void> deletePresets(List<String> ids) async {
    await _itemsService.deleteMany(ids);
  }

  // === Méthodes helper ===

  /// Récupère les signets (bookmarks) d'un utilisateur
  Future<DirectusResponse<dynamic>> getBookmarks(
    String userId, {
    QueryParameters? query,
  }) async {
    final filter = Filter.and([
      Filter.field('user').equals(userId),
      Filter.field('bookmark').isNotNull(),
    ]);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['bookmark'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getPresets(query: mergedQuery);
  }

  /// Récupère les presets d'un utilisateur pour une collection
  Future<DirectusResponse<dynamic>> getUserPresets(
    String userId,
    String collection, {
    QueryParameters? query,
  }) async {
    final filter = Filter.and([
      Filter.field('user').equals(userId),
      Filter.field('collection').equals(collection),
    ]);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort,
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getPresets(query: mergedQuery);
  }

  /// Récupère les presets d'un rôle pour une collection
  Future<DirectusResponse<dynamic>> getRolePresets(
    String roleId,
    String collection, {
    QueryParameters? query,
  }) async {
    final filter = Filter.and([
      Filter.field('role').equals(roleId),
      Filter.field('collection').equals(collection),
      Filter.field('user').isNull(),
    ]);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort,
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getPresets(query: mergedQuery);
  }

  /// Récupère les presets globaux pour une collection
  Future<DirectusResponse<dynamic>> getGlobalPresets(
    String collection, {
    QueryParameters? query,
  }) async {
    final filter = Filter.and([
      Filter.field('collection').equals(collection),
      Filter.field('user').isNull(),
      Filter.field('role').isNull(),
    ]);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort,
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getPresets(query: mergedQuery);
  }
}

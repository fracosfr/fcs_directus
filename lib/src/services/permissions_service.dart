import '../core/directus_http_client.dart';
import '../models/directus_filter.dart';
import 'items_service.dart';

/// Service pour gérer les permissions dans Directus.
///
/// Les permissions définissent les règles d'accès pour les collections et actions.
///
/// Exemple d'utilisation:
/// ```dart
/// // Créer une permission de lecture
/// await client.permissions.createPermission({
///   'collection': 'articles',
///   'action': 'read',
///   'policy': 'policy-id',
///   'fields': ['*'],
/// });
///
/// // Récupérer les permissions d'une policy
/// final permissions = await client.permissions.getPermissionsByPolicy('policy-id');
/// ```
class PermissionsService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  PermissionsService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_permissions');
  }

  /// Récupère la liste de toutes les permissions
  Future<DirectusResponse<dynamic>> getPermissions({
    QueryParameters? query,
  }) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère une permission par son ID
  Future<Map<String, dynamic>> getPermission(
    int id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id.toString(), query: query);
  }

  /// Crée une nouvelle permission
  Future<Map<String, dynamic>> createPermission(
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.createOne(data);
  }

  /// Crée plusieurs permissions en une seule requête
  Future<List<dynamic>> createPermissions(
    List<Map<String, dynamic>> permissions,
  ) async {
    return await _itemsService.createMany(permissions);
  }

  /// Met à jour une permission existante
  Future<Map<String, dynamic>> updatePermission(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Met à jour plusieurs permissions
  Future<List<dynamic>> updatePermissions(
    List<String> ids,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateMany(ids, data);
  }

  /// Supprime une permission
  Future<void> deletePermission(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Supprime plusieurs permissions
  Future<void> deletePermissions(List<String> ids) async {
    await _itemsService.deleteMany(ids);
  }

  // === Méthodes helper ===

  /// Récupère les permissions d'une policy
  Future<DirectusResponse<dynamic>> getPermissionsByPolicy(
    String policyId, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('policy').equals(policyId);
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
    return await getPermissions(query: mergedQuery);
  }

  /// Récupère les permissions d'une collection
  Future<DirectusResponse<dynamic>> getPermissionsByCollection(
    String collection, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('collection').equals(collection);
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
    return await getPermissions(query: mergedQuery);
  }

  /// Récupère les permissions pour une action spécifique
  Future<DirectusResponse<dynamic>> getPermissionsByAction(
    String action, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('action').equals(action);
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
    return await getPermissions(query: mergedQuery);
  }

  /// Récupère les permissions de l'utilisateur actuel
  Future<dynamic> getMyPermissions() async {
    return await _httpClient.get('/permissions/me');
  }

  /// Récupère les permissions de l'utilisateur actuel pour un item spécifique
  Future<dynamic> getItemPermissions(
    String collection,
    String itemId,
  ) async {
    return await _httpClient.get('/permissions/me/$collection/$itemId');
  }
}

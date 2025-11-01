import '../core/directus_http_client.dart';
import 'item_active_service.dart';
import '../models/directus_model.dart';
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
    _itemsService = ItemsService<Map<String, dynamic>>(
      _httpClient,
      'directus_permissions',
    );
  }

  ItemActiveService<T> _activeService<T extends DirectusModel>() =>
      ItemActiveService<T>(_httpClient, 'directus_permissions');

  /// Récupère la liste de toutes les permissions typées
  Future<DirectusResponse<T>> getPermissions<T extends DirectusModel>({
    QueryParameters? query,
  }) async {
    return await _activeService<T>().readMany(query: query);
  }

  /// Récupère une permission par son ID typée
  Future<T> getPermission<T extends DirectusModel>(
    int id, {
    QueryParameters? query,
  }) async {
    return await _activeService<T>().readOne(id.toString(), query: query);
  }

  /// Crée une nouvelle permission typée
  Future<T> createPermission<T extends DirectusModel>(T permission) async {
    final response = await _itemsService.createOne(permission.toJson());
    final factory = DirectusModel.getFactory<T>();
    if (factory == null) {
      throw StateError('No factory registered for type $T.');
    }
    return factory(response as Map<String, dynamic>) as T;
  }

  /// Crée plusieurs permissions typées en une seule requête
  Future<List<T>> createPermissions<T extends DirectusModel>(
    List<T> permissions,
  ) async {
    final response = await _itemsService.createMany(
      permissions.map((p) => p.toJson()).toList(),
    );
    final factory = DirectusModel.getFactory<T>();
    if (factory == null) {
      throw StateError('No factory registered for type $T.');
    }
    return (response)
        .map<T>((item) => factory(item as Map<String, dynamic>) as T)
        .toList();
  }

  /// Met à jour une permission typée
  Future<T> updatePermission<T extends DirectusModel>(T permission) async {
    if (permission.id == null) {
      throw ArgumentError(
        'La permission doit avoir un id pour être mise à jour.',
      );
    }
    final response = await _itemsService.updateOne(
      permission.id!,
      permission.toJsonDirty(),
    );
    final factory = DirectusModel.getFactory<T>();
    if (factory == null) {
      throw StateError('No factory registered for type $T.');
    }
    return factory(response as Map<String, dynamic>) as T;
  }

  /// Met à jour plusieurs permissions typées
  Future<List<T>> updatePermissions<T extends DirectusModel>(
    List<T> permissions,
  ) async {
    final ids = permissions.map((p) => p.id).whereType<String>().toList();
    if (ids.length != permissions.length) {
      throw ArgumentError(
        'Toutes les permissions doivent avoir un id pour être mises à jour.',
      );
    }
    final dirtyData = permissions.first.toJsonDirty();
    final response = await _itemsService.updateMany(ids, dirtyData);
    final factory = DirectusModel.getFactory<T>();
    if (factory == null) {
      throw StateError('No factory registered for type $T.');
    }
    return (response)
        .map<T>((item) => factory(item as Map<String, dynamic>) as T)
        .toList();
  }

  /// Supprime une permission typée
  Future<void> deletePermission<T extends DirectusModel>(T permission) async {
    if (permission.id == null) {
      throw ArgumentError(
        'La permission doit avoir un id pour être supprimée.',
      );
    }
    await _itemsService.deleteOne(permission.id!);
  }

  /// Supprime plusieurs permissions typées
  Future<void> deletePermissions<T extends DirectusModel>(
    List<T> permissions,
  ) async {
    final ids = permissions.map((p) => p.id).whereType<String>().toList();
    if (ids.length != permissions.length) {
      throw ArgumentError(
        'Toutes les permissions doivent avoir un id pour être supprimées.',
      );
    }
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
  Future<dynamic> getItemPermissions(String collection, String itemId) async {
    return await _httpClient.get('/permissions/me/$collection/$itemId');
  }
}

import '../core/directus_http_client.dart';
import '../models/directus_model.dart';
import '../models/directus_role.dart';
import 'items_service.dart';

/// Service pour gérer les rôles Directus.
///
/// Permet de gérer tous les aspects des rôles :
/// - CRUD (Create, Read, Update, Delete)
/// - Opérations batch (création, modification, suppression multiples)
/// - Gestion des hiérarchies de rôles (parent/enfants)
/// - Gestion des politiques associées
///
/// Exemple d'utilisation :
/// ```dart
/// final roles = client.roles;
///
/// // Récupérer tous les rôles
/// final allRoles = await roles.getRoles();
///
/// // Récupérer un rôle spécifique
/// final role = await roles.getRole('role-id');
///
/// // Créer un nouveau rôle
/// final newRole = await roles.createRole(DirectusRole.empty()
///   ..name.set('Editor')
///   ..icon.set('edit')
///   ..description.set('Can edit content'));
///
/// // Mettre à jour un rôle
/// final updated = await roles.updateRole('role-id', DirectusRole.empty()
///   ..description.set('Updated description'));
///
/// // Supprimer un rôle
/// await roles.deleteRole('role-id');
/// ```
class RolesService {
  final DirectusHttpClient _httpClient;

  RolesService(this._httpClient);

  // ========================================
  // Opérations CRUD de base
  // ========================================

  /// Récupère la liste des rôles typés
  ///
  /// Exemple :
  /// ```dart
  /// final response = await client.roles.getRoles();
  /// for (final role in response.data) {
  ///   print(role.name.value);
  /// }
  /// ```
  Future<DirectusResponse<T>> getRoles<T extends DirectusRole>({
    QueryParameters? query,
  }) async {
    final response = await _httpClient.get(
      '/roles',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data['data'] as List;
    final meta = response.data['meta'] != null
        ? DirectusMeta.fromJson(response.data['meta'] as Map<String, dynamic>)
        : null;

    final baseFactory = DirectusModel.getFactory<T>() ?? DirectusRole.factory;
    final items = data
        .map<T>((item) => baseFactory(item as Map<String, dynamic>) as T)
        .toList();

    return DirectusResponse(data: items, meta: meta);
  }

  /// Récupère un rôle par son ID typé
  ///
  /// Exemple :
  /// ```dart
  /// final role = await client.roles.getRole('role-id');
  /// print(role.name.value);
  /// ```
  Future<T> getRole<T extends DirectusRole>(
    String id, {
    QueryParameters? query,
  }) async {
    final response = await _httpClient.get(
      '/roles/$id',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final baseFactory = DirectusModel.getFactory<T>() ?? DirectusRole.factory;
    return baseFactory(data) as T;
  }

  /// Crée un nouveau rôle
  ///
  /// Champs requis : name
  ///
  /// Exemple :
  /// ```dart
  /// final newRole = await rolesService.createRole(
  ///   DirectusRole.empty()
  ///     ..name.set('Content Editor')
  ///     ..icon.set('edit')
  ///     ..description.set('Can create and edit content'),
  /// );
  /// ```
  Future<DirectusRole> createRole(
    Map<String, dynamic> data, {
    QueryParameters? query,
  }) async {
    final response = await _httpClient.post(
      '/roles',
      data: data,
      queryParameters: query?.toQueryParameters(),
    );
    return DirectusRole(response.data['data'] as Map<String, dynamic>);
  }

  /// Crée plusieurs rôles en une seule requête
  ///
  /// Champs requis pour chaque rôle : name
  ///
  /// Exemple :
  /// ```dart
  /// final newRoles = await rolesService.createRoles([
  ///   DirectusRole.empty()
  ///     ..name.set('Editor')
  ///     ..icon.set('edit'),
  ///   DirectusRole.empty()
  ///     ..name.set('Viewer')
  ///     ..icon.set('visibility'),
  /// ]);
  /// ```
  Future<List<DirectusRole>> createRoles(
    List<Map<String, dynamic>> roles, {
    QueryParameters? query,
  }) async {
    final response = await _httpClient.post(
      '/roles',
      data: roles,
      queryParameters: query?.toQueryParameters(),
    );
    final data = response.data['data'];
    if (data is List) {
      return data
          .map((item) => DirectusRole(item as Map<String, dynamic>))
          .toList();
    }
    return [DirectusRole(data as Map<String, dynamic>)];
  }

  /// Met à jour un rôle
  ///
  /// Exemple :
  /// ```dart
  /// final updated = await rolesService.updateRole(
  ///   'role-id',
  ///   DirectusRole.empty()
  ///     ..description.set('Updated description')
  ///     ..icon.set('new_icon'),
  /// );
  /// ```
  Future<DirectusRole> updateRole(
    String id,
    Map<String, dynamic> data, {
    QueryParameters? query,
  }) async {
    final response = await _httpClient.patch(
      '/roles/$id',
      data: data,
      queryParameters: query?.toQueryParameters(),
    );
    return DirectusRole(response.data['data'] as Map<String, dynamic>);
  }

  /// Met à jour plusieurs rôles
  ///
  /// [keys] Liste des IDs des rôles à mettre à jour
  /// [data] Données à appliquer à tous les rôles
  ///
  /// Exemple :
  /// ```dart
  /// final updated = await rolesService.updateRoles(
  ///   keys: ['role-1', 'role-2'],
  ///   data: {'icon': 'group'},
  /// );
  /// ```
  Future<List<DirectusRole>> updateRoles({
    required List<String> keys,
    required Map<String, dynamic> data,
    QueryParameters? query,
  }) async {
    final response = await _httpClient.patch(
      '/roles',
      data: {'keys': keys, 'data': data},
      queryParameters: query?.toQueryParameters(),
    );
    final responseData = response.data['data'];
    if (responseData is List) {
      return responseData
          .map((item) => DirectusRole(item as Map<String, dynamic>))
          .toList();
    }
    return [DirectusRole(responseData as Map<String, dynamic>)];
  }

  /// Supprime un rôle
  ///
  /// Exemple :
  /// ```dart
  /// await rolesService.deleteRole('old-role-id');
  /// ```
  Future<void> deleteRole(String id) async {
    await _httpClient.delete('/roles/$id');
  }

  /// Supprime plusieurs rôles
  ///
  /// Exemple :
  /// ```dart
  /// await rolesService.deleteRoles(['role-1', 'role-2']);
  /// ```
  Future<void> deleteRoles(List<String> ids) async {
    await _httpClient.delete('/roles', data: ids);
  }

  /// Supprime plusieurs rôles typés
  ///
  /// Exemple :
  /// ```dart
  /// await rolesService.deleteRolesTyped(rolesToDelete);
  /// ```
  Future<void> deleteRolesTyped<T extends DirectusRole>(List<T> roles) async {
    final ids = roles.map((r) => r.id).whereType<String>().toList();
    if (ids.length != roles.length) {
      throw ArgumentError(
        'Tous les rôles doivent avoir un id pour être supprimés.',
      );
    }
    await _httpClient.delete('/roles', data: ids);
  }

  // ========================================
  // Méthodes utilitaires
  // ========================================

  /// Récupère tous les rôles enfants d'un rôle parent
  ///
  /// Exemple :
  /// ```dart
  /// final children = await rolesService.getChildRoles('parent-role-id');
  /// ```
  Future<List<DirectusRole>> getChildRoles(
    String parentId, {
    QueryParameters? query,
  }) async {
    final filter = query?.filter ?? {};
    final newFilter = {
      ...filter as Map<String, dynamic>,
      'parent': {'_eq': parentId},
    };

    final newQuery = QueryParameters(
      filter: newFilter,
      fields: query?.fields,
      sort: query?.sort,
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );

    final response = await getRoles(query: newQuery);
    return response.data.cast<DirectusRole>();
  }

  /// Récupère le rôle parent d'un rôle
  ///
  /// Retourne null si le rôle n'a pas de parent
  ///
  /// Exemple :
  /// ```dart
  /// final parent = await rolesService.getParentRole('child-role-id');
  /// if (parent != null) {
  ///   print('Rôle parent: ${parent.name.value}');
  /// }
  /// ```
  Future<DirectusRole?> getParentRole(
    String roleId, {
    QueryParameters? query,
  }) async {
    final fields = [...?query?.fields, 'parent.*'];

    final newQuery = QueryParameters(
      fields: fields,
      filter: query?.filter,
      sort: query?.sort,
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );

    final role = await getRole(roleId, query: newQuery);
    if (role.parent.isEmpty) return null;

    return await getRole(role.parent.value);
  }
}

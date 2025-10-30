import '../core/directus_http_client.dart';
import '../models/directus_policy.dart';
import '../models/directus_model.dart';
import 'items_service.dart';

/// Service pour gérer les politiques Directus.
///
/// Les politiques définissent un ensemble spécifique de permissions d'accès
/// et constituent une unité composable qui peut être attribuée à la fois
/// aux rôles et aux utilisateurs.
///
/// Exemple d'utilisation :
/// ```dart
/// final policies = client.policies;
///
/// // Récupérer toutes les politiques
/// final allPolicies = await policies.getPolicies();
///
/// // Récupérer une politique spécifique
/// final policy = await policies.getPolicy('policy-id');
///
/// // Créer une nouvelle politique
/// final newPolicy = await policies.createPolicy(DirectusPolicy.empty()
///   ..name.set('Content Manager')
///   ..icon.set('edit')
///   ..description.set('Can manage content')
///   ..appAccess.set(true)
///   ..adminAccess.set(false));
///
/// // Mettre à jour une politique
/// final updated = await policies.updatePolicy('policy-id', DirectusPolicy.empty()
///   ..description.set('Updated description'));
///
/// // Supprimer une politique
/// await policies.deletePolicy('policy-id');
/// ```
class PoliciesService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  PoliciesService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_policies');
  }

  // ========================================
  // Opérations CRUD de base
  // ========================================

  /// Récupère la liste des politiques
  ///
  /// Supporte tous les paramètres de query (filter, sort, fields, etc.)
  ///
  /// Exemple :
  /// ```dart
  /// // Récupérer toutes les politiques avec leurs permissions
  /// final policies = await policiesService.getPolicies(
  ///   query: QueryParameters()
  ///     ..fields = ['*', 'permissions.*']
  ///     ..sort = ['name'],
  /// );
  /// ```
  Future<DirectusResponse<dynamic>> getPolicies({
    QueryParameters? query,
  }) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère une politique par son ID
  ///
  /// Retourne une politique typée [DirectusPolicy] ou une sous-classe si une factory est enregistrée.
  ///
  /// Exemple :
  /// ```dart
  /// final policy = await policiesService.getPolicy(
  ///   'admin-policy-id',
  ///   query: QueryParameters()
  ///     ..fields = ['*', 'permissions.*', 'roles.*', 'users.*'],
  /// );
  /// print('Politique: ${policy.name.value}');
  /// print('Accès admin: ${policy.isAdminPolicy}');
  /// ```
  Future<T> getPolicy<T extends DirectusPolicy>(
    String id, {
    QueryParameters? query,
  }) async {
    final data = await _itemsService.readOne(id, query: query);

    // Si un type spécifique est demandé, utiliser la factory
    if (T != DirectusPolicy) {
      final factory = DirectusModel.getFactory<T>();
      if (factory == null) {
        throw StateError(
          'No factory registered for type $T. '
          'Please register a factory using DirectusModel.registerFactory<$T>(...)',
        );
      }
      return factory(data) as T;
    }

    // Sinon retourner DirectusPolicy par défaut
    return DirectusPolicy(data) as T;
  }

  /// Crée une nouvelle politique
  ///
  /// Champs requis : name
  ///
  /// Exemple :
  /// ```dart
  /// final newPolicy = await policiesService.createPolicy(
  ///   DirectusPolicy.empty()
  ///     ..name.set('Content Manager')
  ///     ..icon.set('edit')
  ///     ..description.set('Can manage all content')
  ///     ..appAccess.set(true)
  ///     ..adminAccess.set(false)
  ///     ..enforceTfa.set(false),
  /// );
  /// ```
  Future<DirectusPolicy> createPolicy(
    Map<String, dynamic> data, {
    QueryParameters? query,
  }) async {
    final response = await _httpClient.post(
      '/policies',
      data: data,
      queryParameters: query?.toQueryParameters(),
    );
    return DirectusPolicy(response.data['data'] as Map<String, dynamic>);
  }

  /// Crée plusieurs politiques en une seule requête
  ///
  /// Champs requis pour chaque politique : name
  ///
  /// Exemple :
  /// ```dart
  /// final newPolicies = await policiesService.createPolicies([
  ///   DirectusPolicy.empty()
  ///     ..name.set('Editor')
  ///     ..appAccess.set(true),
  ///   DirectusPolicy.empty()
  ///     ..name.set('Viewer')
  ///     ..appAccess.set(true),
  /// ]);
  /// ```
  Future<List<DirectusPolicy>> createPolicies(
    List<Map<String, dynamic>> policies, {
    QueryParameters? query,
  }) async {
    final response = await _httpClient.post(
      '/policies',
      data: policies,
      queryParameters: query?.toQueryParameters(),
    );
    final data = response.data['data'];
    if (data is List) {
      return data
          .map((item) => DirectusPolicy(item as Map<String, dynamic>))
          .toList();
    }
    return [DirectusPolicy(data as Map<String, dynamic>)];
  }

  /// Met à jour une politique
  ///
  /// Exemple :
  /// ```dart
  /// final updated = await policiesService.updatePolicy(
  ///   'policy-id',
  ///   DirectusPolicy.empty()
  ///     ..description.set('Updated description')
  ///     ..enforceTfa.set(true),
  /// );
  /// ```
  Future<DirectusPolicy> updatePolicy(
    String id,
    Map<String, dynamic> data, {
    QueryParameters? query,
  }) async {
    final response = await _httpClient.patch(
      '/policies/$id',
      data: data,
      queryParameters: query?.toQueryParameters(),
    );
    return DirectusPolicy(response.data['data'] as Map<String, dynamic>);
  }

  /// Met à jour plusieurs politiques
  ///
  /// [keys] Liste des IDs des politiques à mettre à jour
  /// [data] Données à appliquer à toutes les politiques
  ///
  /// Exemple :
  /// ```dart
  /// final updated = await policiesService.updatePolicies(
  ///   keys: ['policy-1', 'policy-2'],
  ///   data: {'enforce_tfa': true},
  /// );
  /// ```
  Future<List<DirectusPolicy>> updatePolicies({
    required List<String> keys,
    required Map<String, dynamic> data,
    QueryParameters? query,
  }) async {
    final response = await _httpClient.patch(
      '/policies',
      data: {'keys': keys, 'data': data},
      queryParameters: query?.toQueryParameters(),
    );
    final responseData = response.data['data'];
    if (responseData is List) {
      return responseData
          .map((item) => DirectusPolicy(item as Map<String, dynamic>))
          .toList();
    }
    return [DirectusPolicy(responseData as Map<String, dynamic>)];
  }

  /// Supprime une politique
  ///
  /// Exemple :
  /// ```dart
  /// await policiesService.deletePolicy('old-policy-id');
  /// ```
  Future<void> deletePolicy(String id) async {
    await _httpClient.delete('/policies/$id');
  }

  /// Supprime plusieurs politiques
  ///
  /// Exemple :
  /// ```dart
  /// await policiesService.deletePolicies(['policy-1', 'policy-2', 'policy-3']);
  /// ```
  Future<void> deletePolicies(List<String> ids) async {
    await _httpClient.delete('/policies', data: ids);
  }

  // ========================================
  // Méthodes utilitaires
  // ========================================

  /// Récupère toutes les politiques avec accès administrateur
  ///
  /// Exemple :
  /// ```dart
  /// final adminPolicies = await policiesService.getAdminPolicies();
  /// ```
  Future<List<DirectusPolicy>> getAdminPolicies({
    QueryParameters? query,
  }) async {
    final filter = query?.filter ?? {};
    final newFilter = {
      ...filter as Map<String, dynamic>,
      'admin_access': {'_eq': true},
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

    final response = await getPolicies(query: newQuery);
    final data = response.data;
    return data
        .map((item) => DirectusPolicy(item as Map<String, dynamic>))
        .toList();
  }

  /// Récupère toutes les politiques avec accès à l'application
  ///
  /// Exemple :
  /// ```dart
  /// final appPolicies = await policiesService.getAppAccessPolicies();
  /// ```
  Future<List<DirectusPolicy>> getAppAccessPolicies({
    QueryParameters? query,
  }) async {
    final filter = query?.filter ?? {};
    final newFilter = {
      ...filter as Map<String, dynamic>,
      'app_access': {'_eq': true},
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

    final response = await getPolicies(query: newQuery);
    final data = response.data;
    return data
        .map((item) => DirectusPolicy(item as Map<String, dynamic>))
        .toList();
  }

  /// Récupère toutes les politiques qui requièrent la 2FA
  ///
  /// Exemple :
  /// ```dart
  /// final tfaPolicies = await policiesService.getTwoFactorPolicies();
  /// ```
  Future<List<DirectusPolicy>> getTwoFactorPolicies({
    QueryParameters? query,
  }) async {
    final filter = query?.filter ?? {};
    final newFilter = {
      ...filter as Map<String, dynamic>,
      'enforce_tfa': {'_eq': true},
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

    final response = await getPolicies(query: newQuery);
    final data = response.data;
    return data
        .map((item) => DirectusPolicy(item as Map<String, dynamic>))
        .toList();
  }
}

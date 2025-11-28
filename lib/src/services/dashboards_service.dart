import '../core/directus_http_client.dart';
import 'items_service.dart';

/// Service pour gérer les dashboards (tableaux de bord) dans Directus.
///
/// Les dashboards organisent différents panneaux dans une vue d'ensemble.
/// Ils peuvent être utilisés pour grouper les données par département, objectif,
/// processus métier ou tout ce que vous choisissez.
///
/// Exemple d'utilisation:
/// ```dart
/// // Créer un dashboard
/// await client.dashboards.createDashboard({
///   'name': 'Mon tableau de bord',
///   'icon': 'space_dashboard',
///   'note': 'Dashboard de test',
/// });
///
/// // Récupérer tous les dashboards
/// final dashboards = await client.dashboards.getDashboards();
///
/// // Récupérer un dashboard spécifique
/// final dashboard = await client.dashboards.getDashboard('dashboard-id');
/// ```
class DashboardsService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  DashboardsService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_dashboards');
  }

  /// Récupère la liste de tous les dashboards
  ///
  /// [query] Paramètres de requête optionnels (filtres, tri, pagination, etc.)
  ///
  /// Exemple:
  /// ```dart
  /// final dashboards = await client.dashboards.getDashboards(
  ///   query: QueryParameters(
  ///     sort: ['name'],
  ///     limit: 20,
  ///   ),
  /// );
  /// ```
  Future<DirectusResponse<dynamic>> getDashboards({
    QueryParameters? query,
  }) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère un dashboard par son ID
  ///
  /// [id] ID du dashboard
  /// [query] Paramètres de requête optionnels
  Future<Map<String, dynamic>> getDashboard(
    String id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id, query: query);
  }

  /// Crée un nouveau dashboard
  ///
  /// [data] Données du dashboard (name, icon, note, color, etc.)
  ///
  /// Exemple:
  /// ```dart
  /// final newDashboard = await client.dashboards.createDashboard({
  ///   'name': 'Sales Dashboard',
  ///   'icon': 'trending_up',
  ///   'note': 'Tableau de bord des ventes',
  ///   'color': '#2196F3',
  /// });
  /// ```
  Future<Map<String, dynamic>> createDashboard(
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.createOne(data);
  }

  /// Crée plusieurs dashboards en une seule requête
  ///
  /// [dashboards] Liste des dashboards à créer
  Future<List<dynamic>> createDashboards(
    List<Map<String, dynamic>> dashboards,
  ) async {
    return await _itemsService.createMany(dashboards);
  }

  /// Met à jour un dashboard existant
  ///
  /// [id] ID du dashboard à mettre à jour
  /// [data] Nouvelles données
  ///
  /// Exemple:
  /// ```dart
  /// await client.dashboards.updateDashboard(
  ///   'dashboard-id',
  ///   {'name': 'Nouveau nom', 'color': '#FF5722'},
  /// );
  /// ```
  Future<Map<String, dynamic>> updateDashboard(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Met à jour plusieurs dashboards en une seule requête
  ///
  /// [ids] Liste des IDs des dashboards à mettre à jour
  /// [data] Données à appliquer à tous les dashboards
  Future<List<dynamic>> updateDashboards(
    List<String> ids,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateMany(keys: ids, data: data);
  }

  /// Supprime un dashboard
  ///
  /// [id] ID du dashboard à supprimer
  Future<void> deleteDashboard(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Supprime plusieurs dashboards en une seule requête
  ///
  /// [ids] Liste des IDs des dashboards à supprimer
  Future<void> deleteDashboards(List<String> ids) async {
    await _itemsService.deleteMany(keys: ids);
  }

  /// Récupère les dashboards d'un utilisateur spécifique
  ///
  /// [userId] ID de l'utilisateur
  /// [query] Paramètres de requête optionnels
  Future<DirectusResponse<dynamic>> getDashboardsByUser(
    String userId, {
    QueryParameters? query,
  }) async {
    final mergedQuery = query ?? QueryParameters();
    final filter = mergedQuery.filter ?? {};
    filter['user_created'] = {'_eq': userId};

    return await _itemsService.readMany(
      query: QueryParameters(
        filter: filter,
        fields: mergedQuery.fields,
        limit: mergedQuery.limit,
        offset: mergedQuery.offset,
        sort: mergedQuery.sort,
        search: mergedQuery.search,
        deep: mergedQuery.deep,
      ),
    );
  }
}

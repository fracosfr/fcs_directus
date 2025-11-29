import '../core/directus_http_client.dart';
import '../models/directus_filter.dart';
import 'items_service.dart';

/// Service pour gérer les panneaux dans Directus.
///
/// Les panneaux sont des widgets affichés dans les dashboards.
///
/// Exemple d'utilisation:
/// ```dart
/// // Récupérer tous les panneaux
/// final panels = await client.panels.getPanels();
///
/// // Créer un nouveau panneau
/// final panel = await client.panels.createPanel({
///   'dashboard': dashboard-id,
///   'name': 'Sales Chart',
///   'type': 'time-series',
///   'width': 12,
///   'height': 6,
///   'options': {...},
/// });
///
/// // Récupérer les panneaux d'un dashboard
/// final dashboardPanels = await client.panels.getDashboardPanels(dashboard-id);
/// ```
class PanelsService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  PanelsService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_panels');
  }

  /// Récupère la liste de tous les panneaux
  Future<DirectusResponse<dynamic>> getPanels({QueryParameters? query}) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère un panneau par son ID
  Future<Map<String, dynamic>> getPanel(
    String id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id, query: query);
  }

  /// Crée un nouveau panneau
  Future<Map<String, dynamic>> createPanel(Map<String, dynamic> data) async {
    return await _itemsService.createOne(data);
  }

  /// Met à jour un panneau existant
  Future<Map<String, dynamic>> updatePanel(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Supprime un panneau
  Future<void> deletePanel(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Supprime plusieurs panneaux
  Future<void> deletePanels(List<String> ids) async {
    await _itemsService.deleteMany(keys: ids);
  }

  // === Méthodes helper ===

  /// Récupère les panneaux d'un dashboard spécifique
  Future<DirectusResponse<dynamic>> getDashboardPanels(
    String dashboardId, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('dashboard').equals(dashboardId);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['position_x', 'position_y'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getPanels(query: mergedQuery);
  }

  /// Récupère les panneaux par type
  Future<DirectusResponse<dynamic>> getPanelsByType(
    String type, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('type').equals(type);
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
    return await getPanels(query: mergedQuery);
  }

  /// Récupère les panneaux de largeur maximale (pleine largeur)
  Future<DirectusResponse<dynamic>> getFullWidthPanels(
    String dashboardId, {
    QueryParameters? query,
  }) async {
    final filter = Filter.and([
      Filter.field('dashboard').equals(dashboardId),
      Filter.field('width').equals(12),
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
    return await getPanels(query: mergedQuery);
  }
}

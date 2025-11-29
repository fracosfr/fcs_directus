import '../core/directus_http_client.dart';
import '../models/directus_filter.dart';
import 'items_service.dart';

/// Service pour gérer les opérations dans Directus.
///
/// Les opérations sont des actions exécutées dans les flows.
///
/// Exemple d'utilisation:
/// ```dart
/// // Récupérer toutes les opérations
/// final operations = await client.operations.getOperations();
///
/// // Créer une nouvelle opération
/// final operation = await client.operations.createOperation({
///   'name': 'Send Email',
///   'key': 'send_email',
///   'type': 'mail',
///   'options': {...},
/// });
///
/// // Récupérer les opérations d'un flow
/// final flowOps = await client.operations.getFlowOperations(flow-id);
/// ```
class OperationsService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  OperationsService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_operations');
  }

  /// Récupère la liste de toutes les opérations
  Future<DirectusResponse<dynamic>> getOperations({
    QueryParameters? query,
  }) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère une opération par son ID
  Future<Map<String, dynamic>> getOperation(
    String id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id, query: query);
  }

  /// Crée une nouvelle opération
  Future<Map<String, dynamic>> createOperation(
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.createOne(data);
  }

  /// Met à jour une opération existante
  Future<Map<String, dynamic>> updateOperation(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Supprime une opération
  Future<void> deleteOperation(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Supprime plusieurs opérations
  Future<void> deleteOperations(List<String> ids) async {
    await _itemsService.deleteMany(keys: ids);
  }

  // === Méthodes helper ===

  /// Récupère les opérations d'un flow spécifique
  Future<DirectusResponse<dynamic>> getFlowOperations(
    String flowId, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('flow').equals(flowId);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['position'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getOperations(query: mergedQuery);
  }

  /// Récupère les opérations par type
  Future<DirectusResponse<dynamic>> getOperationsByType(
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
    return await getOperations(query: mergedQuery);
  }

  /// Récupère les opérations résolues (trigger) d'un flow
  Future<DirectusResponse<dynamic>> getResolveOperations(
    String flowId, {
    QueryParameters? query,
  }) async {
    final filter = Filter.and([
      Filter.field('flow').equals(flowId),
      Filter.field('resolve').isNotNull(),
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
    return await getOperations(query: mergedQuery);
  }
}

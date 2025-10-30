import '../core/directus_http_client.dart';
import 'items_service.dart';

/// Service pour gérer les flows (flux) dans Directus.
///
/// Les flows permettent le traitement de données personnalisé et l'automatisation
/// de tâches basées sur des événements.
///
/// Exemple d'utilisation:
/// ```dart
/// // Créer un flow
/// await client.flows.createFlow({
///   'name': 'Update Articles Flow',
///   'icon': 'bolt',
///   'status': 'active',
///   'trigger': 'manual',
/// });
///
/// // Récupérer tous les flows
/// final flows = await client.flows.getFlows();
///
/// // Déclencher un flow avec webhook
/// await client.flows.triggerFlow('flow-id', {'data': 'payload'});
/// ```
class FlowsService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  FlowsService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_flows');
  }

  /// Récupère la liste de tous les flows
  ///
  /// [query] Paramètres de requête optionnels (filtres, tri, pagination, etc.)
  ///
  /// Exemple:
  /// ```dart
  /// final activeFlows = await client.flows.getFlows(
  ///   query: QueryParameters(
  ///     filter: Filter.field('status').equals('active'),
  ///     sort: ['name'],
  ///   ),
  /// );
  /// ```
  Future<DirectusResponse<dynamic>> getFlows({QueryParameters? query}) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère un flow par son ID
  ///
  /// [id] ID du flow
  /// [query] Paramètres de requête optionnels
  Future<Map<String, dynamic>> getFlow(
    String id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id, query: query);
  }

  /// Crée un nouveau flow
  ///
  /// [data] Données du flow (name, icon, status, trigger, accountability, options, operation)
  ///
  /// Types de triggers possibles:
  /// - manual: Déclenchement manuel
  /// - webhook: Déclenchement par webhook
  /// - event: Déclenchement par événement
  /// - schedule: Déclenchement programmé
  /// - operation: Déclenchement par opération
  ///
  /// Exemple:
  /// ```dart
  /// final newFlow = await client.flows.createFlow({
  ///   'name': 'Email Notification Flow',
  ///   'icon': 'email',
  ///   'status': 'active',
  ///   'trigger': 'event',
  ///   'accountability': 'all',
  ///   'options': {
  ///     'type': 'action',
  ///     'scope': ['items.create'],
  ///     'collections': ['articles'],
  ///   },
  /// });
  /// ```
  Future<Map<String, dynamic>> createFlow(Map<String, dynamic> data) async {
    return await _itemsService.createOne(data);
  }

  /// Crée plusieurs flows en une seule requête
  ///
  /// [flows] Liste des flows à créer
  Future<List<dynamic>> createFlows(List<Map<String, dynamic>> flows) async {
    return await _itemsService.createMany(flows);
  }

  /// Met à jour un flow existant
  ///
  /// [id] ID du flow à mettre à jour
  /// [data] Nouvelles données
  ///
  /// Exemple:
  /// ```dart
  /// await client.flows.updateFlow('flow-id', {
  ///   'status': 'inactive',
  ///   'name': 'Flow désactivé',
  /// });
  /// ```
  Future<Map<String, dynamic>> updateFlow(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Met à jour plusieurs flows en une seule requête
  ///
  /// [ids] Liste des IDs des flows à mettre à jour
  /// [data] Données à appliquer à tous les flows
  Future<List<dynamic>> updateFlows(
    List<String> ids,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateMany(ids, data);
  }

  /// Supprime un flow
  ///
  /// [id] ID du flow à supprimer
  Future<void> deleteFlow(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Supprime plusieurs flows en une seule requête
  ///
  /// [ids] Liste des IDs des flows à supprimer
  Future<void> deleteFlows(List<String> ids) async {
    await _itemsService.deleteMany(ids);
  }

  /// Déclenche un flow avec un webhook GET
  ///
  /// [id] ID du flow à déclencher
  /// [fields] Champs à retourner (optionnel)
  /// [meta] Métadonnées à retourner (optionnel)
  ///
  /// Le flow doit avoir un trigger de type 'webhook'.
  ///
  /// Exemple:
  /// ```dart
  /// final result = await client.flows.triggerFlowGet('flow-id');
  /// print('Résultat: ${result['data']}');
  /// ```
  Future<Map<String, dynamic>> triggerFlowGet(
    String id, {
    List<String>? fields,
    String? meta,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fields != null) queryParams['fields'] = fields.join(',');
    if (meta != null) queryParams['meta'] = meta;

    final response = await _httpClient.get(
      '/flows/trigger/$id',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Déclenche un flow avec un webhook POST
  ///
  /// [id] ID du flow à déclencher
  /// [data] Payload à envoyer au flow
  /// [fields] Champs à retourner (optionnel)
  /// [meta] Métadonnées à retourner (optionnel)
  ///
  /// Le flow doit avoir un trigger de type 'webhook'.
  ///
  /// Exemple:
  /// ```dart
  /// final result = await client.flows.triggerFlow('flow-id', {
  ///   'article_id': '123',
  ///   'action': 'publish',
  /// });
  /// ```
  Future<Map<String, dynamic>> triggerFlow(
    String id,
    Map<String, dynamic> data, {
    List<String>? fields,
    String? meta,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fields != null) queryParams['fields'] = fields.join(',');
    if (meta != null) queryParams['meta'] = meta;

    final response = await _httpClient.post(
      '/flows/trigger/$id',
      data: data,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Récupère les flows par type de trigger
  ///
  /// [trigger] Type de trigger (manual, webhook, event, schedule, operation)
  /// [query] Paramètres de requête optionnels
  Future<DirectusResponse<dynamic>> getFlowsByTrigger(
    String trigger, {
    QueryParameters? query,
  }) async {
    final mergedQuery = query ?? QueryParameters();
    final filter = mergedQuery.filter ?? {};
    filter['trigger'] = {'_eq': trigger};

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

  /// Récupère uniquement les flows actifs
  ///
  /// [query] Paramètres de requête optionnels
  Future<DirectusResponse<dynamic>> getActiveFlows({
    QueryParameters? query,
  }) async {
    final mergedQuery = query ?? QueryParameters();
    final filter = mergedQuery.filter ?? {};
    filter['status'] = {'_eq': 'active'};

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

import '../core/directus_http_client.dart';
import '../models/directus_filter.dart';
import 'items_service.dart';

/// Service pour gérer les révisions dans Directus.
///
/// Les révisions enregistrent les modifications apportées aux items.
///
/// Exemple d'utilisation:
/// ```dart
/// // Récupérer les révisions d'un item
/// final revisions = await client.revisions.getRevisions(
///   query: QueryParameters(
///     filter: Filter.and([
///       Filter.field('collection').equals('articles'),
///       Filter.field('item').equals('15'),
///     ]),
///     sort: ['-id'],
///   ),
/// );
///
/// // Récupérer une révision spécifique
/// final revision = await client.revisions.getRevision(revision-id);
/// ```
class RevisionsService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  RevisionsService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_revisions');
  }

  /// Récupère la liste de toutes les révisions
  Future<DirectusResponse<dynamic>> getRevisions({
    QueryParameters? query,
  }) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère une révision par son ID
  Future<Map<String, dynamic>> getRevision(
    int id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id.toString(), query: query);
  }

  // === Méthodes helper ===

  /// Récupère les révisions d'un item spécifique
  Future<DirectusResponse<dynamic>> getItemRevisions(
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
      sort: query?.sort ?? ['-id'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getRevisions(query: mergedQuery);
  }

  /// Récupère les révisions d'une collection
  Future<DirectusResponse<dynamic>> getCollectionRevisions(
    String collection, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('collection').equals(collection);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['-id'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getRevisions(query: mergedQuery);
  }
}

import '../core/directus_http_client.dart';
import '../models/directus_filter.dart';
import 'items_service.dart';

/// Service pour gérer les notifications dans Directus.
///
/// Les notifications permettent d'envoyer des messages aux utilisateurs.
///
/// Exemple d'utilisation:
/// ```dart
/// // Récupérer les notifications inbox
/// final notifications = await client.notifications.getNotifications(
///   query: QueryParameters(
///     filter: Filter.field('status').equals('inbox'),
///     sort: ['-timestamp'],
///   ),
/// );
///
/// // Marquer comme archivée
/// await client.notifications.updateNotification(
///   'notification-id',
///   {'status': 'archived'},
/// );
/// ```
class NotificationsService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  NotificationsService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_notifications');
  }

  /// Récupère la liste de toutes les notifications
  Future<DirectusResponse<dynamic>> getNotifications({
    QueryParameters? query,
  }) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère une notification par son ID
  Future<Map<String, dynamic>> getNotification(
    int id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id.toString(), query: query);
  }

  /// Crée une nouvelle notification
  Future<Map<String, dynamic>> createNotification(
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.createOne(data);
  }

  /// Crée plusieurs notifications en une seule requête
  Future<List<dynamic>> createNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    return await _itemsService.createMany(notifications);
  }

  /// Met à jour une notification existante
  Future<Map<String, dynamic>> updateNotification(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Met à jour plusieurs notifications
  Future<List<dynamic>> updateNotifications(
    List<String> ids,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateMany(keys: ids, data: data);
  }

  /// Supprime une notification
  Future<void> deleteNotification(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Supprime plusieurs notifications
  Future<void> deleteNotifications(List<String> ids) async {
    await _itemsService.deleteMany(keys: ids);
  }

  // === Méthodes helper ===

  /// Récupère les notifications dans l'inbox
  Future<DirectusResponse<dynamic>> getInboxNotifications({
    QueryParameters? query,
  }) async {
    final filter = Filter.field('status').equals('inbox');
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter as Filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['-timestamp'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getNotifications(query: mergedQuery);
  }

  /// Récupère les notifications archivées
  Future<DirectusResponse<dynamic>> getArchivedNotifications({
    QueryParameters? query,
  }) async {
    final filter = Filter.field('status').equals('archived');
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter as Filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['-timestamp'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getNotifications(query: mergedQuery);
  }

  /// Récupère les notifications d'un utilisateur
  Future<DirectusResponse<dynamic>> getUserNotifications(
    String userId, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('recipient').equals(userId);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter as Filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['-timestamp'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getNotifications(query: mergedQuery);
  }

  /// Archive une notification
  Future<Map<String, dynamic>> archiveNotification(String id) async {
    return await updateNotification(id, {'status': 'archived'});
  }

  /// Archive plusieurs notifications
  Future<List<dynamic>> archiveNotifications(List<String> ids) async {
    return await updateNotifications(ids, {'status': 'archived'});
  }
}

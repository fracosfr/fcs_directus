import '../core/directus_http_client.dart';
import '../models/directus_filter.dart';
import 'items_service.dart';

/// Service pour gérer les activités Directus.
///
/// Permet de consulter l'historique des actions effectuées dans Directus :
/// - Lecture des activités (list, single)
/// - Filtrage par action, utilisateur, collection, etc.
/// - Consultation des révisions associées
///
/// **Note**: Les activités sont en lecture seule. Directus les crée automatiquement
/// lors des actions CRUD sur les items.
///
/// Exemple d'utilisation :
/// ```dart
/// final activity = client.activity;
///
/// // Récupérer les activités récentes
/// final recent = await activity.getActivities(
///   query: QueryParameters(
///     sort: ['-timestamp'],
///     limit: 50,
///   ),
/// );
///
/// // Filtrer par type d'action
/// final creates = await activity.getActivities(
///   query: QueryParameters(
///     filter: Filter.field('action').equals('create'),
///   ),
/// );
///
/// // Activités d'un utilisateur spécifique
/// final userActivities = await activity.getActivities(
///   query: QueryParameters(
///     filter: Filter.field('user').equals('user-id'),
///     deep: Deep({
///       'user': DeepQuery().fields(['id', 'first_name', 'last_name', 'email']),
///     }),
///   ),
/// );
///
/// // Activités d'une collection spécifique
/// final collectionActivities = await activity.getActivities(
///   query: QueryParameters(
///     filter: Filter.field('collection').equals('articles'),
///   ),
/// );
///
/// // Récupérer une activité par son ID avec ses révisions
/// final single = await activity.getActivity(
///   'activity-id',
///   query: QueryParameters(
///     deep: Deep({
///       'revisions': DeepQuery().allFields(),
///     }),
///   ),
/// );
/// ```
class ActivityService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  ActivityService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_activity');
  }

  // ========================================
  // Opérations de lecture
  // ========================================

  /// Récupère la liste des activités
  ///
  /// Supporte tous les paramètres de query (filter, sort, fields, deep, etc.)
  ///
  /// **Filtres utiles:**
  /// - `action`: Type d'action (create, update, delete, login)
  /// - `user`: ID de l'utilisateur
  /// - `collection`: Nom de la collection
  /// - `item`: ID de l'item
  /// - `timestamp`: Date de l'action
  ///
  /// **Tris recommandés:**
  /// - `-timestamp`: Plus récent en premier
  /// - `timestamp`: Plus ancien en premier
  /// - `-id`: Par ID décroissant
  ///
  /// Exemple:
  /// ```dart
  /// // Activités de création des 7 derniers jours
  /// final recentCreates = await activity.getActivities(
  ///   query: QueryParameters(
  ///     filter: Filter.and([
  ///       Filter.field('action').equals('create'),
  ///       Filter.field('timestamp').greaterThan(
  ///         DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
  ///       ),
  ///     ]),
  ///     sort: ['-timestamp'],
  ///     limit: 100,
  ///   ),
  /// );
  /// ```
  Future<DirectusResponse<dynamic>> getActivities({
    QueryParameters? query,
  }) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère une activité par son ID
  ///
  /// Exemple:
  /// ```dart
  /// // Avec les détails de l'utilisateur et les révisions
  /// final activity = await activity.getActivity(
  ///   'activity-id',
  ///   query: QueryParameters(
  ///     deep: Deep({
  ///       'user': DeepQuery().fields(['first_name', 'last_name', 'email']),
  ///       'revisions': DeepQuery().allFields(),
  ///     }),
  ///   ),
  /// );
  /// ```
  Future<Map<String, dynamic>> getActivity(
    String id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id, query: query);
  }

  // ========================================
  // Méthodes helper pour filtres courants
  // ========================================

  /// Récupère les activités d'un utilisateur spécifique
  ///
  /// Exemple:
  /// ```dart
  /// final userActivities = await activity.getUserActivities(
  ///   'user-123',
  ///   limit: 50,
  /// );
  /// ```
  Future<DirectusResponse<dynamic>> getUserActivities(
    String userId, {
    int? limit,
    List<String>? sort,
    QueryParameters? additionalQuery,
  }) async {
    final query = QueryParameters(
      filter: Filter.field('user').equals(userId),
      limit: limit ?? 50,
      sort: sort ?? ['-timestamp'],
    );

    // Fusionner avec la query additionnelle si fournie
    if (additionalQuery != null) {
      return await _itemsService.readMany(
        query: QueryParameters(
          filter: additionalQuery.filter != null
              ? Filter.and([query.filter!, additionalQuery.filter!])
              : query.filter,
          limit: additionalQuery.limit ?? query.limit,
          sort: additionalQuery.sort ?? query.sort,
          fields: additionalQuery.fields,
          deep: additionalQuery.deep,
          offset: additionalQuery.offset,
        ),
      );
    }

    return await _itemsService.readMany(query: query);
  }

  /// Récupère les activités d'une collection spécifique
  ///
  /// Exemple:
  /// ```dart
  /// final articleActivities = await activity.getCollectionActivities(
  ///   'articles',
  ///   actionType: 'create',
  /// );
  /// ```
  Future<DirectusResponse<dynamic>> getCollectionActivities(
    String collectionName, {
    String? actionType,
    int? limit,
    List<String>? sort,
    QueryParameters? additionalQuery,
  }) async {
    final filters = <Filter>[Filter.field('collection').equals(collectionName)];

    if (actionType != null) {
      filters.add(Filter.field('action').equals(actionType));
    }

    final query = QueryParameters(
      filter: filters.length > 1 ? Filter.and(filters) : filters.first,
      limit: limit ?? 50,
      sort: sort ?? ['-timestamp'],
    );

    // Fusionner avec la query additionnelle si fournie
    if (additionalQuery != null) {
      return await _itemsService.readMany(
        query: QueryParameters(
          filter: additionalQuery.filter != null
              ? Filter.and([query.filter!, additionalQuery.filter!])
              : query.filter,
          limit: additionalQuery.limit ?? query.limit,
          sort: additionalQuery.sort ?? query.sort,
          fields: additionalQuery.fields,
          deep: additionalQuery.deep,
          offset: additionalQuery.offset,
        ),
      );
    }

    return await _itemsService.readMany(query: query);
  }

  /// Récupère les activités d'un item spécifique
  ///
  /// Exemple:
  /// ```dart
  /// final itemHistory = await activity.getItemActivities(
  ///   collection: 'articles',
  ///   itemId: 'article-123',
  /// );
  /// ```
  Future<DirectusResponse<dynamic>> getItemActivities(
    String itemId, {
    required String collection,
    int? limit,
    List<String>? sort,
    QueryParameters? additionalQuery,
  }) async {
    final query = QueryParameters(
      filter: Filter.and([
        Filter.field('collection').equals(collection),
        Filter.field('item').equals(itemId),
      ]),
      limit: limit ?? 50,
      sort: sort ?? ['-timestamp'],
    );

    // Fusionner avec la query additionnelle si fournie
    if (additionalQuery != null) {
      return await _itemsService.readMany(
        query: QueryParameters(
          filter: additionalQuery.filter != null
              ? Filter.and([query.filter!, additionalQuery.filter!])
              : query.filter,
          limit: additionalQuery.limit ?? query.limit,
          sort: additionalQuery.sort ?? query.sort,
          fields: additionalQuery.fields,
          deep: additionalQuery.deep,
          offset: additionalQuery.offset,
        ),
      );
    }

    return await _itemsService.readMany(query: query);
  }

  /// Récupère les activités par type d'action
  ///
  /// Types d'action valides : 'create', 'update', 'delete', 'login'
  ///
  /// Exemple:
  /// ```dart
  /// // Toutes les connexions récentes
  /// final logins = await activity.getActivitiesByAction('login', limit: 100);
  ///
  /// // Toutes les suppressions
  /// final deletes = await activity.getActivitiesByAction('delete');
  /// ```
  Future<DirectusResponse<dynamic>> getActivitiesByAction(
    String action, {
    int? limit,
    List<String>? sort,
    QueryParameters? additionalQuery,
  }) async {
    final query = QueryParameters(
      filter: Filter.field('action').equals(action),
      limit: limit ?? 50,
      sort: sort ?? ['-timestamp'],
    );

    // Fusionner avec la query additionnelle si fournie
    if (additionalQuery != null) {
      return await _itemsService.readMany(
        query: QueryParameters(
          filter: additionalQuery.filter != null
              ? Filter.and([query.filter!, additionalQuery.filter!])
              : query.filter,
          limit: additionalQuery.limit ?? query.limit,
          sort: additionalQuery.sort ?? query.sort,
          fields: additionalQuery.fields,
          deep: additionalQuery.deep,
          offset: additionalQuery.offset,
        ),
      );
    }

    return await _itemsService.readMany(query: query);
  }

  /// Récupère les activités récentes (dernières 24 heures par défaut)
  ///
  /// Exemple:
  /// ```dart
  /// // Activités des dernières 24 heures
  /// final today = await activity.getRecentActivities();
  ///
  /// // Activités de la dernière semaine
  /// final week = await activity.getRecentActivities(
  ///   since: DateTime.now().subtract(Duration(days: 7)),
  /// );
  /// ```
  Future<DirectusResponse<dynamic>> getRecentActivities({
    DateTime? since,
    int? limit,
    List<String>? sort,
    QueryParameters? additionalQuery,
  }) async {
    final sinceDate = since ?? DateTime.now().subtract(const Duration(days: 1));

    final query = QueryParameters(
      filter: Filter.field(
        'timestamp',
      ).greaterThan(sinceDate.toIso8601String()),
      limit: limit ?? 100,
      sort: sort ?? ['-timestamp'],
    );

    // Fusionner avec la query additionnelle si fournie
    if (additionalQuery != null) {
      return await _itemsService.readMany(
        query: QueryParameters(
          filter: additionalQuery.filter != null
              ? Filter.and([query.filter!, additionalQuery.filter!])
              : query.filter,
          limit: additionalQuery.limit ?? query.limit,
          sort: additionalQuery.sort ?? query.sort,
          fields: additionalQuery.fields,
          deep: additionalQuery.deep,
          offset: additionalQuery.offset,
        ),
      );
    }

    return await _itemsService.readMany(query: query);
  }
}

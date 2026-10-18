import '../core/directus_http_client.dart';
import '../models/directus_filter.dart';
import '../models/directus_share.dart';
import 'items_service.dart';
import 'system_items_service.dart';

/// Service pour gérer les partages (shares) dans Directus.
///
/// Les shares permettent de partager des collections ou des items
/// avec des utilisateurs externes via des liens sécurisés.
///
/// Exemple d'utilisation:
/// ```dart
/// // Créer un partage pour une collection
/// final share = await client.shares.createShare({
///   'collection': 'articles',
///   'item': 'article-id',
///   'password': 'secret123',
///   'date_end': '2025-12-31T23:59:59Z',
/// });
/// print('Lien de partage: ${share['id']}');
///
/// // Récupérer un partage
/// final shareInfo = await client.shares.getShare(share-id);
///
/// // Supprimer un partage
/// await client.shares.deleteShare(share-id);
/// ```
class SharesService extends DirectusSystemService<DirectusShare> {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  SharesService(this._httpClient)
    : super(_httpClient, 'directus_shares', DirectusShare.factory) {
    _itemsService = ItemsService(_httpClient, 'directus_shares');
  }

  /// Récupère la liste de tous les partages
  Future<DirectusResponse<dynamic>> getShares({QueryParameters? query}) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère un partage par son ID
  Future<Map<String, dynamic>> getShare(
    String id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id, query: query);
  }

  /// Crée un nouveau partage
  ///
  /// [data] Données du partage:
  /// - collection: Collection partagée (requis)
  /// - item: ID de l'item partagé (requis)
  /// - role: Rôle utilisé pour l'accès
  /// - password: Mot de passe optionnel pour protéger l'accès
  /// - user_created: Utilisateur créateur
  /// - date_created: Date de création
  /// - date_start: Date de début de validité
  /// - date_end: Date de fin de validité
  /// - times_used: Nombre de fois utilisé (lecture seule)
  /// - max_uses: Nombre maximum d'utilisations
  Future<Map<String, dynamic>> createShare(Map<String, dynamic> data) async {
    return await _itemsService.createOne(data);
  }

  /// Met à jour un partage existant
  Future<Map<String, dynamic>> updateShare(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Supprime un partage
  Future<void> deleteShare(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Supprime plusieurs partages
  Future<void> deleteShares(List<String> ids) async {
    await _itemsService.deleteMany(keys: ids);
  }

  // === Méthodes helper ===

  /// Récupère les partages d'une collection spécifique
  Future<DirectusResponse<dynamic>> getCollectionShares(
    String collection, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('collection').equals(collection);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['-date_created'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getShares(query: mergedQuery);
  }

  /// Récupère les partages d'un item spécifique
  Future<DirectusResponse<dynamic>> getItemShares(
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
      sort: query?.sort ?? ['-date_created'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getShares(query: mergedQuery);
  }

  /// Récupère les partages actifs (non expirés)
  Future<DirectusResponse<dynamic>> getActiveShares({
    QueryParameters? query,
  }) async {
    final now = DateTime.now().toIso8601String();
    final filter = Filter.or([
      Filter.field('date_end').isNull(),
      Filter.field('date_end').greaterThan(now),
    ]);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['-date_created'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getShares(query: mergedQuery);
  }

  /// Récupère les partages créés par un utilisateur
  Future<DirectusResponse<dynamic>> getUserShares(
    String userId, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('user_created').equals(userId);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['-date_created'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getShares(query: mergedQuery);
  }

  /// Authentifie un visiteur sur un partage (`POST /shares/auth`).
  ///
  /// Retourne `{access_token, refresh_token, expires}` (mode json). Pour agir
  /// avec ce jeton, utiliser `client.auth.loginWithToken(accessToken)`.
  Future<Map<String, dynamic>> authenticate({
    required String shareId,
    String? password,
    String mode = 'json',
  }) async {
    final response = await _httpClient.post(
      '/shares/auth',
      data: {
        'share': shareId,
        if (password != null) 'password': password,
        'mode': mode,
      },
    );
    return Map<String, dynamic>.from(response.data?['data'] as Map? ?? {});
  }

  /// Envoie le lien de partage par email (`POST /shares/invite`).
  Future<void> invite({
    required String shareId,
    required List<String> emails,
  }) async {
    await _httpClient.post(
      '/shares/invite',
      data: {'share': shareId, 'emails': emails},
    );
  }

  /// Informations publiques d'un partage, sans authentification
  /// (`GET /shares/info/{id}`).
  Future<DirectusShare> info(String shareId) async {
    final response = await _httpClient.get('/shares/info/$shareId');
    return DirectusShare(response.data['data'] as Map<String, dynamic>);
  }
}

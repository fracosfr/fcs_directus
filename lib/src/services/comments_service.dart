import '../core/directus_http_client.dart';
import 'items_service.dart';

/// Service pour gérer les commentaires dans Directus.
///
/// Les commentaires sont un outil de collaboration qui peut être laissé sur les items
/// depuis la barre latérale. Cette action est uniquement disponible pour les utilisateurs authentifiés.
///
/// Exemple d'utilisation:
/// ```dart
/// // Créer un commentaire
/// await client.comments.createComment(
///   collection: 'articles',
///   item: '15',
///   comment: 'Ceci est un commentaire sur un article',
/// );
///
/// // Récupérer tous les commentaires
/// final comments = await client.comments.getComments();
///
/// // Récupérer un commentaire spécifique
/// final comment = await client.comments.getComment('comment-id');
/// ```
class CommentsService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  CommentsService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_comments');
  }

  /// Récupère la liste de tous les commentaires
  ///
  /// [query] Paramètres de requête optionnels (filtres, tri, pagination, etc.)
  ///
  /// Exemple:
  /// ```dart
  /// final comments = await client.comments.getComments(
  ///   query: QueryParameters(
  ///     filter: Filter.field('collection').equals('articles'),
  ///     sort: ['-date_created'],
  ///     limit: 20,
  ///   ),
  /// );
  /// ```
  Future<DirectusResponse<dynamic>> getComments({
    QueryParameters? query,
  }) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère un commentaire par son ID
  ///
  /// [id] ID du commentaire
  /// [query] Paramètres de requête optionnels
  Future<Map<String, dynamic>> getComment(
    String id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id, query: query);
  }

  /// Crée un nouveau commentaire
  ///
  /// [collection] Nom de la collection contenant l'item
  /// [item] ID de l'item à commenter
  /// [comment] Texte du commentaire
  ///
  /// Exemple:
  /// ```dart
  /// final newComment = await client.comments.createComment(
  ///   collection: 'articles',
  ///   item: '15',
  ///   comment: 'Excellent article!',
  /// );
  /// ```
  Future<Map<String, dynamic>> createComment({
    required String collection,
    required String item,
    required String comment,
  }) async {
    return await _itemsService.createOne({
      'collection': collection,
      'item': item,
      'comment': comment,
    });
  }

  /// Crée plusieurs commentaires en une seule requête
  ///
  /// [comments] Liste des commentaires à créer
  ///
  /// Chaque commentaire doit contenir: collection, item, comment
  Future<List<dynamic>> createComments(
    List<Map<String, dynamic>> comments,
  ) async {
    return await _itemsService.createMany(comments);
  }

  /// Met à jour un commentaire existant
  ///
  /// [id] ID du commentaire à mettre à jour
  /// [data] Nouvelles données (généralement le champ 'comment')
  ///
  /// Exemple:
  /// ```dart
  /// await client.comments.updateComment(
  ///   'comment-id',
  ///   {'comment': 'Commentaire mis à jour'},
  /// );
  /// ```
  Future<Map<String, dynamic>> updateComment(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Met à jour plusieurs commentaires en une seule requête
  ///
  /// [ids] Liste des IDs des commentaires à mettre à jour
  /// [data] Données à appliquer à tous les commentaires
  Future<List<dynamic>> updateComments(
    List<String> ids,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateMany(ids, data);
  }

  /// Supprime un commentaire
  ///
  /// [id] ID du commentaire à supprimer
  Future<void> deleteComment(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Supprime plusieurs commentaires en une seule requête
  ///
  /// [ids] Liste des IDs des commentaires à supprimer
  Future<void> deleteComments(List<String> ids) async {
    await _itemsService.deleteMany(ids);
  }

  /// Récupère les commentaires pour un item spécifique
  ///
  /// [collection] Nom de la collection
  /// [itemId] ID de l'item
  /// [query] Paramètres de requête optionnels
  ///
  /// Exemple:
  /// ```dart
  /// final itemComments = await client.comments.getCommentsForItem(
  ///   'articles',
  ///   '15',
  ///   query: QueryParameters(sort: ['-date_created']),
  /// );
  /// ```
  Future<DirectusResponse<dynamic>> getCommentsForItem(
    String collection,
    String itemId, {
    QueryParameters? query,
  }) async {
    final mergedQuery = query ?? QueryParameters();
    // Fusionner le filtre avec les filtres existants
    final filter = mergedQuery.filter ?? {};
    filter['collection'] = {'_eq': collection};
    filter['item'] = {'_eq': itemId};

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

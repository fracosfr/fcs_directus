import '../core/directus_http_client.dart';
import '../models/directus_model.dart';
import 'item_active_service.dart';
import 'items_service.dart';

/// Base des services de collections système en lecture seule
/// (`directus_activity`, `directus_revisions`, ...).
///
/// Fournit une API orientée objet : les méthodes retournent des instances du
/// modèle [T] (ex: `DirectusActivity`) plutôt que des `Map`.
///
/// La factory du modèle est enregistrée automatiquement si aucune factory
/// n'existe déjà pour [T] : un développeur peut donc la remplacer par la sienne
/// (sous-classe) via `DirectusModel.registerFactory<T>(...)`.
///
/// ```dart
/// final page = await client.activity.readMany(
///   query: QueryParameters(limit: 10, sort: ['-timestamp']),
/// );
/// for (final activity in page.data) {
///   print(activity.action.value);
/// }
/// ```
abstract class DirectusReadOnlySystemService<T extends DirectusModel> {
  /// Service typé sous-jacent (routé vers l'endpoint système de [collection]).
  final ItemActiveService<T> active;

  DirectusReadOnlySystemService(
    DirectusHttpClient httpClient,
    String collection,
    T Function(Map<String, dynamic>) factory,
  ) : active = ItemActiveService<T>(httpClient, collection) {
    if (DirectusModel.getFactory<T>() == null) {
      DirectusModel.registerFactory<T>(factory);
    }
  }

  /// Nom de la collection système (ex: `directus_comments`).
  String get collection => active.collection;

  /// Récupère plusieurs éléments typés.
  Future<DirectusResponse<T>> readMany({QueryParameters? query}) =>
      active.readMany(query: query);

  /// Récupère un élément typé par son identifiant.
  Future<T> readOne(String id, {QueryParameters? query}) =>
      active.readOne(id, query: query);
}

/// Base des services de collections système en lecture/écriture
/// (`directus_comments`, `directus_flows`, `directus_files`, ...).
///
/// ```dart
/// final comment = DirectusComment.empty()
///   ..collection.set('articles')
///   ..item.set('15')
///   ..comment.set('Relu et validé');
/// final created = await client.comments.createOne(comment);
///
/// created!.comment.set('Relu, validé et publié');
/// await client.comments.updateOne(created); // n'envoie que les champs modifiés
///
/// await client.comments.deleteOne(created);
/// ```
abstract class DirectusSystemService<T extends DirectusModel>
    extends DirectusReadOnlySystemService<T> {
  DirectusSystemService(super.httpClient, super.collection, super.factory);

  /// Crée un élément et retourne le modèle créé.
  Future<T?> createOne(T model) => active.createOne(model);

  /// Crée plusieurs éléments en une requête.
  Future<List<T>> createMany(List<T> models) => active.createMany(models);

  /// Met à jour un élément (seuls les champs modifiés sont envoyés).
  Future<T?> updateOne(T model) => active.updateOne(model);

  /// Applique les mêmes [data] à plusieurs éléments (par [keys], [filter] ou [query]).
  Future<List<T>> updateMany({
    List<String>? keys,
    required Map<String, dynamic> data,
    dynamic filter,
    Map<String, dynamic>? query,
  }) => active.updateMany(keys: keys, data: data, filter: filter, query: query);

  /// Supprime un élément.
  Future<void> deleteOne(T model) => active.deleteOne(model);

  /// Supprime plusieurs éléments (par [keys], [filter] ou [query]).
  Future<void> deleteMany({
    List<String>? keys,
    dynamic filter,
    Map<String, dynamic>? query,
  }) => active.deleteMany(keys: keys, filter: filter, query: query);
}

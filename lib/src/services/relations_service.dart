import '../core/directus_http_client.dart';
import '../models/directus_relation.dart';

/// Service pour gérer les relations entre collections (`/relations`).
///
/// Une relation est identifiée par le couple (collection, champ) qui porte
/// la clé étrangère, et non par un identifiant numérique.
///
/// Exemple d'utilisation:
/// ```dart
/// // Toutes les relations
/// final relations = await client.relations.readAll();
///
/// // Relations d'une collection
/// final articleRelations = await client.relations.readByCollection('articles');
///
/// // Une relation précise
/// final author = await client.relations.readOne('articles', 'author');
/// print(author.relatedCollection.value); // directus_users
///
/// // Créer une relation Many-to-One
/// await client.relations.create(DirectusRelation.empty()
///   ..collection.set('articles')
///   ..field.set('category')
///   ..relatedCollection.set('categories'));
///
/// // Supprimer
/// await client.relations.delete('articles', 'category');
/// ```
class RelationsService {
  final DirectusHttpClient _httpClient;

  RelationsService(this._httpClient);

  List<DirectusRelation> _list(dynamic data) => (data as List)
      .map((r) => DirectusRelation(r as Map<String, dynamic>))
      .toList();

  /// Liste toutes les relations (`GET /relations`).
  Future<List<DirectusRelation>> readAll() async {
    final response = await _httpClient.get('/relations');
    return _list(response.data['data']);
  }

  /// Liste les relations d'une collection (`GET /relations/{collection}`).
  Future<List<DirectusRelation>> readByCollection(String collection) async {
    final response = await _httpClient.get('/relations/$collection');
    return _list(response.data['data']);
  }

  /// Récupère la relation portée par [collection].[field]
  /// (`GET /relations/{collection}/{field}`).
  Future<DirectusRelation> readOne(String collection, String field) async {
    final response = await _httpClient.get('/relations/$collection/$field');
    return DirectusRelation(response.data['data'] as Map<String, dynamic>);
  }

  /// Crée une relation (`POST /relations`).
  Future<DirectusRelation> create(DirectusRelation relation) async {
    final response = await _httpClient.post(
      '/relations',
      data: relation.toJson(),
    );
    return DirectusRelation(response.data['data'] as Map<String, dynamic>);
  }

  /// Met à jour une relation (`PATCH /relations/{collection}/{field}`).
  ///
  /// Seuls les champs modifiés de [relation] sont envoyés (`meta`, `schema`...).
  Future<DirectusRelation> update(DirectusRelation relation) async {
    final response = await _httpClient.patch(
      '/relations/${relation.collection.value}/${relation.field.value}',
      data: relation.toJsonDirty(),
    );
    return DirectusRelation(response.data['data'] as Map<String, dynamic>);
  }

  /// Supprime une relation (`DELETE /relations/{collection}/{field}`).
  Future<void> delete(String collection, String field) async {
    await _httpClient.delete('/relations/$collection/$field');
  }

  // --- Anciennes signatures (conservées pour compatibilité) ---

  /// Liste brute des relations.
  @Deprecated('Utiliser readAll() qui retourne des DirectusRelation.')
  Future<List<Map<String, dynamic>>> getRelations() async {
    final response = await _httpClient.get('/relations');
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// Les relations n'ont pas d'identifiant numérique dans l'API.
  @Deprecated('Utiliser readOne(collection, field).')
  Future<Map<String, dynamic>> getRelation(int id) =>
      throw UnsupportedError('Utiliser readOne(collection, field).');

  /// Liste brute des relations d'une collection.
  @Deprecated('Utiliser readByCollection(collection).')
  Future<List<Map<String, dynamic>>> getRelationsByCollection(
    String collection,
  ) async {
    final response = await _httpClient.get('/relations/$collection');
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// Crée une relation depuis une Map.
  @Deprecated('Utiliser create(DirectusRelation).')
  Future<Map<String, dynamic>> createRelation(Map<String, dynamic> data) async {
    final response = await _httpClient.post('/relations', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Les relations n'ont pas d'identifiant numérique dans l'API.
  @Deprecated('Utiliser update(DirectusRelation).')
  Future<Map<String, dynamic>> updateRelation(
    int id,
    Map<String, dynamic> data,
  ) => throw UnsupportedError('Utiliser update(DirectusRelation).');

  /// Les relations n'ont pas d'identifiant numérique dans l'API.
  @Deprecated('Utiliser delete(collection, field).')
  Future<void> deleteRelation(int id) =>
      throw UnsupportedError('Utiliser delete(collection, field).');
}

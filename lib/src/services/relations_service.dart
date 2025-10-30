import '../core/directus_http_client.dart';

/// Service pour gérer les relations dans Directus.
///
/// Les relations définissent les connexions entre collections.
///
/// Exemple d'utilisation:
/// ```dart
/// // Récupérer toutes les relations
/// final relations = await client.relations.getRelations();
///
/// // Récupérer les relations d'une collection
/// final articleRelations = await client.relations.getRelationsByCollection('articles');
///
/// // Créer une relation Many-to-One
/// await client.relations.createRelation({
///   'many_collection': 'articles',
///   'many_field': 'author',
///   'one_collection': 'users',
/// });
/// ```
class RelationsService {
  final DirectusHttpClient _httpClient;

  RelationsService(this._httpClient);

  /// Récupère la liste de toutes les relations
  Future<dynamic> getRelations() async {
    return await _httpClient.get('/relations');
  }

  /// Récupère une relation par son ID
  Future<dynamic> getRelation(int id) async {
    return await _httpClient.get('/relations/$id');
  }

  /// Récupère les relations d'une collection spécifique
  Future<dynamic> getRelationsByCollection(String collection) async {
    return await _httpClient.get('/relations/$collection');
  }

  /// Crée une nouvelle relation
  Future<dynamic> createRelation(Map<String, dynamic> data) async {
    return await _httpClient.post('/relations', data: data);
  }

  /// Met à jour une relation existante
  Future<dynamic> updateRelation(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _httpClient.patch('/relations/$id', data: data);
  }

  /// Supprime une relation
  Future<void> deleteRelation(int id) async {
    await _httpClient.delete('/relations/$id');
  }
}

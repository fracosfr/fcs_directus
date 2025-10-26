import '../core/directus_http_client.dart';

/// Service pour gérer les collections Directus.
///
/// Permet de lister, créer, mettre à jour et supprimer des collections.
class CollectionsService {
  final DirectusHttpClient _httpClient;

  CollectionsService(this._httpClient);

  /// Récupère la liste de toutes les collections
  Future<List<Map<String, dynamic>>> getCollections() async {
    final response = await _httpClient.get('/collections');
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// Récupère les détails d'une collection
  ///
  /// [collection] Nom de la collection
  Future<Map<String, dynamic>> getCollection(String collection) async {
    final response = await _httpClient.get('/collections/$collection');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Crée une nouvelle collection
  ///
  /// [data] Configuration de la collection
  Future<Map<String, dynamic>> createCollection(
    Map<String, dynamic> data,
  ) async {
    final response = await _httpClient.post('/collections', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Met à jour une collection
  ///
  /// [collection] Nom de la collection
  /// [data] Nouvelles données de configuration
  Future<Map<String, dynamic>> updateCollection(
    String collection,
    Map<String, dynamic> data,
  ) async {
    final response = await _httpClient.patch(
      '/collections/$collection',
      data: data,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Supprime une collection
  ///
  /// [collection] Nom de la collection à supprimer
  Future<void> deleteCollection(String collection) async {
    await _httpClient.delete('/collections/$collection');
  }
}

import 'package:fcs_directus/src/models/directus_model.dart';

import '../core/directus_http_client.dart';
import 'items_service.dart';

class ItemActiveService<T extends DirectusModel> {
  final DirectusHttpClient _httpClient;
  final String collection;

  ItemActiveService(this._httpClient, this.collection);

  /// Récupère plusieurs items sous forme de modèle typé T
  Future<DirectusResponse<T>> readMany({QueryParameters? query}) async {
    final response = await _httpClient.get(
      '/items/$collection',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data['data'] as List;
    final meta = response.data['meta'] != null
        ? DirectusMeta.fromJson(response.data['meta'] as Map<String, dynamic>)
        : null;

    final T Function(Map<String, dynamic>) resolvedFactory = _getModelFactory();
    final items = data
        .map((item) => resolvedFactory(item as Map<String, dynamic>))
        .toList();
    return DirectusResponse(data: items, meta: meta);
  }

  /// Récupère un item par son ID et le retourne en modèle typé T
  Future<T> readOne(String id, {QueryParameters? query}) async {
    final response = await _httpClient.get(
      '/items/$collection/$id',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final T Function(Map<String, dynamic>) resolvedFactory = _getModelFactory();
    return resolvedFactory(data);
  }

  /// Crée un nouvel item et retourne un modèle typé T
  Future<T?> createOne(T model) async {
    final response = await _httpClient.post(
      '/items/$collection',
      data: model.toJson(),
    );

    if (response.statusCode == 204) return null;

    final responseData = response.data['data'] as Map<String, dynamic>;
    final T Function(Map<String, dynamic>) resolvedFactory = _getModelFactory();
    return resolvedFactory(responseData);
  }

  /// Crée plusieurs nouveaux items et les retourne en modèles typés T
  Future<List<T>> createMany(List<T> models) async {
    final response = await _httpClient.post(
      '/items/$collection',
      data: models.map((m) => m.toJson()).toList(),
    );

    final responseData = response.data['data'] as List;
    final T Function(Map<String, dynamic>) resolvedFactory = _getModelFactory();
    return responseData
        .map((item) => resolvedFactory(item as Map<String, dynamic>))
        .toList();
  }

  Future<T> updateOne(T model) async {
    if (model.id == null) {
      throw ArgumentError('The model must have an ID to be updated.');
    }
    final response = await _httpClient.patch(
      '/items/$collection/${model.id}',
      data: model.toJsonDirty(),
    );

    final responseData = response.data['data'] as Map<String, dynamic>;
    final T Function(Map<String, dynamic>) resolvedFactory = _getModelFactory();
    return resolvedFactory(responseData);
  }

  /// Met à jour plusieurs items et les retourne en modèles typés T
  Future<List<T>> updateMany(List<T> models) async {
    if (models.any((m) => m.id == null)) {
      throw ArgumentError('All models must have an ID to be updated.');
    }
    if (models.isEmpty) {
      return [];
    }

    final payload = models.map((m) {
      final dirty = m.toJsonDirty();
      dirty['id'] = m.id;
      return dirty;
    }).toList();

    final response = await _httpClient.patch(
      '/items/$collection',
      data: payload,
    );

    final responseData = response.data['data'] as List;
    final T Function(Map<String, dynamic>) resolvedFactory = _getModelFactory();
    return responseData
        .map((item) => resolvedFactory(item as Map<String, dynamic>))
        .toList();
  }

  /// Supprime un item en utilisant son modèle
  Future<void> deleteOne(T model) async {
    if (model.id == null) {
      throw ArgumentError('The model must have an ID to be deleted.');
    }
    await _httpClient.delete('/items/$collection/${model.id}');
  }

  /// Supprime plusieurs items en utilisant leurs modèles
  Future<void> deleteMany(List<T> models) async {
    final ids = models.map((m) => m.id).whereType<String>().toList();
    if (ids.length != models.length) {
      throw ArgumentError('All models must have an ID to be deleted.');
    }
    if (ids.isEmpty) {
      return;
    }

    await _httpClient.delete(
      '/items/$collection',
      queryParameters: {
        'filter': {
          'id': {'_in': ids},
        },
      },
    );
  }

  /// Récupère le singleton sous forme de modèle typé T
  Future<T> readSingleton({QueryParameters? query}) async {
    final response = await _httpClient.get(
      '/items/$collection',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final T Function(Map<String, dynamic>) resolvedFactory = _getModelFactory();
    return resolvedFactory(data);
  }

  /// Met à jour le singleton et retourne un modèle typé T
  Future<T> updateSingleton(T model) async {
    final response = await _httpClient.patch(
      '/items/$collection',
      data: model.toJsonDirty(),
    );

    final responseData = response.data['data'] as Map<String, dynamic>;
    final T Function(Map<String, dynamic>) resolvedFactory = _getModelFactory();
    return resolvedFactory(responseData);
  }

  /// Récupère le factory du modèle T si disponible
  T Function(Map<String, dynamic>) _getModelFactory() {
    final factory = DirectusModel.getFactory<T>();

    if (factory == null) {
      throw StateError(
        'Aucune factory enregistrée pour le type $T. '
        'Veuillez enregistrer une factory avec `DirectusModel.registerFactory<$T>((data) => ...)` '
        'ou la fournir directement à la méthode.',
      );
    }

    return (data) => factory(data) as T;
  }
}

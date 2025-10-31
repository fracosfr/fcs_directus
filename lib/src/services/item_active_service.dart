import 'package:fcs_directus/src/models/directus_model.dart';

import '../core/directus_http_client.dart';
import 'items_service.dart';

class ItemActiveService<T extends DirectusModel> {
  final DirectusHttpClient _httpClient;
  final String collection;

  ItemActiveService(this._httpClient, this.collection);

  /// Récupère plusieurs items sous forme de modèle typé T
  Future<DirectusResponse<T>> readMany({
    T Function(Map<String, dynamic>)? factory,
    QueryParameters? query,
  }) async {
    final response = await _httpClient.get(
      '/items/$collection',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data['data'] as List;
    final meta = response.data['meta'] != null
        ? DirectusMeta.fromJson(response.data['meta'] as Map<String, dynamic>)
        : null;

    final T Function(Map<String, dynamic>) resolvedFactory =
        factory ?? _getModelFactory();
    final items = data
        .map((item) => resolvedFactory(item as Map<String, dynamic>))
        .toList();
    return DirectusResponse(data: items, meta: meta);
  }

  /// Récupère un item par son ID et le retourne en modèle typé T
  Future<T> readOne(
    String id, {
    T Function(Map<String, dynamic>)? factory,
    QueryParameters? query,
  }) async {
    final response = await _httpClient.get(
      '/items/$collection/$id',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final T Function(Map<String, dynamic>) resolvedFactory =
        factory ?? _getModelFactory();
    return resolvedFactory(data);
  }

  /// Crée un nouvel item et retourne un modèle typé T
  Future<T> createOne(
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? factory,
  }) async {
    final response = await _httpClient.post('/items/$collection', data: data);

    final responseData = response.data['data'] as Map<String, dynamic>;
    final T Function(Map<String, dynamic>) resolvedFactory =
        factory ?? _getModelFactory();
    return resolvedFactory(responseData);
  }

  /// Met à jour un item et retourne un modèle typé T
  Future<T> updateOne(
    String id,
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? factory,
  }) async {
    final response = await _httpClient.patch(
      '/items/$collection/$id',
      data: data,
    );

    final responseData = response.data['data'] as Map<String, dynamic>;
    final T Function(Map<String, dynamic>) resolvedFactory =
        factory ?? _getModelFactory();
    return resolvedFactory(responseData);
  }

  /// Récupère le singleton sous forme de modèle typé T
  Future<T> readSingleton({
    T Function(Map<String, dynamic>)? factory,
    QueryParameters? query,
  }) async {
    final response = await _httpClient.get(
      '/items/$collection',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final T Function(Map<String, dynamic>) resolvedFactory =
        factory ?? _getModelFactory();
    return resolvedFactory(data);
  }

  /// Met à jour le singleton et retourne un modèle typé T
  Future<T> updateSingleton(
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? factory,
  }) async {
    final response = await _httpClient.patch('/items/$collection', data: data);

    final responseData = response.data['data'] as Map<String, dynamic>;
    final T Function(Map<String, dynamic>) resolvedFactory =
        factory ?? _getModelFactory();
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

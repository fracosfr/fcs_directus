import 'package:fcs_directus/src/models/directus_model.dart';

import '../core/directus_http_client.dart';
import '../models/directus_filter.dart';
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

    // Directus peut retourner 204 No Content sans body
    if (response.data == null || !response.data!.containsKey('data')) {
      return null;
    }

    final responseData = response.data!['data'] as Map<String, dynamic>;
    final T Function(Map<String, dynamic>) resolvedFactory = _getModelFactory();
    return resolvedFactory(responseData);
  }

  /// Crée plusieurs nouveaux items et les retourne en modèles typés T
  Future<List<T>> createMany(List<T> models) async {
    final response = await _httpClient.post(
      '/items/$collection',
      data: models.map((m) => m.toJson()).toList(),
    );

    final responseData = (response.data?['data'] ?? []) as List;
    final T Function(Map<String, dynamic>) resolvedFactory = _getModelFactory();
    return responseData
        .map((item) => resolvedFactory(item as Map<String, dynamic>))
        .toList();
  }

  Future<T?> updateOne(T model) async {
    if (model.id == null) {
      throw ArgumentError('The model must have an ID to be updated.');
    }
    final response = await _httpClient.patch(
      '/items/$collection/${model.id}',
      data: model.toJsonDirty(),
    );

    // Directus peut retourner 204 No Content sans body
    if (response.data == null || !response.data!.containsKey('data')) {
      return null;
    }

    final responseData = response.data!['data'] as Map<String, dynamic>;
    final T Function(Map<String, dynamic>) resolvedFactory = _getModelFactory();
    return resolvedFactory(responseData);
  }

  /// Met à jour plusieurs items avec les mêmes données et les retourne en modèles typés T
  ///
  /// [keys] Liste des identifiants des items à mettre à jour (optionnel)
  /// [data] Données à appliquer à tous les items
  /// [filter] Filtre pour sélectionner les items à mettre à jour (optionnel)
  /// [query] Query object au format Directus pour sélectionner les items (optionnel)
  ///
  /// Si ni [keys] ni [filter] ni [query] n'est fourni, tous les items de la collection
  /// seront mis à jour.
  ///
  /// Exemple :
  /// ```dart
  /// // Mettre à jour par liste d'IDs
  /// final updated = await articles.updateMany(
  ///   keys: ['id1', 'id2', 'id3'],
  ///   data: {'status': 'published'},
  /// );
  ///
  /// // Mettre à jour avec un filtre
  /// final updated = await articles.updateMany(
  ///   filter: Filter.equals('category', 'news'),
  ///   data: {'featured': true},
  /// );
  ///
  /// // Mettre à jour tous les items
  /// final updated = await articles.updateMany(data: {'archived': false});
  /// ```
  Future<List<T>> updateMany({
    List<String>? keys,
    required Map<String, dynamic> data,
    dynamic filter,
    Map<String, dynamic>? query,
  }) async {
    // Construire le body de la requête
    final Map<String, dynamic> body = {'data': data};

    // Ajouter keys si fourni
    if (keys != null && keys.isNotEmpty) {
      body['keys'] = keys;
    }

    // Ajouter query si fourni (contient filter, search, etc.)
    if (query != null) {
      body['query'] = query;
    } else if (filter != null) {
      // Convertir le filtre si c'est un objet Filter
      final filterJson = filter is Filter ? filter.toJson() : filter;
      body['query'] = {'filter': filterJson};
    }

    final response = await _httpClient.patch('/items/$collection', data: body);

    // Directus peut retourner 204 No Content sans body
    if (response.data == null || !response.data!.containsKey('data')) {
      return [];
    }

    final responseData = response.data!['data'] as List;
    final T Function(Map<String, dynamic>) resolvedFactory = _getModelFactory();
    return responseData
        .map((item) => resolvedFactory(item as Map<String, dynamic>))
        .toList();
  }

  /// Met à jour plusieurs modèles individuellement avec leurs propres données dirty
  ///
  /// Chaque modèle est mis à jour avec ses propres champs modifiés.
  /// Note: Cette méthode fait une requête par modèle.
  ///
  /// [models] Liste des modèles à mettre à jour
  ///
  /// Exemple :
  /// ```dart
  /// article1.title.set('Nouveau titre 1');
  /// article2.status.set('published');
  /// final updated = await articles.updateManyIndividual([article1, article2]);
  /// ```
  Future<List<T?>> updateManyIndividual(List<T> models) async {
    if (models.any((m) => m.id == null)) {
      throw ArgumentError('All models must have an ID to be updated.');
    }
    if (models.isEmpty) {
      return [];
    }

    final results = <T?>[];
    for (final model in models) {
      final result = await updateOne(model);
      results.add(result);
    }
    return results;
  }

  /// Supprime un item en utilisant son modèle
  Future<void> deleteOne(T model) async {
    if (model.id == null) {
      throw ArgumentError('The model must have an ID to be deleted.');
    }
    await _httpClient.delete('/items/$collection/${model.id}');
  }

  /// Supprime plusieurs items en utilisant leurs modèles
  ///
  /// Exemple :
  /// ```dart
  /// await articles.deleteManyModels([article1, article2]);
  /// ```
  Future<void> deleteManyModels(List<T> models) async {
    final ids = models.map((m) => m.id).whereType<String>().toList();
    if (ids.length != models.length) {
      throw ArgumentError('All models must have an ID to be deleted.');
    }
    if (ids.isEmpty) {
      return;
    }

    await _httpClient.delete('/items/$collection', data: ids);
  }

  /// Supprime plusieurs items
  ///
  /// [keys] Liste des identifiants des items à supprimer (optionnel)
  /// [filter] Filtre pour sélectionner les items à supprimer (optionnel)
  /// [query] Query object au format Directus pour sélectionner les items (optionnel)
  ///
  /// Si ni [keys] ni [filter] ni [query] n'est fourni, tous les items de la collection
  /// seront supprimés.
  ///
  /// Exemple :
  /// ```dart
  /// // Supprimer par liste d'IDs
  /// await articles.deleteMany(keys: ['id1', 'id2', 'id3']);
  ///
  /// // Supprimer avec un filtre
  /// await articles.deleteMany(filter: Filter.equals('status', 'archived'));
  ///
  /// // Supprimer tous les items de la collection
  /// await articles.deleteMany();
  /// ```
  Future<void> deleteMany({
    List<String>? keys,
    dynamic filter,
    Map<String, dynamic>? query,
  }) async {
    // Si keys est fourni directement (format simple)
    if (keys != null && keys.isNotEmpty && filter == null && query == null) {
      await _httpClient.delete('/items/$collection', data: keys);
      return;
    }

    // Construire le body de la requête au format objet
    final Map<String, dynamic> body = {};

    // Ajouter keys si fourni
    if (keys != null && keys.isNotEmpty) {
      body['keys'] = keys;
    }

    // Ajouter query si fourni (contient filter, search, etc.)
    if (query != null) {
      body['query'] = query;
    } else if (filter != null) {
      // Convertir le filtre si c'est un objet Filter
      final filterJson = filter is Filter ? filter.toJson() : filter;
      body['query'] = {'filter': filterJson};
    }

    await _httpClient.delete(
      '/items/$collection',
      data: body.isEmpty ? null : body,
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

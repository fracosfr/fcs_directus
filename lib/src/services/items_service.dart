import '../core/directus_http_client.dart';
import '../models/directus_active_model.dart';

/// Paramètres de requête pour filtrer, trier et paginer les données
class QueryParameters {
  /// Filtres à appliquer
  final Map<String, dynamic>? filter;

  /// Champs à retourner
  final List<String>? fields;

  /// Tri des résultats (ex: ['name', '-created_at'])
  final List<String>? sort;

  /// Nombre de résultats à retourner
  final int? limit;

  /// Offset pour la pagination
  final int? offset;

  /// Page (alternative à offset)
  final int? page;

  /// Recherche full-text
  final String? search;

  /// Relations à inclure (deep)
  final Map<String, dynamic>? deep;

  QueryParameters({
    this.filter,
    this.fields,
    this.sort,
    this.limit,
    this.offset,
    this.page,
    this.search,
    this.deep,
  });

  /// Convertit les paramètres en Map pour les query parameters
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (filter != null) {
      params['filter'] = filter;
    }
    if (fields != null && fields!.isNotEmpty) {
      params['fields'] = fields!.join(',');
    }
    if (sort != null && sort!.isNotEmpty) {
      params['sort'] = sort!.join(',');
    }
    if (limit != null) {
      params['limit'] = limit;
    }
    if (offset != null) {
      params['offset'] = offset;
    }
    if (page != null) {
      params['page'] = page;
    }
    if (search != null) {
      params['search'] = search;
    }
    if (deep != null) {
      params['deep'] = deep;
    }

    return params;
  }
}

/// Réponse paginée de Directus
class DirectusResponse<T> {
  final List<T> data;
  final DirectusMeta? meta;

  DirectusResponse({required this.data, this.meta});
}

/// Métadonnées de pagination
class DirectusMeta {
  final int? totalCount;
  final int? filterCount;

  DirectusMeta({this.totalCount, this.filterCount});

  factory DirectusMeta.fromJson(Map<String, dynamic> json) {
    return DirectusMeta(
      totalCount: json['total_count'] as int?,
      filterCount: json['filter_count'] as int?,
    );
  }
}

/// Service pour interagir avec les items d'une collection Directus.
///
/// Ce service fournit les opérations CRUD de base.
/// Le type générique [T] représente le modèle de données de la collection.
///
/// Exemple d'utilisation:
/// ```dart
/// final articlesService = client.items<Article>('articles');
///
/// // Créer
/// final newArticle = await articlesService.createOne({'title': 'Mon article'});
///
/// // Lire
/// final articles = await articlesService.readMany();
/// final article = await articlesService.readOne('1');
///
/// // Mettre à jour
/// await articlesService.updateOne('1', {'title': 'Titre modifié'});
///
/// // Supprimer
/// await articlesService.deleteOne('1');
/// ```
class ItemsService<T> {
  final DirectusHttpClient _httpClient;
  final String collection;

  ItemsService(this._httpClient, this.collection);

  // Convenience methods to work with DirectusActiveModel without requiring
  // a specific model class. These methods return dynamic maps wrapped in
  // DirectusActiveModel for callers who prefer the Active Record pattern.

  /// Récupère plusieurs items sous forme de `DirectusActiveModel`
  Future<DirectusResponse<DynamicActiveModel>> readManyActive({
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

    final items = data
        .map((item) => DynamicActiveModel(item as Map<String, dynamic>))
        .toList();

    return DirectusResponse(data: items, meta: meta);
  }

  /// Récupère un item par son ID et le retourne en `DirectusActiveModel`
  Future<DynamicActiveModel> readOneActive(
    String id, {
    QueryParameters? query,
  }) async {
    final response = await _httpClient.get(
      '/items/$collection/$id',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return DynamicActiveModel(data);
  }

  /// Crée un nouvel item et retourne un `DirectusActiveModel`
  Future<DynamicActiveModel> createOneActive(Map<String, dynamic> data) async {
    final response = await _httpClient.post('/items/$collection', data: data);

    final responseData = response.data['data'] as Map<String, dynamic>;
    return DynamicActiveModel(responseData);
  }

  /// Met à jour un item et retourne un `DirectusActiveModel`
  Future<DynamicActiveModel> updateOneActive(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _httpClient.patch(
      '/items/$collection/$id',
      data: data,
    );

    final responseData = response.data['data'] as Map<String, dynamic>;
    return DynamicActiveModel(responseData);
  }

  /// Récupère plusieurs items
  ///
  /// [query] Paramètres de requête pour filtrer et paginer
  /// [fromJson] Fonction pour convertir JSON en objet T (optionnel)
  Future<DirectusResponse<dynamic>> readMany({
    QueryParameters? query,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await _httpClient.get(
      '/items/$collection',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data['data'] as List;
    final meta = response.data['meta'] != null
        ? DirectusMeta.fromJson(response.data['meta'] as Map<String, dynamic>)
        : null;

    final items = fromJson != null
        ? data.map((item) => fromJson(item as Map<String, dynamic>)).toList()
        : data;

    return DirectusResponse(data: items, meta: meta);
  }

  /// Récupère un item par son ID
  ///
  /// [id] Identifiant de l'item
  /// [query] Paramètres de requête (champs, relations, etc.)
  /// [fromJson] Fonction pour convertir JSON en objet T (optionnel)
  Future<dynamic> readOne(
    String id, {
    QueryParameters? query,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await _httpClient.get(
      '/items/$collection/$id',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return fromJson != null ? fromJson(data) : data;
  }

  /// Crée un nouvel item
  ///
  /// [data] Données de l'item à créer
  /// [fromJson] Fonction pour convertir JSON en objet T (optionnel)
  Future<dynamic> createOne(
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await _httpClient.post('/items/$collection', data: data);

    final responseData = response.data['data'] as Map<String, dynamic>;
    return fromJson != null ? fromJson(responseData) : responseData;
  }

  /// Crée plusieurs items
  ///
  /// [items] Liste des items à créer
  /// [fromJson] Fonction pour convertir JSON en objet T (optionnel)
  Future<List<dynamic>> createMany(
    List<Map<String, dynamic>> items, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await _httpClient.post('/items/$collection', data: items);

    final data = response.data['data'] as List;
    return fromJson != null
        ? data.map((item) => fromJson(item as Map<String, dynamic>)).toList()
        : data;
  }

  /// Met à jour un item
  ///
  /// [id] Identifiant de l'item
  /// [data] Données à mettre à jour
  /// [fromJson] Fonction pour convertir JSON en objet T (optionnel)
  Future<dynamic> updateOne(
    String id,
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await _httpClient.patch(
      '/items/$collection/$id',
      data: data,
    );

    final responseData = response.data['data'] as Map<String, dynamic>;
    return fromJson != null ? fromJson(responseData) : responseData;
  }

  /// Met à jour plusieurs items
  ///
  /// [ids] Liste des identifiants des items à mettre à jour
  /// [data] Données à mettre à jour
  /// [fromJson] Fonction pour convertir JSON en objet T (optionnel)
  Future<List<dynamic>> updateMany(
    List<String> ids,
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await _httpClient.patch(
      '/items/$collection',
      data: data,
      queryParameters: {
        'filter': {
          'id': {'_in': ids},
        },
      },
    );

    final responseData = response.data['data'] as List;
    return fromJson != null
        ? responseData
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList()
        : responseData;
  }

  /// Supprime un item
  ///
  /// [id] Identifiant de l'item à supprimer
  Future<void> deleteOne(String id) async {
    await _httpClient.delete('/items/$collection/$id');
  }

  /// Supprime plusieurs items
  ///
  /// [ids] Liste des identifiants des items à supprimer
  Future<void> deleteMany(List<String> ids) async {
    await _httpClient.delete(
      '/items/$collection',
      queryParameters: {
        'filter': {
          'id': {'_in': ids},
        },
      },
    );
  }
}

import '../core/directus_http_client.dart';
import '../models/directus_filter.dart';
import '../models/directus_deep.dart';
import '../models/directus_aggregate.dart';

/// Paramètres de requête pour filtrer, trier et paginer les données
class QueryParameters {
  /// Filtres à appliquer (objet Filter ou Map pour compatibilité)
  final dynamic filter;

  /// Champs à retourner
  final List<String>? fields;

  /// Tri des résultats.
  ///
  /// Exemples :
  /// ```dart
  /// sort: ['name']         // Tri croissant par nom
  /// sort: ['-created_at']  // Tri décroissant par date de création
  /// sort: ['category', '-price'] // Multi-critères
  /// ```
  final List<String>? sort;

  /// Nombre de résultats à retourner
  final int? limit;

  /// Offset pour la pagination
  final int? offset;

  /// Page (alternative à offset)
  final int? page;

  /// Recherche full-text
  final String? search;

  /// Relations à inclure (objet Deep ou Map pour compatibilité)
  final dynamic deep;

  /// Agrégations à effectuer (objet Aggregate ou Map pour compatibilité)
  final dynamic aggregate;

  /// Regroupement des résultats (objet GroupBy, `List<String>` ou Map pour compatibilité)
  final dynamic groupBy;

  QueryParameters({
    this.filter,
    this.fields,
    this.sort,
    this.limit,
    this.offset,
    this.page,
    this.search,
    this.deep,
    this.aggregate,
    this.groupBy,
  });

  /// Convertit les paramètres en Map pour les query parameters
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (filter != null) {
      // Convertir Filter en Map si nécessaire
      if (filter is Filter) {
        params['filter'] = (filter as Filter).toJson();
      } else if (filter is Map<String, dynamic>) {
        params['filter'] = filter;
      }
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
      // Si deep est un objet Deep, convertir en JSON
      if (deep is Deep) {
        params['deep'] = deep.toJson();
      } else {
        // Sinon, utiliser directement (pour compatibilité Map)
        params['deep'] = deep;
      }
    }
    if (aggregate != null) {
      // Si aggregate est un objet Aggregate, convertir en JSON
      if (aggregate is Aggregate) {
        params['aggregate'] = aggregate.toJson();
      } else {
        // Sinon, utiliser directement (pour compatibilité Map)
        params['aggregate'] = aggregate;
      }
    }
    if (groupBy != null) {
      // Si groupBy est un objet GroupBy, convertir en JSON
      if (groupBy is GroupBy) {
        params['groupBy'] = (groupBy as GroupBy).toJson().join(',');
      } else if (groupBy is List<String>) {
        params['groupBy'] = groupBy.join(',');
      } else {
        // Sinon, utiliser directement (pour compatibilité Map/String)
        params['groupBy'] = groupBy;
      }
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

    final data = response.data!['data'] as Map<String, dynamic>;
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

    // Directus peut retourner 204 No Content sans body
    if (response.data == null || !response.data!.containsKey('data')) {
      return null;
    }

    final responseData = response.data!['data'] as Map<String, dynamic>;
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

    final data = response.data!['data'] as List;
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

    // Directus peut retourner 204 No Content sans body
    if (response.data == null || !response.data!.containsKey('data')) {
      return null;
    }

    final responseData = response.data!['data'] as Map<String, dynamic>;
    return fromJson != null ? fromJson(responseData) : responseData;
  }

  /// Met à jour plusieurs items avec les mêmes données
  ///
  /// [keys] Liste des identifiants des items à mettre à jour (optionnel)
  /// [data] Données à appliquer à tous les items
  /// [filter] Filtre pour sélectionner les items à mettre à jour (optionnel)
  /// [query] Query object au format Directus pour sélectionner les items (optionnel)
  /// [fromJson] Fonction pour convertir JSON en objet T (optionnel)
  ///
  /// Si ni [keys] ni [filter] ni [query] n'est fourni, tous les items de la collection
  /// seront mis à jour.
  ///
  /// Exemple :
  /// ```dart
  /// // Mettre à jour par liste d'IDs
  /// await items.updateMany(
  ///   keys: ['id1', 'id2', 'id3'],
  ///   data: {'status': 'published'},
  /// );
  ///
  /// // Mettre à jour avec un filtre
  /// await items.updateMany(
  ///   filter: Filter.equals('category', 'news'),
  ///   data: {'featured': true},
  /// );
  ///
  /// // Mettre à jour tous les items de la collection
  /// await items.updateMany(data: {'archived': false});
  /// ```
  Future<List<dynamic>> updateMany({
    List<String>? keys,
    required Map<String, dynamic> data,
    dynamic filter,
    Map<String, dynamic>? query,
    T Function(Map<String, dynamic>)? fromJson,
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
  /// await items.deleteMany(keys: ['id1', 'id2', 'id3']);
  ///
  /// // Supprimer avec un filtre
  /// await items.deleteMany(filter: Filter.equals('status', 'archived'));
  ///
  /// // Supprimer tous les items de la collection
  /// await items.deleteMany();
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

  // ========================================================================
  // MÉTHODES SINGLETON
  // ========================================================================

  /// Récupère le singleton de la collection
  ///
  /// Un singleton est une collection qui ne contient qu'un seul item unique.
  /// Utile pour les paramètres globaux, configurations, etc.
  ///
  /// [query] Paramètres de requête (champs, relations, etc.)
  /// [fromJson] Fonction pour convertir JSON en objet T (optionnel)
  ///
  /// Exemple:
  /// ```dart
  /// // Récupérer les settings globaux
  /// final settings = await directus.items('settings').readSingleton();
  /// ```
  Future<dynamic> readSingleton({
    QueryParameters? query,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await _httpClient.get(
      '/items/$collection',
      queryParameters: query?.toQueryParameters(),
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return fromJson != null ? fromJson(data) : data;
  }

  /// Met à jour le singleton de la collection
  ///
  /// Contrairement aux items normaux, un singleton n'a pas besoin d'ID
  /// car il n'existe qu'un seul item dans la collection.
  ///
  /// [data] Données à mettre à jour
  /// [fromJson] Fonction pour convertir JSON en objet T (optionnel)
  ///
  /// Exemple:
  /// ```dart
  /// // Mettre à jour les settings
  /// await directus.items('settings').updateSingleton({
  ///   'site_name': 'Mon nouveau site',
  ///   'maintenance_mode': false,
  /// });
  /// ```
  Future<dynamic> updateSingleton(
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await _httpClient.patch('/items/$collection', data: data);

    final responseData = response.data!['data'] as Map<String, dynamic>;
    return fromJson != null ? fromJson(responseData) : responseData;
  }
}

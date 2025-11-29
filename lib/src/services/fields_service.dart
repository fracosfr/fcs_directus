import '../core/directus_http_client.dart';

/// Service pour gérer les champs (fields) dans Directus.
///
/// Les champs sont des éléments de contenu individuels au sein d'un item.
/// Ils sont mappés aux colonnes de la base de données.
///
/// Exemple d'utilisation:
/// ```dart
/// // Lister tous les champs d'une collection
/// final fields = await client.fields.getFieldsInCollection('articles');
///
/// // Créer un nouveau champ
/// await client.fields.createField('articles', {
///   'field': 'subtitle',
///   'type': 'string',
///   'meta': {'interface': 'input'},
/// });
///
/// // Mettre à jour un champ
/// await client.fields.updateField('articles', 'subtitle', {
///   'meta': {'note': 'Sous-titre de l\'article'},
/// });
/// ```
class FieldsService {
  final DirectusHttpClient _httpClient;

  FieldsService(this._httpClient);

  /// Récupère la liste de tous les champs du projet
  ///
  /// Retourne une liste de tous les champs disponibles dans le projet,
  /// toutes collections confondues.
  ///
  /// [limit] Limite le nombre de champs retournés
  /// [sort] Tri des champs
  Future<List<Map<String, dynamic>>> getAllFields({
    int? limit,
    List<String>? sort,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (sort != null) queryParams['sort'] = sort.join(',');

    final response = await _httpClient.get(
      '/fields',
      queryParameters: queryParams,
    );
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// Récupère la liste des champs d'une collection spécifique
  ///
  /// [collection] Nom de la collection
  /// [sort] Tri des champs
  ///
  /// Exemple:
  /// ```dart
  /// final articleFields = await client.fields.getFieldsInCollection(
  ///   'articles',
  ///   sort: ['field'],
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> getFieldsInCollection(
    String collection, {
    List<String>? sort,
  }) async {
    final queryParams = <String, dynamic>{};
    if (sort != null) queryParams['sort'] = sort.join(',');

    final response = await _httpClient.get(
      '/fields/$collection',
      queryParameters: queryParams,
    );
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// Récupère les détails d'un champ spécifique
  ///
  /// [collection] Nom de la collection
  /// [field] Nom du champ
  Future<Map<String, dynamic>> getField(String collection, String field) async {
    final response = await _httpClient.get('/fields/$collection/$field');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Crée un nouveau champ dans une collection
  ///
  /// [collection] Nom de la collection
  /// [data] Configuration du champ (field, type, schema, meta)
  ///
  /// Exemple:
  /// ```dart
  /// final newField = await client.fields.createField('articles', {
  ///   'field': 'author_email',
  ///   'type': 'string',
  ///   'schema': {
  ///     'is_nullable': true,
  ///   },
  ///   'meta': {
  ///     'interface': 'input',
  ///     'options': {'placeholder': 'email@example.com'},
  ///     'display': 'formatted-value',
  ///     'readonly': false,
  ///     'hidden': false,
  ///     'width': 'full',
  ///   },
  /// });
  /// ```
  Future<Map<String, dynamic>> createField(
    String collection,
    Map<String, dynamic> data,
  ) async {
    final response = await _httpClient.post('/fields/$collection', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Met à jour un champ existant
  ///
  /// [collection] Nom de la collection
  /// [field] Nom du champ
  /// [data] Nouvelles données de configuration
  ///
  /// Exemple:
  /// ```dart
  /// await client.fields.updateField('articles', 'title', {
  ///   'meta': {
  ///     'note': 'Titre principal de l\'article',
  ///     'width': 'full',
  ///   },
  /// });
  /// ```
  Future<Map<String, dynamic>> updateField(
    String collection,
    String field,
    Map<String, dynamic> data,
  ) async {
    final response = await _httpClient.patch(
      '/fields/$collection/$field',
      data: data,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Supprime un champ
  ///
  /// [collection] Nom de la collection
  /// [field] Nom du champ à supprimer
  ///
  /// ⚠️ Attention: Cette action ne peut pas être annulée!
  Future<void> deleteField(String collection, String field) async {
    await _httpClient.delete('/fields/$collection/$field');
  }

  /// Vérifie si un champ existe dans une collection
  ///
  /// [collection] Nom de la collection
  /// [field] Nom du champ à vérifier
  Future<bool> fieldExists(String collection, String field) async {
    try {
      await getField(collection, field);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Récupère les champs obligatoires d'une collection
  ///
  /// Filtre côté client les champs qui ont `schema.is_nullable = false`
  Future<List<Map<String, dynamic>>> getRequiredFields(
    String collection,
  ) async {
    final fields = await getFieldsInCollection(collection);
    return fields
        .where((field) => field['schema']?['is_nullable'] == false)
        .toList();
  }

  /// Récupère les champs par type d'interface
  ///
  /// [collection] Nom de la collection
  /// [interfaceType] Type d'interface (input, select-dropdown, etc.)
  Future<List<Map<String, dynamic>>> getFieldsByInterface(
    String collection,
    String interfaceType,
  ) async {
    final fields = await getFieldsInCollection(collection);
    return fields
        .where((field) => field['meta']?['interface'] == interfaceType)
        .toList();
  }
}

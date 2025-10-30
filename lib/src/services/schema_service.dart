import '../core/directus_http_client.dart';

/// Service pour gérer le schéma de la base de données Directus.
///
/// Le schéma représente la structure complète de la base de données
/// (tables, colonnes, relations, etc.).
///
/// Exemple d'utilisation:
/// ```dart
/// // Récupérer le schéma complet
/// final schema = await client.schema.snapshot();
///
/// // Appliquer des changements de schéma
/// await client.schema.apply({
///   'collections': [...],
///   'fields': [...],
///   'relations': [...],
/// });
///
/// // Obtenir les différences avec un autre schéma
/// final diff = await client.schema.diff(otherSchema);
/// ```
class SchemaService {
  final DirectusHttpClient _httpClient;

  SchemaService(this._httpClient);

  /// Récupère un snapshot complet du schéma de la base de données
  ///
  /// Retourne un objet contenant:
  /// - collections: Liste de toutes les collections
  /// - fields: Liste de tous les champs
  /// - relations: Liste de toutes les relations
  ///
  /// Ce snapshot peut être utilisé pour:
  /// - Sauvegarder la structure de la base de données
  /// - Comparer avec d'autres environnements
  /// - Appliquer sur une autre instance
  Future<dynamic> snapshot() async {
    final response = await _httpClient.get('/schema/snapshot');
    return response.data['data'];
  }

  /// Applique un schéma sur l'instance Directus
  ///
  /// [schema] Le schéma à appliquer (obtenu via snapshot())
  ///
  /// ⚠️ ATTENTION: Cette opération modifie la structure de la base de données.
  /// Assurez-vous d'avoir une sauvegarde avant d'appliquer un schéma.
  ///
  /// Exemple:
  /// ```dart
  /// final schema = {
  ///   'collections': [
  ///     {
  ///       'collection': 'articles',
  ///       'meta': {...},
  ///       'schema': {...},
  ///     }
  ///   ],
  ///   'fields': [...],
  ///   'relations': [...],
  /// };
  /// await client.schema.apply(schema);
  /// ```
  Future<void> apply(Map<String, dynamic> schema) async {
    await _httpClient.post('/schema/apply', data: schema);
  }

  /// Compare le schéma actuel avec un autre schéma
  ///
  /// [schema] Le schéma à comparer avec le schéma actuel
  /// [force] Si true, force l'application même en cas de conflit
  ///
  /// Retourne les différences entre les deux schémas:
  /// - Collections ajoutées, modifiées ou supprimées
  /// - Champs ajoutés, modifiés ou supprimés
  /// - Relations ajoutées, modifiées ou supprimées
  ///
  /// Exemple:
  /// ```dart
  /// final diff = await client.schema.diff(otherSchema);
  /// if (diff['hash'] != currentHash) {
  ///   print('Le schéma a changé');
  ///   print('Collections: ${diff['diff']['collections']}');
  ///   print('Fields: ${diff['diff']['fields']}');
  /// }
  /// ```
  Future<dynamic> diff(
    Map<String, dynamic> schema, {
    bool force = false,
  }) async {
    final response = await _httpClient.post(
      '/schema/diff',
      data: schema,
      queryParameters: force ? {'force': true} : null,
    );
    return response.data['data'];
  }
}

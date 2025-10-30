import 'directus_model.dart';

/// Représente une relation Directus.
///
/// Les relations définissent les connexions entre les collections
/// dans Directus (One-to-Many, Many-to-One, Many-to-Many, etc.).
///
/// Exemple d'utilisation :
/// ```dart
/// // Récupérer toutes les relations
/// final relations = await client.relations.getRelations();
///
/// // Récupérer les relations d'une collection
/// final articleRelations = await client.relations.getRelationsByCollection('articles');
///
/// // Créer une relation Many-to-One
/// final relation = DirectusRelation.empty()
///   ..manyCollection.set('articles')
///   ..manyField.set('author')
///   ..oneCollection.set('users');
/// await client.relations.createRelation(relation.toMap());
/// ```
class DirectusRelation extends DirectusModel {
  /// Collection qui a le champ contenant la clé étrangère (côté "many")
  late final manyCollection = stringValue('many_collection');

  /// Champ de clé étrangère qui contient la clé primaire de la collection liée
  late final manyField = stringValue('many_field');

  /// Collection du côté "one" de la relation
  late final oneCollection = stringValue('one_collection');

  /// Colonne alias qui sert de côté "one" de la relation
  late final oneField = stringValue('one_field');

  /// Champ de collection one
  late final oneCollectionField = stringValue('one_collection_field');

  /// Collections autorisées pour le côté "one"
  late final oneAllowedCollections =
      listValue<String>('one_allowed_collections');

  /// Champ sur la table de jonction qui contient le champ "many" de la relation liée
  late final junctionField = stringValue('junction_field');

  /// Champ de tri
  late final sortField = stringValue('sort_field');

  /// Action de désélection du côté "one"
  late final oneDeselectAction = stringValue('one_deselect_action');

  DirectusRelation(super.data);
  DirectusRelation.empty() : super.empty();

  @override
  String get itemName => 'directus_relations';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusRelation factory(Map<String, dynamic> data) =>
      DirectusRelation(data);

  /// Vérifie si c'est une relation Many-to-One simple
  bool get isManyToOne =>
      manyCollection.isNotEmpty &&
      manyField.isNotEmpty &&
      oneCollection.isNotEmpty &&
      junctionField.valueOrNull == null;

  /// Vérifie si c'est une relation One-to-Many
  bool get isOneToMany =>
      oneCollection.isNotEmpty &&
      oneField.isNotEmpty &&
      junctionField.valueOrNull == null;

  /// Vérifie si c'est une relation Many-to-Many (avec table de jonction)
  bool get isManyToMany => junctionField.isNotEmpty;

  /// Vérifie si la relation a un champ de tri
  bool get hasSortField => sortField.isNotEmpty;

  /// Vérifie si la relation a des collections autorisées
  bool get hasAllowedCollections => oneAllowedCollections.isNotEmpty;

  /// Obtient le type de relation
  String get relationType {
    if (isManyToMany) return 'Many-to-Many';
    if (isOneToMany) return 'One-to-Many';
    if (isManyToOne) return 'Many-to-One';
    return 'Unknown';
  }

  /// Obtient un résumé de la relation
  String get summary {
    final type = relationType;
    final many = manyCollection.valueOrNull ?? 'collection inconnue';
    final manyF = manyField.valueOrNull ?? 'champ inconnu';
    final one = oneCollection.valueOrNull ?? 'collection inconnue';
    return '$type: $many.$manyF -> $one';
  }
}

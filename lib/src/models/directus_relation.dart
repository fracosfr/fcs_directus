import 'directus_model.dart';
import 'directus_property.dart';

/// Représente une relation Directus (`/relations`).
///
/// Format API :
/// ```json
/// {
///   "collection": "articles",          // collection portant la clé étrangère
///   "field": "author",                 // champ clé étrangère
///   "related_collection": "directus_users",
///   "meta": { "one_field": "articles", "junction_field": null, ... },
///   "schema": { "on_delete": "SET NULL", ... }
/// }
/// ```
///
/// Les propriétés `manyCollection`, `oneField`, `junctionField`... lisent
/// l'objet `meta`.
///
/// ```dart
/// final relation = await client.relations.readOne('articles', 'author');
/// print(relation.relatedCollection.value); // directus_users
/// print(relation.relationType);            // Many-to-One
/// ```
class DirectusRelation extends DirectusModel {
  /// Collection qui porte la clé étrangère
  late final collection = stringValue('collection');

  /// Champ clé étrangère
  late final field = stringValue('field');

  /// Collection référencée (null pour une relation Many-to-Any)
  late final relatedCollection = stringValue('related_collection');

  /// Métadonnées Directus de la relation (Map)
  late final meta = jsonValue('meta');

  /// Contraintes de base de données (`on_delete`, `on_update`, ...)
  late final schema = jsonValue('schema');

  DirectusRelation(super.data);
  DirectusRelation.empty() : super.empty();

  /// Vue typée de l'objet `meta`.
  DirectusRelationMeta get metaModel =>
      DirectusRelationMeta(meta.asMapOrEmpty());

  /// Collection « many » (meta.many_collection)
  StringProperty get manyCollection => metaModel.manyCollection;

  /// Champ « many » (meta.many_field)
  StringProperty get manyField => metaModel.manyField;

  /// Collection « one » (meta.one_collection)
  StringProperty get oneCollection => metaModel.oneCollection;

  /// Alias O2M côté « one » (meta.one_field)
  StringProperty get oneField => metaModel.oneField;

  /// Champ stockant la collection pour un Many-to-Any (meta.one_collection_field)
  StringProperty get oneCollectionField => metaModel.oneCollectionField;

  /// Collections autorisées pour un Many-to-Any (meta.one_allowed_collections)
  ListProperty<String> get oneAllowedCollections =>
      metaModel.oneAllowedCollections;

  /// Champ de jonction pour un Many-to-Many (meta.junction_field)
  StringProperty get junctionField => metaModel.junctionField;

  /// Champ de tri (meta.sort_field)
  StringProperty get sortField => metaModel.sortField;

  /// Action à la désélection (meta.one_deselect_action : `nullify` / `delete`)
  StringProperty get oneDeselectAction => metaModel.oneDeselectAction;

  @override
  String get itemName => 'directus_relations';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusRelation factory(Map<String, dynamic> data) =>
      DirectusRelation(data);

  /// Vrai pour une relation Many-to-Many (présence d'un champ de jonction)
  bool get isManyToMany => junctionField.isNotEmpty;

  /// Vrai pour une relation Many-to-Any (pas de collection liée fixe)
  bool get isManyToAny =>
      relatedCollection.valueOrNull == null && oneCollectionField.isNotEmpty;

  /// Vrai si la relation expose un alias One-to-Many côté « one »
  bool get isOneToMany => oneField.isNotEmpty && !isManyToMany;

  /// Vrai pour une relation Many-to-One simple
  bool get isManyToOne =>
      relatedCollection.isNotEmpty && !isManyToMany && !isManyToAny;

  /// Vérifie si la relation a un champ de tri
  bool get hasSortField => sortField.isNotEmpty;

  /// Vérifie si la relation a des collections autorisées (M2A)
  bool get hasAllowedCollections => oneAllowedCollections.isNotEmpty;

  /// Type de relation lisible
  String get relationType {
    if (isManyToMany) return 'Many-to-Many';
    if (isManyToAny) return 'Many-to-Any';
    if (isOneToMany) return 'One-to-Many';
    if (isManyToOne) return 'Many-to-One';
    return 'Unknown';
  }

  /// Résumé lisible de la relation
  String get summary {
    final many = collection.valueOrNull ?? 'collection inconnue';
    final manyF = field.valueOrNull ?? 'champ inconnu';
    final one = relatedCollection.valueOrNull ?? 'collection inconnue';
    return '$relationType: $many.$manyF -> $one';
  }
}

/// Objet `meta` d'une relation Directus.
class DirectusRelationMeta extends DirectusModel {
  late final manyCollection = stringValue('many_collection');
  late final manyField = stringValue('many_field');
  late final oneCollection = stringValue('one_collection');
  late final oneField = stringValue('one_field');
  late final oneCollectionField = stringValue('one_collection_field');
  late final oneAllowedCollections = listValue<String>(
    'one_allowed_collections',
  );
  late final junctionField = stringValue('junction_field');
  late final sortField = stringValue('sort_field');
  late final oneDeselectAction = stringValue('one_deselect_action');

  DirectusRelationMeta(super.data);

  @override
  String get itemName => 'directus_relations';
}

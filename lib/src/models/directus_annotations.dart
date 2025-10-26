/// Annotation pour marquer une classe comme modèle Directus.
///
/// Cette annotation est utilisée pour la génération de code automatique
/// avec build_runner.
///
/// Exemple:
/// ```dart
/// @DirectusModel()
/// class Article extends DirectusModel {
///   final String title;
///   final String? content;
///
///   Article({
///     super.id,
///     required this.title,
///     this.content,
///     super.dateCreated,
///     super.dateUpdated,
///   });
/// }
/// ```
class DirectusModelAnnotation {
  /// Nom de la collection Directus (optionnel, utilise le nom de la classe en snake_case par défaut)
  final String? collection;

  const DirectusModelAnnotation({this.collection});
}

/// Annotation pour marquer une classe comme modèle Directus.
const directusModel = DirectusModelAnnotation();

/// Annotation pour exclure un champ de la sérialisation.
///
/// Exemple:
/// ```dart
/// @DirectusIgnore()
/// String get fullName => '$firstName $lastName';
/// ```
class DirectusIgnore {
  const DirectusIgnore();
}

/// Annotation pour personnaliser le nom d'un champ dans JSON.
///
/// Exemple:
/// ```dart
/// @DirectusField('custom_field_name')
/// final String myField;
/// ```
class DirectusField {
  /// Nom du champ dans JSON
  final String name;

  const DirectusField(this.name);
}

/// Annotation pour marquer un champ comme relation.
///
/// Exemple:
/// ```dart
/// @DirectusRelation()
/// final User? author;
/// ```
class DirectusRelation {
  /// Si true, la relation sera incluse dans toJson()
  final bool includeInJson;

  const DirectusRelation({this.includeInJson = false});
}

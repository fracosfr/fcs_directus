import 'directus_model.dart';

/// Représente une version de contenu (`directus_versions`).
///
/// ```dart
/// final draft = DirectusVersion.empty()
///   ..key.set('draft')
///   ..name.set('Brouillon')
///   ..collection.set('articles')
///   ..item.set('15');
/// final version = await client.versions.createOne(draft);
/// await client.versions.save(version!.id!, {'title': 'Titre en cours'});
/// await client.versions.promote(version.id!);
/// ```
class DirectusVersion extends DirectusModel {
  /// Clé de la version (ex: `draft`), utilisée avec `QueryParameters.version`
  late final key = stringValue('key');

  /// Nom affiché
  late final name = stringValue('name');

  /// Collection de l'item versionné
  late final collection = stringValue('collection');

  /// Identifiant de l'item versionné
  late final item = stringValue('item');

  /// Hash de l'item principal lors de la création (détection de conflit)
  late final hash = stringValue('hash');

  /// Modifications enregistrées dans la version
  late final delta = jsonValue('delta');

  DirectusVersion(super.data);
  DirectusVersion.empty() : super.empty();

  @override
  String get itemName => 'directus_versions';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusVersion factory(Map<String, dynamic> data) =>
      DirectusVersion(data);
}

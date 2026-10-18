import 'directus_model.dart';

/// Représente une chaîne de traduction (`directus_translations`).
///
/// ```dart
/// final t = DirectusTranslation.empty()
///   ..language.set('fr-FR')
///   ..key.set('welcome')
///   ..value.set('Bienvenue');
/// await client.translations.createOne(t);
/// ```
class DirectusTranslation extends DirectusModel {
  /// Code de langue (ex: `fr-FR`)
  late final language = stringValue('language');

  /// Clé de traduction
  late final key = stringValue('key');

  /// Valeur traduite
  late final value = stringValue('value');

  DirectusTranslation(super.data);
  DirectusTranslation.empty() : super.empty();

  @override
  String get itemName => 'directus_translations';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusTranslation factory(Map<String, dynamic> data) =>
      DirectusTranslation(data);
}

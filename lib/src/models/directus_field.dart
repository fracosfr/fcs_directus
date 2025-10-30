import 'directus_model.dart';

/// Représente un champ (field) Directus.
///
/// Les champs définissent la structure des collections dans Directus.
/// Ils déterminent les types de données, les interfaces, les validations
/// et l'apparence dans le Data Studio.
///
/// Exemple d'utilisation :
/// ```dart
/// // Créer un nouveau champ
/// final field = DirectusField.empty()
///   ..field.set('title')
///   ..type.set('string')
///   ..interface.set('input')
///   ..required.set(true)
///   ..width.set('full')
///   ..note.set('The title of the article');
/// await client.fields.createField('articles', field.toMap());
///
/// // Récupérer les champs d'une collection
/// final fields = await client.fields.getFieldsInCollection('articles');
///
/// // Vérifier si un champ existe
/// final exists = await client.fields.fieldExists('articles', 'title');
/// ```
class DirectusField extends DirectusModel {
  /// Nom unique de la collection contenant ce champ
  late final collection = stringValue('collection');

  /// Nom unique du champ (unique dans la collection)
  late final field = stringValue('field');

  /// Drapeaux de transformation spéciaux qui s'appliquent à ce champ
  /// Exemples: alias, file, m2o, o2m, m2m, m2a, translations, etc.
  late final special = listValue<String>('special');

  /// Interface utilisée pour ce champ
  /// Exemples: input, textarea, wysiwyg, dropdown, datetime, etc.
  late final interface = stringValue('interface');

  /// Options de l'interface configurées pour ce champ
  /// La structure dépend de l'interface utilisée
  late final options = objectValue('options');

  /// Display utilisé pour ce champ
  late final display = stringValue('display');

  /// Options configurées pour le display utilisé
  late final displayOptions = objectValue('display_options');

  /// Si le champ est considéré en lecture seule dans le Data Studio
  late final readonly = boolValue('readonly');

  /// Si le champ est caché de la page d'édition dans le Data Studio
  late final hidden = boolValue('hidden');

  /// Où ce champ est affiché sur la page d'édition dans le Data Studio
  late final sort = intValue('sort');

  /// Largeur de l'interface sur la page d'édition dans le Data Studio
  /// Valeurs possibles: half, half-left, half-right, half-space, full, fill
  late final width = stringValue('width');

  /// Traductions de ce nom de champ dans les différentes langues du Data Studio
  late final translations = listValue<Map<String, dynamic>>('translations');

  /// Description courte affichée dans le Data Studio
  late final note = stringValue('note');

  /// Si le champ est requis
  late final required = boolValue('required');

  /// Groupe auquel appartient le champ (Many-to-One vers fields)
  late final group = intValue('group');

  /// Message de validation personnalisé
  late final validationMessage = stringValue('validation_message');

  DirectusField(super.data);
  DirectusField.empty() : super.empty();

  @override
  String get itemName => 'directus_fields';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusField factory(Map<String, dynamic> data) =>
      DirectusField(data);

  /// Vérifie si le champ a une description
  bool get hasNote => note.isNotEmpty;

  /// Vérifie si le champ est requis
  bool get isRequired => required.value == true;

  /// Vérifie si le champ est en lecture seule
  bool get isReadonly => readonly.value == true;

  /// Vérifie si le champ est caché
  bool get isHidden => hidden.value == true;

  /// Vérifie si le champ a une interface configurée
  bool get hasInterface => interface.isNotEmpty;

  /// Vérifie si le champ a des options d'interface
  bool get hasOptions => options.exists && (options.value?.isNotEmpty ?? false);

  /// Vérifie si le champ a un display configuré
  bool get hasDisplay => display.isNotEmpty;

  /// Vérifie si le champ a des options de display
  bool get hasDisplayOptions =>
      displayOptions.exists && (displayOptions.value?.isNotEmpty ?? false);

  /// Vérifie si le champ a des transformations spéciales
  bool get hasSpecial => special.isNotEmpty;

  /// Vérifie si le champ est un alias
  bool get isAlias => special.value.contains('alias');

  /// Vérifie si le champ est une relation Many-to-One
  bool get isM2O => special.value.contains('m2o');

  /// Vérifie si le champ est une relation One-to-Many
  bool get isO2M => special.value.contains('o2m');

  /// Vérifie si le champ est une relation Many-to-Many
  bool get isM2M => special.value.contains('m2m');

  /// Vérifie si le champ est une relation Many-to-Any
  bool get isM2A => special.value.contains('m2a');

  /// Vérifie si le champ est un champ de traduction
  bool get isTranslations => special.value.contains('translations');

  /// Vérifie si le champ est un fichier
  bool get isFile => special.value.contains('file');

  /// Obtient un résumé du champ
  String get summary {
    final fieldName = field.valueOrNull ?? 'Champ sans nom';
    final collectionName = collection.valueOrNull ?? 'collection inconnue';
    final interfaceType = interface.valueOrNull ?? 'interface inconnue';
    final req = isRequired ? ' (requis)' : '';
    return '$fieldName dans $collectionName - Interface: $interfaceType$req';
  }
}

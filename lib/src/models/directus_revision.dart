import 'directus_model.dart';

/// Représente une révision Directus.
///
/// Les révisions enregistrent les changements spécifiques apportés aux items,
/// permettant de suivre l'historique des modifications et potentiellement de
/// restaurer des versions précédentes.
///
/// Exemple d'utilisation :
/// ```dart
/// // Récupérer les révisions d'un item
/// final revisions = await client.items('directus_revisions').readMany(
///   query: QueryParameters(
///     filter: Filter.field('item').equals('item-id'),
///     sort: ['-id'],
///   ),
/// );
/// ```
class DirectusRevision extends DirectusModel {
  /// Activité associée à cette révision (Many-to-One vers activity)
  late final activity = intValue('activity');

  /// Collection dans laquelle l'item réside
  late final collection = stringValue('collection');

  /// Identifiant de l'item
  late final item = stringValue('item');

  /// Données de la révision (contient les changements)
  late final data = objectValue('data');

  /// Delta des changements (différences avec la version précédente)
  late final delta = objectValue('delta');

  /// Révision parente (pour les versions chainées)
  late final parent = intValue('parent');

  /// Version de l'item à cette révision
  late final version = stringValue('version');

  DirectusRevision(super.data);
  DirectusRevision.empty() : super.empty();

  @override
  String get itemName => 'directus_revisions';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusRevision factory(Map<String, dynamic> data) =>
      DirectusRevision(data);

  /// Vérifie si la révision a des données
  bool get hasData => data.exists && (data.value?.isNotEmpty ?? false);

  /// Vérifie si la révision a un delta
  bool get hasDelta => delta.exists && (delta.value?.isNotEmpty ?? false);

  /// Vérifie si la révision a une révision parente
  bool get hasParent => parent.value > 0;

  /// Obtient le nombre de champs modifiés dans le delta
  int get changesCount {
    final d = delta.value;
    return d?.isNotEmpty == true ? d!.length : 0;
  }

  /// Obtient les noms des champs modifiés
  List<String> get changedFields {
    final d = delta.value;
    return d?.keys.toList() ?? [];
  }
}

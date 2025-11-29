import 'directus_model.dart';
import 'directus_policy.dart';

/// Représente une permission Directus.
///
/// Les permissions définissent les règles d'accès pour les collections
/// et les actions dans Directus.
///
/// Exemple d'utilisation :
/// ```dart
/// // Créer une permission de lecture
/// final permission = DirectusPermission.empty()
///   ..collection.set('articles')
///   ..action.set('read')
///   ..policy.set('policy-id')
///   ..fields.set(['*']);
/// await client.permissions.createPermission(permission.toMap());
///
/// // Récupérer les permissions d'une policy
/// final permissions = await client.permissions.getPermissions(
///   query: QueryParameters(
///     filter: Filter.field('policy').equals('policy-id'),
///   ),
/// );
/// ```
class DirectusPermission extends DirectusModel {
  /// Collection à laquelle cette permission s'applique
  late final collection = stringValue('collection');

  /// Action à laquelle cette permission s'applique
  /// Valeurs possibles: create, read, update, delete
  late final action = stringValue('action');

  /// Structure JSON contenant les vérifications de permissions
  late final permissions = objectValue('permissions');

  /// Structure JSON contenant les vérifications de validation
  late final validation = objectValue('validation');

  /// Structure JSON contenant les valeurs par défaut pour les items créés/mis à jour
  late final presets = objectValue('presets');

  /// Liste des champs avec lesquels l'utilisateur peut interagir
  late final fields = listValue<String>('fields');

  /// Policy à laquelle cette permission s'applique (Many-to-One vers policies)
  late final policy = stringValue('policy');

  DirectusPermission(super.data);
  DirectusPermission.empty() : super.empty();

  @override
  String get itemName => 'directus_permissions';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusPermission factory(Map<String, dynamic> data) =>
      DirectusPermission(data);

  /// Vérifie si l'action est une création
  bool get isCreate => action.value == 'create';

  /// Vérifie si l'action est une lecture
  bool get isRead => action.value == 'read';

  /// Vérifie si l'action est une mise à jour
  bool get isUpdate => action.value == 'update';

  /// Vérifie si l'action est une suppression
  bool get isDelete => action.value == 'delete';

  /// Vérifie si la permission a des règles de permissions
  bool get hasPermissions =>
      permissions.exists && (permissions.value?.isNotEmpty ?? false);

  /// Vérifie si la permission a des règles de validation
  bool get hasValidation =>
      validation.exists && (validation.value?.isNotEmpty ?? false);

  /// Vérifie si la permission a des presets
  bool get hasPresets => presets.exists && (presets.value?.isNotEmpty ?? false);

  /// Vérifie si la permission restreint les champs
  bool get hasFieldRestrictions => fields.isNotEmpty;

  /// Vérifie si tous les champs sont autorisés
  bool get allowsAllFields =>
      fields.value.contains('*') || fields.value.isEmpty;

  /// Obtient la policy associée
  DirectusPolicy? get policyObject =>
      getDirectusModelOrNull<DirectusPolicy>('policy');

  /// Obtient un résumé de la permission
  String get summary {
    final coll = collection.valueOrNull ?? 'collection inconnue';
    final act = action.valueOrNull ?? 'action inconnue';
    final fieldCount = allowsAllFields ? 'tous' : '${fields.value.length}';
    return '$act sur $coll - $fieldCount champ(s)';
  }
}

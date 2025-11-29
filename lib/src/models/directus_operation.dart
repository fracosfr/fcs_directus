import 'directus_model.dart';
import 'directus_user.dart';

/// Représente une opération Directus.
///
/// Les opérations sont des blocs de construction pour les flows.
/// Chaque opération effectue une action spécifique et peut être
/// chaînée avec d'autres opérations pour créer des workflows complexes.
///
/// Exemple d'utilisation :
/// ```dart
/// // Une opération est généralement chargée dans le contexte d'un flow
/// final flow = await client.flows.getFlow(
///   'flow-id',
///   query: QueryParameters()
///     ..fields = ['*', 'operations.*'],
/// );
///
/// final operations = flow.operationsList;
/// for (final op in operations) {
///   print('Operation: ${op.name.value} (${op.type.value})');
/// }
/// ```
class DirectusOperation extends DirectusModel {
  /// Nom de l'opération
  late final name = stringValue('name');

  /// Clé de l'opération (doit être unique dans un flow donné)
  late final key = stringValue('key');

  /// Type d'opération
  /// Valeurs possibles: log, mail, notification, create, read, request,
  /// sleep, transform, trigger, condition, ou tout type d'extension custom
  late final type = stringValue('type');

  /// Position de l'opération sur l'axe X dans l'espace de travail du flow
  late final positionX = intValue('position_x');

  /// Position de l'opération sur l'axe Y dans l'espace de travail du flow
  late final positionY = intValue('position_y');

  /// Options dépendant du type d'opération
  late final options = objectValue('options');

  /// L'opération déclenchée quand l'opération courante réussit
  /// (ou logique "then" d'une opération de condition)
  late final resolve = stringValue('resolve');

  /// L'opération déclenchée quand l'opération courante échoue
  /// (ou logique "otherwise" d'une opération de condition)
  late final reject = stringValue('reject');

  /// Flow auquel appartient cette opération (Many-to-One vers flows)
  late final flow = stringValue('flow');

  DirectusOperation(super.data);
  DirectusOperation.empty() : super.empty();

  @override
  String get itemName => 'directus_operations';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusOperation factory(Map<String, dynamic> data) =>
      DirectusOperation(data);

  /// Vérifie si l'opération a des options configurées
  bool get hasOptions => options.exists && (options.value?.isNotEmpty ?? false);

  /// Vérifie si l'opération a une opération de résolution (success)
  bool get hasResolve => resolve.isNotEmpty;

  /// Vérifie si l'opération a une opération de rejet (failure)
  bool get hasReject => reject.isNotEmpty;

  /// Obtient l'utilisateur qui a créé l'opération
  DirectusUser? get creator =>
      getDirectusModelOrNull<DirectusUser>('user_created');

  /// Obtient le nom du créateur de l'opération
  String? get creatorName => creator?.fullName;

  /// Formate la date de création de manière lisible
  String get formattedDateCreated {
    final date = dateCreated;
    if (date == null) return 'Date inconnue';
    return date.toLocal().toString();
  }

  /// Vérifie si l'opération est de type log
  bool get isLog => type.value == 'log';

  /// Vérifie si l'opération est de type mail
  bool get isMail => type.value == 'mail';

  /// Vérifie si l'opération est de type notification
  bool get isNotification => type.value == 'notification';

  /// Vérifie si l'opération est de type create
  bool get isCreate => type.value == 'create';

  /// Vérifie si l'opération est de type read
  bool get isRead => type.value == 'read';

  /// Vérifie si l'opération est de type request
  bool get isRequest => type.value == 'request';

  /// Vérifie si l'opération est de type sleep
  bool get isSleep => type.value == 'sleep';

  /// Vérifie si l'opération est de type transform
  bool get isTransform => type.value == 'transform';

  /// Vérifie si l'opération est de type trigger
  bool get isTrigger => type.value == 'trigger';

  /// Vérifie si l'opération est de type condition
  bool get isCondition => type.value == 'condition';

  /// Obtient un résumé de l'opération
  String get summary {
    final operationName = name.valueOrNull ?? 'Opération sans nom';
    final operationType = type.valueOrNull ?? 'type inconnu';
    final operationKey = key.valueOrNull ?? 'clé inconnue';
    return '$operationName ($operationKey) - Type: $operationType';
  }
}

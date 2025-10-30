import 'directus_model.dart';
import 'directus_user.dart';
import 'directus_operation.dart';

/// Représente un flow Directus.
///
/// Les flows permettent de créer des workflows d'automatisation et de
/// traitement de données événementiel dans Directus. Ils peuvent être
/// déclenchés par divers événements (hooks, webhooks, manuel, schedule, etc.)
/// et exécutent une chaîne d'opérations.
///
/// Exemple d'utilisation :
/// ```dart
/// // Créer un flow manuel
/// final flow = DirectusFlow.empty()
///   ..name.set('Update Articles Flow')
///   ..status.set('active')
///   ..trigger.set('manual')
///   ..icon.set('bolt')
///   ..color.set('#112233')
///   ..accountability.set('\$trigger');
/// await client.flows.createFlow(flow.toMap());
///
/// // Déclencher un flow
/// final result = await client.flows.triggerFlow('flow-id', {
///   'data': {'value': 42}
/// });
///
/// // Récupérer un flow avec ses opérations
/// final flow = await client.flows.getFlow(
///   'flow-id',
///   query: QueryParameters()
///     ..fields = ['*', 'operations.*'],
/// );
/// ```
class DirectusFlow extends DirectusModel {
  /// Nom du flow
  late final name = stringValue('name');

  /// Icône affichée dans l'Admin App pour le flow
  late final icon = stringValue('icon');

  /// Couleur de l'icône affichée dans l'Admin App pour le flow
  late final color = stringValue('color');

  /// Description du flow
  late final description = stringValue('description');

  /// Statut actuel du flow
  /// Valeurs possibles: active, inactive
  late final status = stringValue('status');

  /// Type de déclencheur pour le flow
  /// Valeurs possibles: hook, webhook, operation, schedule, manual
  late final trigger = stringValue('trigger');

  /// Permission utilisée pendant le flow
  /// Valeurs possibles: $public, $trigger, $full, ou UUID d'un rôle
  late final accountability = stringValue('accountability');

  /// Options du déclencheur sélectionné pour le flow
  late final options = objectValue('options');

  /// UUID de l'opération connectée au déclencheur dans le flow
  late final operation = stringValue('operation');

  /// Opérations du flow (One-to-Many vers operations)
  late final operations = modelListValue<DirectusOperation>('operations');

  DirectusFlow(super.data);
  DirectusFlow.empty() : super.empty();

  @override
  String get itemName => 'directus_flows';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusFlow factory(Map<String, dynamic> data) => DirectusFlow(data);

  /// Vérifie si le flow est actif
  bool get isActive => status.value == 'active';

  /// Vérifie si le flow est inactif
  bool get isInactive => status.value == 'inactive';

  /// Vérifie si le flow a une description
  bool get hasDescription => description.isNotEmpty;

  /// Vérifie si le flow a des options configurées
  bool get hasOptions => options.exists && (options.value?.isNotEmpty ?? false);

  /// Vérifie si le flow a des opérations
  bool get hasOperations => operations.isNotEmpty;

  /// Obtient la liste des opérations
  List<DirectusOperation> get operationsList => operations.value;

  /// Obtient le nombre d'opérations
  int get operationsCount => operations.value.length;

  /// Obtient l'utilisateur qui a créé le flow
  DirectusUser? get creator =>
      getDirectusModelOrNull<DirectusUser>('user_created');

  /// Obtient le nom du créateur du flow
  String? get creatorName => creator?.fullName;

  /// Formate la date de création de manière lisible
  String get formattedDateCreated {
    final date = dateCreated;
    if (date == null) return 'Date inconnue';
    return date.toLocal().toString();
  }

  /// Vérifie si le déclencheur est de type hook
  bool get isHookTrigger => trigger.value == 'hook';

  /// Vérifie si le déclencheur est de type webhook
  bool get isWebhookTrigger => trigger.value == 'webhook';

  /// Vérifie si le déclencheur est de type operation
  bool get isOperationTrigger => trigger.value == 'operation';

  /// Vérifie si le déclencheur est de type schedule
  bool get isScheduleTrigger => trigger.value == 'schedule';

  /// Vérifie si le déclencheur est de type manual
  bool get isManualTrigger => trigger.value == 'manual';

  /// Active le flow
  void activate() => status.set('active');

  /// Désactive le flow
  void deactivate() => status.set('inactive');

  /// Obtient un résumé du flow
  String get summary {
    final flowName = name.valueOrNull ?? 'Flow sans nom';
    final flowStatus = isActive ? 'actif' : 'inactif';
    final flowTrigger = trigger.valueOrNull ?? 'trigger inconnu';
    final count = operationsCount;
    return '$flowName ($flowStatus) - Trigger: $flowTrigger - $count opération(s)';
  }
}

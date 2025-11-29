import 'directus_model.dart';
import 'directus_user.dart';
import 'directus_revision.dart';

/// Représente une action d'activité Directus.
///
/// L'activité enregistre toutes les actions effectuées dans Directus, y compris :
/// - Création, modification et suppression d'items
/// - Connexions des utilisateurs
/// - Changements dans les collections
///
/// Exemple d'utilisation :
/// ```dart
/// // Récupérer les activités récentes
/// final activities = await client.activity.getActivities(
///   query: QueryParameters(
///     sort: ['-timestamp'],
///     limit: 50,
///   ),
/// );
///
/// // Filtrer les activités de création
/// final creates = await client.activity.getActivities(
///   query: QueryParameters(
///     filter: Filter.field('action').equals('create'),
///   ),
/// );
///
/// // Récupérer les activités d'un utilisateur spécifique
/// final userActivities = await client.activity.getActivities(
///   query: QueryParameters(
///     filter: Filter.field('user').equals('user-id'),
///   ),
/// );
/// ```
class DirectusActivity<U extends DirectusUser> extends DirectusModel {
  /// Action qui a été effectuée
  /// Valeurs possibles : create, update, delete, login
  late final action = stringValue('action');

  /// Utilisateur qui a effectué cette action (Many-to-One vers users)
  late final user = modelValue<U>('user');

  /// Date et heure de l'action
  late final timestamp = dateTimeValue('timestamp');

  /// Adresse IP de l'utilisateur au moment de l'action
  late final ip = stringValue('ip');

  /// User agent du navigateur au moment de l'action
  late final userAgent = stringValue('user_agent');

  /// Identifiant de la collection dans laquelle l'item réside
  late final collection = stringValue('collection');

  /// Identifiant unique de l'item sur lequel l'action a été appliquée
  /// (toujours une chaîne, même pour les clés primaires entières)
  late final item = stringValue('item');

  /// Commentaire de l'utilisateur
  /// Stocke les commentaires affichés dans la barre latérale droite
  /// de la page d'édition d'item dans l'admin
  late final comment = stringValue('comment');

  /// Origine de la requête au moment de l'action
  late final origin = stringValue('origin');

  /// Révisions associées à cette activité (One-to-Many vers revisions)
  /// Contient les changements effectués dans cette activité
  late final revisions = modelListValue<DirectusRevision>('revisions');

  DirectusActivity(super.data);
  DirectusActivity.empty() : super.empty();

  @override
  String get itemName => 'directus_activity';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusActivity factory(Map<String, dynamic> data) =>
      DirectusActivity(data);

  /// Vérifie si l'action est une création
  bool get isCreate => action.value == 'create';

  /// Vérifie si l'action est une mise à jour
  bool get isUpdate => action.value == 'update';

  /// Vérifie si l'action est une suppression
  bool get isDelete => action.value == 'delete';

  /// Vérifie si l'action est une connexion
  bool get isLogin => action.value == 'login';

  /// Vérifie si l'activité a un commentaire
  bool get hasComment => comment.isNotEmpty;

  /// Vérifie si l'activité a des révisions
  bool get hasRevisions => revisions.isNotEmpty;

  /// Obtient l'utilisateur qui a effectué l'action
  DirectusUser? get actor => user.value;

  /// Obtient le nom complet de l'utilisateur qui a effectué l'action
  String? get actorName => actor?.fullName;

  /// Obtient l'email de l'utilisateur qui a effectué l'action
  String? get actorEmail => actor?.email.valueOrNull;

  /// Formate le timestamp de manière lisible
  String get formattedTimestamp {
    final ts = timestamp.value;
    if (ts == null) return 'Date inconnue';
    return ts.toLocal().toString();
  }

  /// Obtient une description de l'action
  String get actionDescription {
    final actionType = action.value;
    final collectionName = collection.valueOrNull ?? 'collection inconnue';
    final itemId = item.valueOrNull ?? 'item inconnu';

    switch (actionType) {
      case 'create':
        return 'Création dans $collectionName (ID: $itemId)';
      case 'update':
        return 'Mise à jour dans $collectionName (ID: $itemId)';
      case 'delete':
        return 'Suppression dans $collectionName (ID: $itemId)';
      case 'login':
        return 'Connexion utilisateur';
      default:
        return 'Action $actionType dans $collectionName (ID: $itemId)';
    }
  }

  /// Obtient un résumé de l'activité
  String get summary {
    final actor = actorName ?? actorEmail ?? 'Utilisateur inconnu';
    final action = actionDescription;
    final time = formattedTimestamp;
    return '$actor - $action - $time';
  }
}

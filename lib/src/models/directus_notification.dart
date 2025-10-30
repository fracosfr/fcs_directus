import 'directus_model.dart';
import 'directus_user.dart';

/// Représente une notification Directus.
///
/// Les notifications permettent d'envoyer des messages aux utilisateurs
/// dans l'application Directus.
///
/// Exemple d'utilisation :
/// ```dart
/// // Récupérer les notifications de l'inbox
/// final notifications = await client.notifications.getNotifications(
///   query: QueryParameters(
///     filter: Filter.field('status').equals('inbox'),
///     sort: ['-timestamp'],
///   ),
/// );
///
/// // Marquer une notification comme archivée
/// await client.notifications.updateNotification(
///   'notification-id',
///   {'status': 'archived'},
/// );
/// ```
class DirectusNotification extends DirectusModel {
  /// Timestamp de création de la notification
  late final timestamp = dateTimeValue('timestamp');

  /// Statut actuel de la notification (inbox, archived)
  late final status = stringValue('status');

  /// Utilisateur qui a reçu la notification (Many-to-One vers users)
  late final recipient = stringValue('recipient');

  /// Utilisateur qui a envoyé la notification (Many-to-One vers users)
  late final sender = stringValue('sender');

  /// Sujet du message
  late final subject = stringValue('subject');

  /// Corps du message
  late final message = stringValue('message');

  /// Collection référencée par cette notification
  late final collection = stringValue('collection');

  /// ID de l'item référencé par cette notification
  late final item = stringValue('item');

  DirectusNotification(super.data);
  DirectusNotification.empty() : super.empty();

  @override
  String get itemName => 'directus_notifications';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusNotification factory(Map<String, dynamic> data) =>
      DirectusNotification(data);

  /// Vérifie si la notification est dans l'inbox
  bool get isInInbox => status.value == 'inbox';

  /// Vérifie si la notification est archivée
  bool get isArchived => status.value == 'archived';

  /// Obtient l'utilisateur destinataire
  DirectusUser? get recipientUser =>
      getDirectusModelOrNull<DirectusUser>('recipient');

  /// Obtient l'utilisateur expéditeur
  DirectusUser? get senderUser =>
      getDirectusModelOrNull<DirectusUser>('sender');

  /// Obtient le nom du destinataire
  String? get recipientName => recipientUser?.fullName;

  /// Obtient le nom de l'expéditeur
  String? get senderName => senderUser?.fullName;

  /// Vérifie si la notification a un sujet
  bool get hasSubject => subject.isNotEmpty;

  /// Vérifie si la notification a un message
  bool get hasMessage => message.isNotEmpty;

  /// Formate le timestamp de manière lisible
  String get formattedTimestamp {
    final ts = timestamp.value;
    if (ts == null) return 'Date inconnue';
    return ts.toLocal().toString();
  }

  /// Archive la notification
  void archive() => status.set('archived');

  /// Obtient un résumé de la notification
  String get summary {
    final from = senderName ?? 'Système';
    final subj = subject.valueOrNull ?? 'Notification';
    final date = formattedTimestamp;
    final stat = isArchived ? ' [archivée]' : '';
    return '$from: $subj - $date$stat';
  }
}

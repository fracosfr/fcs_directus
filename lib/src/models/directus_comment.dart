import 'directus_model.dart';
import 'directus_user.dart';

/// Représente un commentaire Directus.
///
/// Les commentaires permettent aux utilisateurs de collaborer sur les items
/// dans Directus. Ils apparaissent dans la barre latérale droite de la page
/// d'édition d'item dans le Data Studio.
///
/// Exemple d'utilisation :
/// ```dart
/// // Créer un commentaire sur un article
/// final comment = DirectusComment.empty()
///   ..collection.set('articles')
///   ..item.set('15')
///   ..comment.set('This is a comment on an article');
/// await client.comments.createComment(comment.toMap());
///
/// // Récupérer les commentaires d'un item
/// final comments = await client.comments.getCommentsForItem(
///   collection: 'articles',
///   itemId: '15',
/// );
///
/// // Mettre à jour un commentaire
/// final updatedComment = DirectusComment.empty()
///   ..comment.set('Updated comment text');
/// await client.comments.updateComment('comment-id', updatedComment.toMap());
/// ```
class DirectusComment extends DirectusModel {
  /// Collection dans laquelle l'item réside
  late final collection = stringValue('collection');

  /// L'item sur lequel le commentaire est créé
  late final item = stringValue('item');

  /// Le texte du commentaire
  /// Ce commentaire s'affiche dans la barre latérale droite de la page
  /// d'édition d'item dans le Data Studio
  late final comment = stringValue('comment');

  DirectusComment(super.data);
  DirectusComment.empty() : super.empty();

  @override
  String get itemName => 'directus_comments';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusComment factory(Map<String, dynamic> data) =>
      DirectusComment(data);

  /// Vérifie si le commentaire a du texte
  bool get hasComment => comment.isNotEmpty;

  /// Vérifie si le commentaire appartient à une collection spécifique
  bool isForCollection(String collectionName) =>
      collection.value == collectionName;

  /// Vérifie si le commentaire appartient à un item spécifique
  bool isForItem(String itemId) => item.value == itemId;

  /// Obtient l'utilisateur qui a créé le commentaire
  DirectusUser? get author =>
      getDirectusModelOrNull<DirectusUser>('user_created');

  /// Obtient l'utilisateur qui a mis à jour le commentaire
  DirectusUser? get editor =>
      getDirectusModelOrNull<DirectusUser>('user_updated');

  /// Obtient le nom de l'auteur du commentaire
  String? get authorName => author?.fullName;

  /// Vérifie si le commentaire a été modifié
  bool get isEdited {
    final created = dateCreated;
    final updated = dateUpdated;
    if (created == null || updated == null) return false;
    return !created.isAtSameMomentAs(updated);
  }

  /// Formate la date de création de manière lisible
  String get formattedDateCreated {
    final date = dateCreated;
    if (date == null) return 'Date inconnue';
    return date.toLocal().toString();
  }

  /// Formate la date de mise à jour de manière lisible
  String get formattedDateUpdated {
    final date = dateUpdated;
    if (date == null) return 'Date inconnue';
    return date.toLocal().toString();
  }

  /// Obtient un résumé du commentaire
  String get summary {
    final author = authorName ?? 'Utilisateur inconnu';
    final text = comment.valueOrNull ?? 'Commentaire vide';
    final date = formattedDateCreated;
    final edited = isEdited ? ' (édité)' : '';
    return '$author - $date$edited: $text';
  }
}

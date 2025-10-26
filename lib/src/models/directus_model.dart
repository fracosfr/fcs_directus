/// Classe de base pour tous les modèles Directus.
///
/// Cette classe fournit les fonctionnalités de base pour la sérialisation
/// et la désérialisation JSON. Tous les modèles personnalisés devraient
/// hériter de cette classe.
///
/// Exemple d'utilisation:
/// ```dart
/// class Article extends DirectusModel {
///   final String title;
///   final String? content;
///   final String status;
///
///   Article({
///     String? id,
///     required this.title,
///     this.content,
///     this.status = 'draft',
///     DateTime? dateCreated,
///     DateTime? dateUpdated,
///   }) : super(
///           id: id,
///           dateCreated: dateCreated,
///           dateUpdated: dateUpdated,
///         );
///
///   @override
///   Map<String, dynamic> toMap() {
///     return {
///       'title': title,
///       if (content != null) 'content': content,
///       'status': status,
///     };
///   }
///
///   factory Article.fromJson(Map<String, dynamic> json) {
///     return Article(
///       id: json['id']?.toString(),
///       title: json['title'] as String,
///       content: json['content'] as String?,
///       status: json['status'] as String? ?? 'draft',
///       dateCreated: DirectusModel.parseDate(json['date_created']),
///       dateUpdated: DirectusModel.parseDate(json['date_updated']),
///     );
///   }
/// }
/// ```
abstract class DirectusModel {
  /// Identifiant unique de l'item
  final String? id;

  /// Date de création (champ standard Directus)
  final DateTime? dateCreated;

  /// Date de dernière modification (champ standard Directus)
  final DateTime? dateUpdated;

  /// Crée un nouveau modèle Directus
  DirectusModel({this.id, this.dateCreated, this.dateUpdated});

  /// Convertit le modèle en Map pour l'envoi à l'API.
  ///
  /// Cette méthode doit être implémentée par les classes enfants
  /// pour retourner uniquement les champs spécifiques au modèle.
  /// Les champs de base (id, dates) sont gérés automatiquement.
  Map<String, dynamic> toMap();

  /// Convertit le modèle complet en JSON.
  ///
  /// Combine les champs de base avec les champs spécifiques
  /// retournés par [toMap].
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      ...toMap(),
      if (dateCreated != null) 'date_created': dateCreated!.toIso8601String(),
      if (dateUpdated != null) 'date_updated': dateUpdated!.toIso8601String(),
    };
  }

  /// Helper pour parser une date depuis JSON.
  ///
  /// Gère les valeurs null et les différents formats de date.
  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Helper pour parser un ID depuis JSON.
  ///
  /// Convertit n'importe quel type en String.
  static String? parseId(dynamic value) {
    return value?.toString();
  }

  @override
  String toString() {
    return '$runtimeType(id: $id)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DirectusModel &&
        other.runtimeType == runtimeType &&
        other.id == id;
  }

  @override
  int get hashCode => id.hashCode ^ runtimeType.hashCode;
}

import 'directus_model.dart';

/// Mixin qui fournit des méthodes pour la sérialisation/désérialisation automatique.
///
/// Ce mixin utilise un système de mappers pour convertir automatiquement
/// les données JSON en objets Dart et vice-versa.
///
/// Exemple d'utilisation:
/// ```dart
/// class Article extends DirectusModel with DirectusSerializable<Article> {
///   final String title;
///   final String? content;
///   final String status;
///
///   Article({
///     super.id,
///     required this.title,
///     this.content,
///     this.status = 'draft',
///     super.dateCreated,
///     super.dateUpdated,
///   });
///
///   @override
///   Article fromJsonTyped(Map<String, dynamic> json) => Article(
///     id: DirectusModel.parseId(json['id']),
///     title: json['title'] as String,
///     content: json['content'] as String?,
///     status: json['status'] as String? ?? 'draft',
///     dateCreated: DirectusModel.parseDate(json['date_created']),
///     dateUpdated: DirectusModel.parseDate(json['date_updated']),
///   );
///
///   @override
///   Map<String, dynamic> toMap() => {
///     'title': title,
///     if (content != null) 'content': content,
///     'status': status,
///   };
/// }
/// ```
mixin DirectusSerializable<T extends DirectusModel> on DirectusModel {
  /// Crée une instance de T depuis JSON.
  ///
  /// Cette méthode doit être implémentée par les classes enfants.
  T fromJsonTyped(Map<String, dynamic> json);

  /// Crée une instance depuis JSON (wrapper type-safe).
  static T fromJson<T extends DirectusModel>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) factory,
  ) {
    return factory(json);
  }
}

/// Classe utilitaire pour enregistrer et récupérer des factories de modèles.
///
/// Permet de créer des instances de modèles sans avoir à passer
/// la factory à chaque fois.
///
/// Exemple:
/// ```dart
/// // Enregistrement
/// DirectusModelRegistry.register<Article>((json) => Article.fromJson(json));
///
/// // Utilisation
/// final article = DirectusModelRegistry.create<Article>(jsonData);
/// ```
class DirectusModelRegistry {
  static final Map<Type, Function> _factories = {};

  /// Enregistre une factory pour un type de modèle.
  static void register<T extends DirectusModel>(
    T Function(Map<String, dynamic>) factory,
  ) {
    _factories[T] = factory;
  }

  /// Crée une instance d'un modèle depuis JSON.
  static T create<T extends DirectusModel>(Map<String, dynamic> json) {
    final factory = _factories[T];
    if (factory == null) {
      throw Exception(
        'No factory registered for type $T. '
        'Call DirectusModelRegistry.register<$T>() first.',
      );
    }
    return factory(json) as T;
  }

  /// Crée une liste d'instances depuis une liste JSON.
  static List<T> createList<T extends DirectusModel>(List<dynamic> jsonList) {
    return jsonList
        .map((json) => create<T>(json as Map<String, dynamic>))
        .toList();
  }

  /// Vérifie si une factory est enregistrée pour un type.
  static bool isRegistered<T extends DirectusModel>() {
    return _factories.containsKey(T);
  }

  /// Supprime une factory enregistrée.
  static void unregister<T extends DirectusModel>() {
    _factories.remove(T);
  }

  /// Supprime toutes les factories enregistrées.
  static void clear() {
    _factories.clear();
  }
}

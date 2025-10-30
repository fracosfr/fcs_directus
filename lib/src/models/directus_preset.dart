import 'directus_model.dart';
import 'directus_user.dart';
import 'directus_role.dart';

/// Représente un preset (signets et préférences) Directus.
///
/// Les presets stockent les préférences de l'utilisateur pour les collections,
/// comme les filtres, le tri, la mise en page, etc. Ils peuvent aussi servir
/// de signets (bookmarks).
///
/// Exemple d'utilisation :
/// ```dart
/// // Créer un signet
/// final preset = DirectusPreset.empty()
///   ..collection.set('articles')
///   ..bookmark.set('Articles publiés')
///   ..search.set('published')
///   ..layout.set('tabular')
///   ..layoutQuery.set({'sort': ['-published_on']});
/// await client.presets.createPreset(preset.toMap());
///
/// // Récupérer les signets d'un utilisateur
/// final bookmarks = await client.presets.getBookmarks('user-id');
/// ```
class DirectusPreset extends DirectusModel {
  /// Nom du signet (si défini, le preset est considéré comme un signet)
  late final bookmark = stringValue('bookmark');

  /// Utilisateur auquel ce preset s'applique (Many-to-One vers users)
  late final user = stringValue('user');

  /// Rôle auquel ce preset s'applique si user est null (Many-to-One vers roles)
  late final role = stringValue('role');

  /// Collection pour laquelle ce preset est utilisé
  late final collection = stringValue('collection');

  /// Requête de recherche
  late final search = stringValue('search');

  /// Clé de la mise en page utilisée
  late final layout = stringValue('layout');

  /// Requête de mise en page sauvegardée par type de mise en page
  /// Contrôle quelles données sont récupérées au chargement
  late final layoutQuery = objectValue('layout_query');

  /// Options des vues (contrôlées par la mise en page)
  late final layoutOptions = objectValue('layout_options');

  /// Filtres appliqués
  late final filters = listValue<Map<String, dynamic>>('filters');

  DirectusPreset(super.data);
  DirectusPreset.empty() : super.empty();

  @override
  String get itemName => 'directus_presets';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusPreset factory(Map<String, dynamic> data) =>
      DirectusPreset(data);

  /// Vérifie si c'est un signet (bookmark)
  bool get isBookmark => bookmark.isNotEmpty;

  /// Vérifie si le preset est pour un utilisateur spécifique
  bool get isUserSpecific => user.isNotEmpty;

  /// Vérifie si le preset est pour un rôle
  bool get isRoleSpecific => role.isNotEmpty && user.valueOrNull == null;

  /// Vérifie si le preset est global
  bool get isGlobal => user.valueOrNull == null && role.valueOrNull == null;

  /// Obtient l'utilisateur associé
  DirectusUser? get userObject => getDirectusModelOrNull<DirectusUser>('user');

  /// Obtient le rôle associé
  DirectusRole? get roleObject => getDirectusModelOrNull<DirectusRole>('role');

  /// Vérifie si le preset a une recherche
  bool get hasSearch => search.isNotEmpty;

  /// Vérifie si le preset a une mise en page
  bool get hasLayout => layout.isNotEmpty;

  /// Vérifie si le preset a des options de mise en page
  bool get hasLayoutQuery =>
      layoutQuery.exists && (layoutQuery.value?.isNotEmpty ?? false);

  /// Vérifie si le preset a des options de vue
  bool get hasLayoutOptions =>
      layoutOptions.exists && (layoutOptions.value?.isNotEmpty ?? false);

  /// Vérifie si le preset a des filtres
  bool get hasFilters => filters.isNotEmpty;

  /// Obtient le nom d'affichage du preset
  String get displayName {
    final bookmarkName = bookmark.valueOrNull;
    if (bookmarkName != null) return bookmarkName;
    final coll = collection.valueOrNull ?? 'collection';
    if (isUserSpecific) return 'Preset pour $coll (utilisateur)';
    if (isRoleSpecific) return 'Preset pour $coll (rôle)';
    return 'Preset pour $coll (global)';
  }

  /// Obtient un résumé du preset
  String get summary {
    final name = displayName;
    final type = isBookmark ? 'Signet' : 'Preset';
    final coll = collection.valueOrNull ?? 'collection inconnue';
    return '$type: $name - Collection: $coll';
  }
}

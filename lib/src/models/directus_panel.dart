import 'directus_model.dart';
import 'directus_user.dart';

/// Représente un panel Directus pour les dashboards.
///
/// Les panels sont des widgets configurables qui affichent des données
/// dans les dashboards du module Insights de Directus.
///
/// Exemple d'utilisation :
/// ```dart
/// // Créer un panel pour un dashboard
/// final panel = DirectusPanel.empty()
///   ..dashboard.set('dashboard-id')
///   ..name.set('30-day sales')
///   ..type.set('time-series')
///   ..icon.set('paid')
///   ..color.set('#6B8068')
///   ..positionX.set(1)
///   ..positionY.set(1)
///   ..width.set(12)
///   ..height.set(8)
///   ..showHeader.set(true)
///   ..options.set({'collection': 'sales', 'dateField': 'date'});
/// ```
class DirectusPanel extends DirectusModel {
  /// Dashboard où ce panel est visible (Many-to-One vers dashboards)
  late final dashboard = stringValue('dashboard');

  /// Nom du panel
  late final name = stringValue('name');

  /// Icône Material Design pour le panel
  late final icon = stringValue('icon');

  /// Couleur d'accent du panel (format hexcode)
  late final color = stringValue('color');

  /// Si l'en-tête doit être affiché pour ce panel
  late final showHeader = boolValue('show_header');

  /// Description du panel
  late final note = stringValue('note');

  /// Type de panel utilisé
  /// Exemples: time-series, metric, list, label, etc.
  late final type = stringValue('type');

  /// Position X sur la grille de l'espace de travail
  late final positionX = intValue('position_x');

  /// Position Y sur la grille de l'espace de travail
  late final positionY = intValue('position_y');

  /// Largeur du panel en nombre de points de grille
  late final width = intValue('width');

  /// Hauteur du panel en nombre de points de grille
  late final height = intValue('height');

  /// Options spécifiques au type de panel
  late final options = objectValue('options');

  DirectusPanel(super.data);
  DirectusPanel.empty() : super.empty();

  @override
  String get itemName => 'directus_panels';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusPanel factory(Map<String, dynamic> data) =>
      DirectusPanel(data);

  /// Vérifie si le panel a une description
  bool get hasNote => note.isNotEmpty;

  /// Vérifie si le panel affiche son en-tête
  bool get hasHeader => showHeader.value == true;

  /// Vérifie si le panel a des options configurées
  bool get hasOptions => options.exists && (options.value?.isNotEmpty ?? false);

  /// Obtient l'utilisateur qui a créé le panel
  DirectusUser? get creator =>
      getDirectusModelOrNull<DirectusUser>('user_created');

  /// Obtient le nom du créateur du panel
  String? get creatorName => creator?.fullName;

  /// Calcule la surface occupée par le panel
  int get area => (width.value) * (height.value);

  /// Vérifie si le panel est de type série temporelle
  bool get isTimeSeries => type.value == 'time-series';

  /// Vérifie si le panel est de type métrique
  bool get isMetric => type.value == 'metric';

  /// Vérifie si le panel est de type liste
  bool get isList => type.value == 'list';

  /// Vérifie si le panel est de type label
  bool get isLabel => type.value == 'label';

  /// Formate la date de création de manière lisible
  String get formattedDateCreated {
    final date = dateCreated;
    if (date == null) return 'Date inconnue';
    return date.toLocal().toString();
  }

  /// Obtient un résumé du panel
  String get summary {
    final panelName = name.valueOrNull ?? 'Panel sans nom';
    final panelType = type.valueOrNull ?? 'type inconnu';
    final size = '${width.value}x${height.value}';
    return '$panelName ($panelType) - Taille: $size';
  }
}

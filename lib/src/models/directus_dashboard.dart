import 'directus_model.dart';
import 'directus_user.dart';
import 'directus_panel.dart';

/// Représente un dashboard Directus.
///
/// Les dashboards font partie du module Insights de Directus et permettent
/// de créer des tableaux de bord personnalisés avec des panels configurables.
///
/// Exemple d'utilisation :
/// ```dart
/// // Créer un dashboard
/// final dashboard = DirectusDashboard.empty()
///   ..name.set('My dashboard')
///   ..icon.set('space_dashboard')
///   ..color.set('#6644FF')
///   ..note.set('Test');
/// await client.dashboards.createDashboard(dashboard.toMap());
///
/// // Récupérer un dashboard avec ses panels
/// final dashboard = await client.dashboards.getDashboard(
///   'dashboard-id',
///   query: QueryParameters()
///     ..fields = ['*', 'panels.*'],
/// );
///
/// final panels = dashboard.panelsList;
/// print('Dashboard has ${panels.length} panels');
/// ```
class DirectusDashboard extends DirectusModel {
  /// Nom du dashboard
  late final name = stringValue('name');

  /// Icône Material Design pour le dashboard
  late final icon = stringValue('icon');

  /// Texte descriptif du dashboard
  late final note = stringValue('note');

  /// Couleur d'accent pour le dashboard (format hexcode)
  late final color = stringValue('color');

  /// Panels qui sont dans ce dashboard (One-to-Many vers panels)
  late final panels = modelListValue<DirectusPanel>('panels');

  DirectusDashboard(super.data);
  DirectusDashboard.empty() : super.empty();

  @override
  String get itemName => 'directus_dashboards';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusDashboard factory(Map<String, dynamic> data) =>
      DirectusDashboard(data);

  /// Vérifie si le dashboard a une description
  bool get hasNote => note.isNotEmpty;

  /// Vérifie si le dashboard a des panels
  bool get hasPanels => panels.isNotEmpty;

  /// Obtient la liste des panels
  List<DirectusPanel> get panelsList => panels.value;

  /// Obtient le nombre de panels
  int get panelsCount => panels.value.length;

  /// Obtient l'utilisateur qui a créé le dashboard
  DirectusUser? get creator =>
      getDirectusModelOrNull<DirectusUser>('user_created');

  /// Obtient le nom du créateur du dashboard
  String? get creatorName => creator?.fullName;

  /// Formate la date de création de manière lisible
  String get formattedDateCreated {
    final date = dateCreated;
    if (date == null) return 'Date inconnue';
    return date.toLocal().toString();
  }

  /// Obtient les panels d'un type spécifique
  List<DirectusPanel> getPanelsByType(String type) {
    return panels.value.where((panel) => panel.type.value == type).toList();
  }

  /// Obtient un résumé du dashboard
  String get summary {
    final dashboardName = name.valueOrNull ?? 'Dashboard sans nom';
    final count = panelsCount;
    final date = formattedDateCreated;
    return '$dashboardName - $count panel(s) - Créé le $date';
  }
}

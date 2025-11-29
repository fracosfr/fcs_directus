import '../core/directus_http_client.dart';

/// Service pour gérer les paramètres globaux de Directus.
///
/// Les settings contiennent la configuration globale de l'instance Directus
/// (nom du projet, URL publique, couleurs, logo, etc.).
///
/// Exemple d'utilisation:
/// ```dart
/// // Récupérer les paramètres
/// final settings = await client.settings.getSettings();
/// print('Nom du projet: ${settings['project_name']}');
/// print('URL publique: ${settings['project_url']}');
///
/// // Mettre à jour les paramètres
/// await client.settings.updateSettings({
///   'project_name': 'Mon Projet',
///   'project_color': '#6644FF',
/// });
/// ```
class SettingsService {
  final DirectusHttpClient _httpClient;

  SettingsService(this._httpClient);

  /// Récupère les paramètres globaux de l'instance Directus
  ///
  /// Retourne un objet avec tous les paramètres configurables:
  /// - project_name: Nom du projet
  /// - project_url: URL publique
  /// - project_color: Couleur principale
  /// - project_logo: Logo du projet
  /// - public_foreground: Image de fond de la page de connexion
  /// - public_background: Arrière-plan de la page de connexion
  /// - public_note: Note affichée sur la page de connexion
  /// - auth_login_attempts: Nombre de tentatives de connexion autorisées
  /// - auth_password_policy: Politique de mot de passe
  /// - storage_asset_transform: Transformation des assets
  /// - storage_asset_presets: Présets de transformation
  /// - custom_css: CSS personnalisé
  /// - Et bien d'autres...
  Future<dynamic> getSettings() async {
    final response = await _httpClient.get('/settings');
    return response.data['data'];
  }

  /// Met à jour les paramètres globaux
  ///
  /// [data] Map contenant les paramètres à mettre à jour
  ///
  /// Exemple:
  /// ```dart
  /// await client.settings.updateSettings({
  ///   'project_name': 'Mon Nouveau Projet',
  ///   'project_color': '#FF6644',
  ///   'project_url': 'https://mon-projet.com',
  /// });
  /// ```
  Future<dynamic> updateSettings(Map<String, dynamic> data) async {
    final response = await _httpClient.patch('/settings', data: data);
    return response.data['data'];
  }
}

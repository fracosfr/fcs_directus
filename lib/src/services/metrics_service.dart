import '../core/directus_http_client.dart';

/// Service pour gérer les métriques dans Directus.
///
/// Les métriques fournissent des statistiques sur le serveur Directus.
///
/// Exemple d'utilisation:
/// ```dart
/// // Récupérer les métriques du serveur
/// final metrics = await client.metrics.getMetrics();
/// print('Version: ${metrics['directus']['version']}');
/// print('Uptime: ${metrics['uptime']}');
/// ```
class MetricsService {
  final DirectusHttpClient _httpClient;

  MetricsService(this._httpClient);

  /// Récupère les métriques du serveur Directus
  ///
  /// Retourne des informations sur:
  /// - Version de Directus
  /// - Uptime du serveur
  /// - Statistiques de performance
  /// - Utilisation des ressources
  Future<dynamic> getMetrics() async {
    return await _httpClient.get('/metrics');
  }
}

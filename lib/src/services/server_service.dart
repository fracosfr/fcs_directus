import '../core/directus_http_client.dart';

/// Service pour récupérer les informations du serveur Directus.
///
/// Ce service fournit des endpoints pour vérifier l'état du serveur,
/// obtenir des informations sur la version et les spécifications.
///
/// Exemple d'utilisation:
/// ```dart
/// // Vérifier la santé du serveur
/// final health = await client.server.health();
/// print('Status: ${health['status']}');
///
/// // Obtenir les informations du serveur
/// final info = await client.server.info();
/// print('Version: ${info['directus']['version']}');
///
/// // Ping le serveur
/// final pong = await client.server.ping();
/// print('Pong: $pong');
///
/// // Récupérer les spécifications OpenAPI
/// final specs = await client.server.specs();
/// ```
class ServerService {
  final DirectusHttpClient _httpClient;

  ServerService(this._httpClient);

  /// Vérifie l'état de santé du serveur et de la base de données
  ///
  /// Retourne un objet avec le status 'ok' ou 'error'
  Future<dynamic> health() async {
    return await _httpClient.get('/server/health');
  }

  /// Récupère les informations détaillées du serveur
  ///
  /// Retourne des informations sur:
  /// - Version de Directus
  /// - Version de Node.js
  /// - Système d'exploitation
  /// - Extensions installées
  Future<dynamic> info() async {
    return await _httpClient.get('/server/info');
  }

  /// Ping simple pour vérifier que le serveur répond
  ///
  /// Retourne 'pong'
  Future<String> ping() async {
    final response = await _httpClient.get('/server/ping');
    return response.toString();
  }

  /// Récupère les spécifications OpenAPI du serveur
  ///
  /// Retourne le schéma OpenAPI complet de l'API Directus
  Future<dynamic> specs() async {
    return await _httpClient.get('/server/specs/oas');
  }
}

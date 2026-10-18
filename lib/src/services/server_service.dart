import 'package:dio/dio.dart';

import '../core/directus_http_client.dart';

/// Service pour récupérer les informations du serveur Directus (`/server/*`).
///
/// Exemple d'utilisation:
/// ```dart
/// // Ping (public) : idéal pour un health-check sans authentification
/// final pong = await client.server.ping(); // 'pong'
///
/// // Santé (authentification requise depuis Directus 12)
/// final health = await client.server.health();
/// print('Status: ${health['status']}');
///
/// // Informations du projet
/// final info = await client.server.info();
/// print('Version: ${info['version']}');
///
/// // Spécifications OpenAPI / GraphQL
/// final oas = await client.server.specs();
/// final sdl = await client.server.graphqlSdl(system: true);
/// ```
class ServerService {
  final DirectusHttpClient _httpClient;

  ServerService(this._httpClient);

  /// État de santé du serveur (`GET /server/health`).
  ///
  /// Depuis Directus 12 l'endpoint exige une authentification : un admin
  /// reçoit le rapport complet (`checks`), un non-admin uniquement `status`.
  /// Un statut `error` est renvoyé avec un code HTTP 503, il est retourné
  /// ici sans lever d'exception.
  Future<Map<String, dynamic>> health() async {
    final response = await _httpClient.get(
      '/server/health',
      options: Options(
        validateStatus: (s) => s != null && (s < 400 || s == 503),
      ),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Informations du projet (`GET /server/info`).
  ///
  /// Contient `project` (nom, logo, couleurs...) et, selon les droits,
  /// `version`, `rateLimit`, `queryLimit`, `websocket`, `extensions`...
  Future<Map<String, dynamic>> info() async {
    final response = await _httpClient.get('/server/info');
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// Ping public (`GET /server/ping`) ; retourne `pong`.
  Future<String> ping() async {
    final response = await _httpClient.get<String>(
      '/server/ping',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  /// Spécification OpenAPI du projet (`GET /server/specs/oas`).
  Future<Map<String, dynamic>> specs() async {
    final response = await _httpClient.get('/server/specs/oas');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Schéma GraphQL SDL (`GET /server/specs/graphql/{scope}`).
  ///
  /// [system] `true` pour le schéma des collections système (`/graphql/system`).
  Future<String> graphqlSdl({bool system = false}) async {
    final response = await _httpClient.get<String>(
      '/server/specs/graphql/${system ? 'system' : 'items'}',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  /// Initialise un projet vierge en créant le premier administrateur
  /// (`POST /server/setup`). Disponible uniquement tant qu'aucun admin n'existe.
  ///
  /// [projectUsage] `personal`, `commercial` ou `community`.
  Future<void> setup({
    required String adminEmail,
    required String adminPassword,
    String? adminFirstName,
    String? adminLastName,
    String? licenseKey,
    String? projectOwner,
    String? projectUsage,
    String? orgName,
    bool productUpdates = false,
  }) async {
    await _httpClient.post(
      '/server/setup',
      data: {
        'admin': {
          'email': adminEmail,
          'password': adminPassword,
          if (adminFirstName != null) 'first_name': adminFirstName,
          if (adminLastName != null) 'last_name': adminLastName,
        },
        if (licenseKey != null) 'license_key': licenseKey,
        if (projectOwner != null || projectUsage != null || orgName != null)
          'owner': {
            'project_owner': projectOwner,
            'project_usage': projectUsage,
            'org_name': orgName,
            'product_updates': productUpdates,
          },
      },
    );
  }
}

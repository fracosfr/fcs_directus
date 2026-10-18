import '../core/directus_http_client.dart';
import 'items_service.dart';

/// Service des déploiements (`/deployments`) : intégration avec des
/// hébergeurs (Vercel, Netlify...) pour déclencher et suivre des builds.
///
/// ```dart
/// await client.deployments.create(
///   provider: 'vercel',
///   credentials: {'access_token': '...'},
/// );
/// final projects = await client.deployments.projects('vercel');
/// await client.deployments.deploy('vercel', projectId, preview: true);
/// ```
class DeploymentsService {
  final DirectusHttpClient _httpClient;

  DeploymentsService(this._httpClient);

  /// Liste les configurations de déploiement (`GET /deployments`).
  Future<DirectusResponse<dynamic>> readMany({QueryParameters? query}) async {
    final response = await _httpClient.get(
      '/deployments',
      queryParameters: query?.toQueryParameters(),
    );
    final meta = response.data['meta'];
    return DirectusResponse(
      data: response.data['data'] as List? ?? [],
      meta: meta is Map<String, dynamic> ? DirectusMeta.fromJson(meta) : null,
    );
  }

  /// Crée une configuration pour un fournisseur (`POST /deployments`).
  Future<Map<String, dynamic>> create({
    required String provider,
    required Map<String, dynamic> credentials,
    Map<String, dynamic>? options,
  }) async {
    final response = await _httpClient.post(
      '/deployments',
      data: {
        'provider': provider,
        'credentials': credentials,
        if (options != null) 'options': options,
      },
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// Configuration d'un fournisseur (`GET /deployments/{provider}`).
  Future<Map<String, dynamic>?> read(String provider) async {
    final response = await _httpClient.get('/deployments/$provider');
    final data = response.data['data'];
    return data == null ? null : Map<String, dynamic>.from(data as Map);
  }

  /// Met à jour les identifiants / options (`PATCH /deployments/{provider}`).
  Future<Map<String, dynamic>> update(
    String provider, {
    Map<String, dynamic>? credentials,
    Map<String, dynamic>? options,
  }) async {
    final response = await _httpClient.patch(
      '/deployments/$provider',
      data: {
        if (credentials != null) 'credentials': credentials,
        if (options != null) 'options': options,
      },
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// Supprime la configuration (`DELETE /deployments/{provider}`).
  Future<void> delete(String provider) async {
    await _httpClient.delete('/deployments/$provider');
  }

  /// Projets disponibles chez le fournisseur (`GET /deployments/{provider}/projects`).
  Future<List<dynamic>> projects(String provider) async {
    final response = await _httpClient.get('/deployments/$provider/projects');
    return response.data['data'] as List? ?? [];
  }

  /// Détail d'un projet (`GET /deployments/{provider}/projects/{id}`).
  Future<Map<String, dynamic>> project(String provider, String id) async {
    final response = await _httpClient.get(
      '/deployments/$provider/projects/$id',
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// Sélectionne / retire des projets suivis
  /// (`PATCH /deployments/{provider}/projects`).
  ///
  /// [create] liste de `{external_id, name}`, [delete] liste d'identifiants.
  Future<List<dynamic>> updateProjects(
    String provider, {
    List<Map<String, String>> create = const [],
    List<String> delete = const [],
  }) async {
    final response = await _httpClient.patch(
      '/deployments/$provider/projects',
      data: {'create': create, 'delete': delete},
    );
    return response.data['data'] as List? ?? [];
  }

  /// Tableau de bord des projets suivis (`GET /deployments/{provider}/dashboard`).
  ///
  /// [range] fenêtre de statistiques, ex: `7d`, `24h`.
  Future<dynamic> dashboard(String provider, {String? range}) async {
    final response = await _httpClient.get(
      '/deployments/$provider/dashboard',
      queryParameters: range != null ? {'range': range} : null,
    );
    return response.data['data'];
  }

  /// Déclenche un déploiement (`POST /deployments/{provider}/projects/{id}/deploy`).
  Future<Map<String, dynamic>> deploy(
    String provider,
    String projectId, {
    bool preview = false,
    bool clearCache = true,
  }) async {
    final response = await _httpClient.post(
      '/deployments/$provider/projects/$projectId/deploy',
      data: {'preview': preview, 'clear_cache': clearCache},
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// Historique des builds d'un projet
  /// (`GET /deployments/{provider}/projects/{id}/runs`).
  Future<DirectusResponse<dynamic>> runs(
    String provider,
    String projectId, {
    QueryParameters? query,
  }) async {
    final response = await _httpClient.get(
      '/deployments/$provider/projects/$projectId/runs',
      queryParameters: query?.toQueryParameters(),
    );
    final meta = response.data['meta'];
    return DirectusResponse(
      data: response.data['data'] as List? ?? [],
      meta: meta is Map<String, dynamic> ? DirectusMeta.fromJson(meta) : null,
    );
  }

  /// Statistiques des builds
  /// (`GET /deployments/{provider}/projects/{id}/runs/stats`).
  Future<dynamic> runStats(
    String provider,
    String projectId, {
    String? range,
  }) async {
    final response = await _httpClient.get(
      '/deployments/$provider/projects/$projectId/runs/stats',
      queryParameters: range != null ? {'range': range} : null,
    );
    return response.data['data'];
  }

  /// Détail d'un build, logs inclus (`GET /deployments/{provider}/runs/{id}`).
  ///
  /// [since] ne retourne que les logs postérieurs (polling).
  Future<Map<String, dynamic>> run(
    String provider,
    String runId, {
    DateTime? since,
  }) async {
    final response = await _httpClient.get(
      '/deployments/$provider/runs/$runId',
      queryParameters: since != null
          ? {'since': since.toUtc().toIso8601String()}
          : null,
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// Annule un build (`POST /deployments/{provider}/runs/{id}/cancel`).
  Future<Map<String, dynamic>> cancelRun(String provider, String runId) async {
    final response = await _httpClient.post(
      '/deployments/$provider/runs/$runId/cancel',
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }
}

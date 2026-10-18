import '../core/directus_http_client.dart';
import '../models/directus_settings.dart';
import 'items_service.dart';

/// Service pour les paramètres du projet (`/settings`, singleton).
///
/// ```dart
/// final settings = await client.settings.read();
/// settings.projectName.set('Mon projet');
/// await client.settings.update(settings);
/// ```
class SettingsService {
  final DirectusHttpClient _httpClient;

  SettingsService(this._httpClient);

  /// Lit les paramètres (`GET /settings`).
  Future<DirectusSettings> read({QueryParameters? query}) async {
    final response = await _httpClient.get(
      '/settings',
      queryParameters: query?.toQueryParameters(),
    );
    return DirectusSettings(response.data['data'] as Map<String, dynamic>);
  }

  /// Met à jour les paramètres modifiés (`PATCH /settings`).
  Future<DirectusSettings> update(DirectusSettings settings) async {
    final response = await _httpClient.patch(
      '/settings',
      data: settings.toJsonDirty(),
    );
    return DirectusSettings(response.data['data'] as Map<String, dynamic>);
  }

  /// Enregistre le propriétaire du projet (`POST /settings/owner`).
  ///
  /// [projectUsage] `personal`, `commercial` ou `community`.
  Future<void> setOwner({
    required String projectOwner,
    String? projectUsage,
    String? orgName,
    bool productUpdates = false,
  }) async {
    await _httpClient.post(
      '/settings/owner',
      data: {
        'project_owner': projectOwner,
        'project_usage': projectUsage,
        'org_name': orgName,
        'product_updates': productUpdates,
      },
    );
  }

  /// Lit les paramètres sous forme de Map.
  Future<dynamic> getSettings() async {
    final response = await _httpClient.get('/settings');
    return response.data['data'];
  }

  /// Met à jour les paramètres depuis une Map.
  Future<dynamic> updateSettings(Map<String, dynamic> data) async {
    final response = await _httpClient.patch('/settings', data: data);
    return response.data['data'];
  }
}

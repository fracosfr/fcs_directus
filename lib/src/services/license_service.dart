import '../core/directus_http_client.dart';

/// Service de gestion de la licence Directus (`/license`, admin uniquement).
///
/// ```dart
/// final license = await client.license.read();
/// print(license['tier']);
/// await client.license.activate('DIRECTUS-XXXX');
/// ```
class LicenseService {
  final DirectusHttpClient _httpClient;

  LicenseService(this._httpClient);

  /// État de la licence (`GET /license`) : tier, entitlements, `invalid_reason`,
  /// `token_expires_at`...
  Future<Map<String, dynamic>> read() async {
    final response = await _httpClient.get('/license');
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// Active une clé de licence (`POST /license`).
  Future<void> activate(String licenseKey) async {
    await _httpClient.post('/license', data: {'license_key': licenseKey});
  }

  /// Remplace la clé de licence (`PATCH /license`).
  Future<void> update(String licenseKey) async {
    await _httpClient.patch('/license', data: {'license_key': licenseKey});
  }

  /// Retire la licence (`DELETE /license`).
  Future<void> remove() async {
    await _httpClient.delete('/license');
  }

  /// Prévisualise une clé sans l'activer (`POST /license/preview`).
  Future<Map<String, dynamic>> preview(String licenseKey) async {
    final response = await _httpClient.post(
      '/license/preview',
      data: {'license_key': licenseKey},
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// URL du portail de gestion de la licence (`GET /license/portal`).
  Future<dynamic> portal() async {
    final response = await _httpClient.get('/license/portal');
    return response.data?['data'] ?? response.data;
  }

  /// Add-ons disponibles (`GET /license/addons`).
  Future<dynamic> addons() async {
    final response = await _httpClient.get('/license/addons');
    return response.data['data'];
  }

  /// Définit la quantité d'un add-on (`PATCH /license/addons/{id}`).
  Future<void> setAddonQuantity(String addonId, int quantity) async {
    await _httpClient.patch(
      '/license/addons/$addonId',
      data: {'quantity': quantity},
    );
  }

  /// Retire un add-on (`DELETE /license/addons/{id}`).
  Future<void> removeAddon(String addonId) async {
    await _httpClient.delete('/license/addons/$addonId');
  }

  /// Résolution en attente pour une clé (`POST /license/pending-resolution`).
  Future<dynamic> pendingResolution({String? licenseKey}) async {
    final response = await _httpClient.post(
      '/license/pending-resolution',
      data: {if (licenseKey != null) 'license_key': licenseKey},
    );
    return response.data?['data'];
  }

  /// Résout un conflit de licence (`POST /license/resolve`).
  /// [payload] est transmis tel quel (schéma `ResolveInput` de Directus).
  Future<dynamic> resolve(Map<String, dynamic> payload) async {
    final response = await _httpClient.post('/license/resolve', data: payload);
    return response.data?['data'];
  }
}

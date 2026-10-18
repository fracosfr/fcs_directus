import '../core/directus_http_client.dart';

/// Service pour gérer les extensions Directus (`/extensions`).
///
/// Chaque extension (et chaque entrée d'un bundle) est identifiée par un UUID
/// (`id`) : c'est cet identifiant qui est utilisé pour la mise à jour.
///
/// Exemple d'utilisation:
/// ```dart
/// // Lister les extensions installées
/// final extensions = await client.extensions.getExtensions();
/// final ext = extensions.firstWhere((e) => e['schema']?['name'] == 'my-ext');
///
/// // Désactiver une extension
/// await client.extensions.updateExtension(ext['id'], {'enabled': false});
///
/// // Marketplace
/// final results = await client.extensions.searchRegistry(search: 'seo');
/// await client.extensions.install(extensionId: 'uuid', version: 'uuid');
/// ```
class ExtensionsService {
  final DirectusHttpClient _httpClient;

  ExtensionsService(this._httpClient);

  /// Liste les extensions installées (`GET /extensions`).
  Future<List<Map<String, dynamic>>> getExtensions() async {
    final response = await _httpClient.get('/extensions');
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// Met à jour la configuration d'une extension (`PATCH /extensions/{id}`).
  ///
  /// [id] UUID de l'extension (champ `id` de [getExtensions])
  /// [meta] Configuration, ex: `{'enabled': false}`
  Future<Map<String, dynamic>> updateExtension(
    String id,
    Map<String, dynamic> meta,
  ) async {
    final response = await _httpClient.patch(
      '/extensions/$id',
      data: {'meta': meta},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Les entrées de bundle ont désormais leur propre UUID.
  @Deprecated('Utiliser updateExtension(id, meta) avec l\'UUID de l\'entrée.')
  Future<Map<String, dynamic>> updateExtensionInBundle(
    String bundle,
    String name,
    Map<String, dynamic> meta,
  ) async {
    final extensions = await getExtensions();
    final entry = extensions.firstWhere(
      (e) => e['bundle'] != null && e['schema']?['name'] == name,
      orElse: () => throw ArgumentError('Extension $bundle/$name introuvable'),
    );
    return updateExtension(entry['id'] as String, meta);
  }

  /// Supprime une extension installée localement (`DELETE /extensions/{id}`).
  Future<void> deleteExtension(String id) async {
    await _httpClient.delete('/extensions/$id');
  }

  /// Recherche dans le marketplace (`GET /extensions/registry`).
  ///
  /// Retourne `{data: [...], meta: {filter_count}}`.
  Future<Map<String, dynamic>> searchRegistry({
    String? search,
    String? type,
    String? sort,
    int? limit,
    int? offset,
  }) async {
    final response = await _httpClient.get(
      '/extensions/registry',
      queryParameters: {
        if (search != null) 'search': search,
        if (type != null) 'type': type,
        if (sort != null) 'sort': sort,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Détail d'une extension du marketplace
  /// (`GET /extensions/registry/extension/{id}`).
  Future<Map<String, dynamic>> getRegistryExtension(String id) async {
    final response = await _httpClient.get(
      '/extensions/registry/extension/$id',
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Profil d'un éditeur du marketplace
  /// (`GET /extensions/registry/account/{id}`).
  Future<Map<String, dynamic>> getRegistryAccount(String id) async {
    final response = await _httpClient.get('/extensions/registry/account/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Installe une extension du marketplace (`POST /extensions/registry/install`).
  ///
  /// [extensionId] UUID de l'extension, [version] UUID de la version.
  Future<void> install({
    required String extensionId,
    required String version,
  }) async {
    await _httpClient.post(
      '/extensions/registry/install',
      data: {'extension': extensionId, 'version': version},
    );
  }

  /// Réinstalle une extension (`POST /extensions/registry/reinstall`).
  Future<void> reinstall(String extensionId) async {
    await _httpClient.post(
      '/extensions/registry/reinstall',
      data: {'extension': extensionId},
    );
  }

  /// Désinstalle une extension du marketplace
  /// (`DELETE /extensions/registry/uninstall/{id}`).
  Future<void> uninstall(String id) async {
    await _httpClient.delete('/extensions/registry/uninstall/$id');
  }

  /// Filtre les extensions installées par type (`interface`, `display`...).
  Future<List<Map<String, dynamic>>> getExtensionsByType(String type) async {
    final extensions = await getExtensions();
    return extensions
        .where((ext) => ext['type'] == type || ext['schema']?['type'] == type)
        .toList();
  }

  /// Vérifie si une extension est installée (par nom).
  Future<bool> isExtensionInstalled(String name) async {
    final extensions = await getExtensions();
    return extensions.any(
      (ext) => ext['name'] == name || ext['schema']?['name'] == name,
    );
  }
}

import '../core/directus_http_client.dart';

/// Service pour gérer les extensions dans Directus.
///
/// Directus peut être facilement étendu par l'ajout de plusieurs types d'extensions,
/// y compris les layouts, interfaces et modules.
///
/// Note: Les extensions sont généralement en lecture seule via l'API,
/// avec possibilité de mise à jour de la configuration seulement.
///
/// Exemple d'utilisation:
/// ```dart
/// // Lister toutes les extensions
/// final extensions = await client.extensions.getExtensions();
///
/// // Mettre à jour la configuration d'une extension
/// await client.extensions.updateExtension(
///   'my-extension',
///   {'enabled': true},
/// );
/// ```
class ExtensionsService {
  final DirectusHttpClient _httpClient;

  ExtensionsService(this._httpClient);

  /// Récupère la liste de toutes les extensions installées
  ///
  /// Liste les extensions installées et leur configuration dans le projet.
  ///
  /// Exemple:
  /// ```dart
  /// final extensions = await client.extensions.getExtensions();
  /// for (var ext in extensions) {
  ///   print('Extension: ${ext['name']} - Bundle: ${ext['bundle']}');
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> getExtensions() async {
    final response = await _httpClient.get('/extensions');
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// Met à jour la configuration d'une extension
  ///
  /// [name] Nom de l'extension
  /// [meta] Métadonnées Directus pour l'extension (configuration)
  ///
  /// Exemple:
  /// ```dart
  /// await client.extensions.updateExtension(
  ///   'my-custom-interface',
  ///   {
  ///     'meta': {
  ///       'enabled': true,
  ///       'config': {'theme': 'dark'},
  ///     },
  ///   },
  /// );
  /// ```
  Future<Map<String, dynamic>> updateExtension(
    String name,
    Map<String, dynamic> meta,
  ) async {
    final response = await _httpClient.patch(
      '/extensions/$name',
      data: {'meta': meta},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Met à jour la configuration d'une extension dans un bundle
  ///
  /// [bundle] Nom du bundle contenant l'extension
  /// [name] Nom de l'extension dans le bundle
  /// [meta] Métadonnées Directus pour l'extension (configuration)
  ///
  /// Exemple:
  /// ```dart
  /// await client.extensions.updateExtensionInBundle(
  ///   'my-bundle',
  ///   'my-extension',
  ///   {
  ///     'meta': {
  ///       'enabled': false,
  ///     },
  ///   },
  /// );
  /// ```
  Future<Map<String, dynamic>> updateExtensionInBundle(
    String bundle,
    String name,
    Map<String, dynamic> meta,
  ) async {
    final response = await _httpClient.patch(
      '/extensions/$bundle/$name',
      data: {'meta': meta},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Récupère les extensions par type
  ///
  /// Note: Méthode helper qui filtre côté client.
  /// Types possibles: interface, display, layout, module, panel, hook, endpoint, operation, bundle
  Future<List<Map<String, dynamic>>> getExtensionsByType(String type) async {
    final extensions = await getExtensions();
    return extensions
        .where((ext) => ext['type'] == type || ext['schema']?['type'] == type)
        .toList();
  }

  /// Vérifie si une extension est installée
  ///
  /// [name] Nom de l'extension à rechercher
  Future<bool> isExtensionInstalled(String name) async {
    final extensions = await getExtensions();
    return extensions.any((ext) => ext['name'] == name);
  }
}

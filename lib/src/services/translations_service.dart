import '../core/directus_http_client.dart';
import '../models/directus_filter.dart';
import 'items_service.dart';

/// Service pour gérer les traductions dans Directus.
///
/// Les traductions permettent de gérer le contenu multilingue
/// dans Directus.
///
/// Exemple d'utilisation:
/// ```dart
/// // Récupérer toutes les traductions
/// final translations = await client.translations.getTranslations();
///
/// // Créer une traduction
/// final translation = await client.translations.createTranslation({
///   'language': 'fr-FR',
///   'key': 'welcome_message',
///   'value': 'Bienvenue sur notre site',
/// });
///
/// // Récupérer les traductions pour une langue
/// final frTranslations = await client.translations.getLanguageTranslations('fr-FR');
/// ```
class TranslationsService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  TranslationsService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_translations');
  }

  /// Récupère la liste de toutes les traductions
  Future<DirectusResponse<dynamic>> getTranslations({
    QueryParameters? query,
  }) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère une traduction par son ID
  Future<Map<String, dynamic>> getTranslation(
    String id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id, query: query);
  }

  /// Crée une nouvelle traduction
  ///
  /// [data] Données de la traduction:
  /// - language: Code de langue (ex: 'fr-FR', 'en-US')
  /// - key: Clé de la traduction
  /// - value: Valeur traduite
  Future<Map<String, dynamic>> createTranslation(
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.createOne(data);
  }

  /// Met à jour une traduction existante
  Future<Map<String, dynamic>> updateTranslation(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Supprime une traduction
  Future<void> deleteTranslation(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Supprime plusieurs traductions
  Future<void> deleteTranslations(List<String> ids) async {
    await _itemsService.deleteMany(keys: ids);
  }

  // === Méthodes helper ===

  /// Récupère toutes les traductions pour une langue spécifique
  Future<DirectusResponse<dynamic>> getLanguageTranslations(
    String language, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('language').equals(language);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['key'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getTranslations(query: mergedQuery);
  }

  /// Récupère une traduction spécifique par clé et langue
  Future<DirectusResponse<dynamic>> getTranslationByKey(
    String key,
    String language, {
    QueryParameters? query,
  }) async {
    final filter = Filter.and([
      Filter.field('key').equals(key),
      Filter.field('language').equals(language),
    ]);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      limit: 1,
    );
    return await getTranslations(query: mergedQuery);
  }

  /// Récupère toutes les langues disponibles
  Future<List<String>> getAvailableLanguages() async {
    final response = await getTranslations(
      query: QueryParameters(fields: ['language'], limit: -1),
    );

    final languages = <String>{};
    for (final item in response.data) {
      if (item is Map<String, dynamic> && item['language'] != null) {
        languages.add(item['language'] as String);
      }
    }

    return languages.toList()..sort();
  }

  /// Récupère toutes les traductions pour plusieurs langues
  Future<DirectusResponse<dynamic>> getMultipleLanguagesTranslations(
    List<String> languages, {
    QueryParameters? query,
  }) async {
    final filter = Filter.field('language').inList(languages);
    final mergedQuery = QueryParameters(
      filter: query?.filter != null
          ? Filter.and([filter, query!.filter])
          : filter,
      fields: query?.fields,
      sort: query?.sort ?? ['language', 'key'],
      limit: query?.limit,
      offset: query?.offset,
      page: query?.page,
      search: query?.search,
    );
    return await getTranslations(query: mergedQuery);
  }
}

import 'package:dio/dio.dart';

import '../core/directus_http_client.dart';
import 'items_service.dart';

/// Format de fichier pour l'import / export de données.
enum DirectusExportFormat {
  json('application/json'),
  csv('text/csv'),
  csvUtf8('text/csv'),
  xml('text/xml'),
  yaml('text/yaml');

  const DirectusExportFormat(this.mimeType);

  /// Type MIME utilisé pour l'import.
  final String mimeType;

  /// Valeur attendue par l'API (`json`, `csv`, `csv_utf8`, `xml`, `yaml`).
  String get apiValue => this == csvUtf8 ? 'csv_utf8' : name;
}

/// Mode d'import par lot (`POST /utils/import`).
enum DirectusImportMode {
  /// Crée les items (échec sur clé primaire existante).
  add,

  /// Crée ou met à jour les items selon leur clé primaire.
  merge,
}

/// Service pour les utilitaires Directus (`/utils/*`).
///
/// - [random] : chaînes aléatoires
/// - [cache] : vidage du cache
/// - [sort] : réordonnancement manuel
/// - [export], [import], [importBatch] : échanges de données
/// - [revert] : restauration d'une révision
///
/// Exemple d'utilisation:
/// ```dart
/// final token = await client.utilities.random.string(length: 32);
/// await client.utilities.cache.clear(system: true);
///
/// // Exporter vers un fichier de la médiathèque (traitement asynchrone)
/// await client.utilities.export(
///   'articles',
///   format: DirectusExportFormat.csv,
///   query: QueryParameters(filter: Filter.field('status').equals('published')),
///   file: {'title': 'Export articles'},
/// );
///
/// // Importer un fichier CSV
/// await client.utilities.import(
///   'articles',
///   bytes: csvBytes,
///   format: DirectusExportFormat.csv,
/// );
///
/// // Restaurer une révision
/// await client.utilities.revert(42);
/// ```
class UtilitiesService {
  final DirectusHttpClient _httpClient;

  /// Les endpoints `/utils/hash/*` ont été supprimés dans Directus 12.1.
  @Deprecated('Endpoints /utils/hash/* supprimés dans Directus 12.1.')
  late final HashUtility hash;
  late final RandomUtility random;
  late final CacheUtility cache;
  late final SortUtility sort;

  UtilitiesService(this._httpClient) {
    // ignore: deprecated_member_use_from_same_package
    hash = HashUtility(_httpClient);
    random = RandomUtility(_httpClient);
    cache = CacheUtility(_httpClient);
    sort = SortUtility(_httpClient);
  }

  /// Exporte les données d'une collection dans un fichier de la médiathèque
  /// (`POST /utils/export/{collection}`).
  ///
  /// Le traitement est asynchrone côté serveur : la requête retourne
  /// immédiatement et l'utilisateur reçoit une notification à la fin.
  ///
  /// [format] Format du fichier généré
  /// [query] Requête de sélection (par défaut `limit: -1`, toutes les lignes)
  /// [file] Métadonnées du fichier créé (`title`, `folder`, ...)
  Future<void> export(
    String collection, {
    DirectusExportFormat format = DirectusExportFormat.json,
    QueryParameters? query,
    Map<String, dynamic>? file,
  }) async {
    await _httpClient.post(
      '/utils/export/$collection',
      data: {
        'format': format.apiValue,
        'query': _queryToBody(query) ?? {'limit': -1},
        if (file != null) 'file': file,
      },
    );
  }

  /// Importe un fichier (JSON, CSV...) dans une collection
  /// (`POST /utils/import/{collection}`, multipart).
  ///
  /// [bytes] Contenu du fichier
  /// [format] Format du fichier (détermine le type MIME envoyé)
  /// [background] Traitement en tâche de fond (réponse immédiate)
  Future<void> import(
    String collection, {
    required List<int> bytes,
    DirectusExportFormat format = DirectusExportFormat.json,
    String? filename,
    bool background = false,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename:
            filename ??
            'import.${format == DirectusExportFormat.csvUtf8 ? 'csv' : format.name}',
        contentType: DioMediaType.parse(format.mimeType),
      ),
    });
    await _httpClient.post(
      '/utils/import/$collection',
      data: formData,
      queryParameters: background ? {'background': true} : null,
    );
  }

  /// Importe des items dans plusieurs collections en une requête
  /// (`POST /utils/import`).
  ///
  /// [batch] Map `collection → liste d'items`
  /// [mode] [DirectusImportMode.add] ou [DirectusImportMode.merge]
  /// [dryRun] Valide sans écrire
  /// [dangerouslyAllowDelete] Autorise la suppression des items absents (merge)
  ///
  /// Retourne le rapport d'import renvoyé par Directus.
  Future<dynamic> importBatch(
    Map<String, List<Map<String, dynamic>>> batch, {
    DirectusImportMode mode = DirectusImportMode.add,
    bool dryRun = false,
    bool dangerouslyAllowDelete = false,
  }) async {
    final response = await _httpClient.post(
      '/utils/import',
      data: [
        for (final entry in batch.entries)
          {'collection': entry.key, 'items': entry.value},
      ],
      queryParameters: {
        'mode': mode.name,
        if (dryRun) 'dryRun': true,
        if (dangerouslyAllowDelete) 'dangerouslyAllowDelete': true,
      },
    );
    return response.data?['data'];
  }

  /// Restaure l'item dans l'état d'une révision (`POST /utils/revert/{revision}`).
  Future<void> revert(Object revisionId) async {
    await _httpClient.post('/utils/revert/$revisionId');
  }

  /// Génère/complète des traductions par IA (`POST /utils/translations/generate`,
  /// admin uniquement). [payload] est transmis tel quel à Directus.
  Future<dynamic> generateTranslations(Map<String, dynamic> payload) async {
    final response = await _httpClient.post(
      '/utils/translations/generate',
      data: payload,
    );
    return response.data?['data'];
  }

  /// Valide et résout une URL de redirection post-login
  /// (`POST /utils/resolve-redirect`). Retourne l'URL acceptée par le serveur.
  Future<String> resolveRedirect(String redirect, {String? provider}) async {
    final response = await _httpClient.post(
      '/utils/resolve-redirect',
      data: {'redirect': redirect, if (provider != null) 'provider': provider},
    );
    return response.data['data'].toString();
  }

  /// Convertit [QueryParameters] en objet `query` pour un body JSON.
  static Map<String, dynamic>? _queryToBody(QueryParameters? query) {
    if (query == null) return null;
    return query.toJsonBody();
  }
}

/// Utilitaires de hash (endpoints supprimés dans Directus 12.1).
@Deprecated('Endpoints /utils/hash/* supprimés dans Directus 12.1.')
class HashUtility {
  final DirectusHttpClient _httpClient;

  HashUtility(this._httpClient);

  /// Génère un hash à partir d'une chaîne
  ///
  /// [string] Chaîne à hasher
  ///
  /// Retourne le hash généré
  Future<String> generate(String string) async {
    final response = await _httpClient.post(
      '/utils/hash/generate',
      data: {'string': string},
    );
    return response.data['data'] as String;
  }

  /// Vérifie si une chaîne correspond à un hash
  ///
  /// [string] Chaîne originale
  /// [hash] Hash à vérifier
  ///
  /// Retourne true si la chaîne correspond au hash
  Future<bool> verify(String string, String hash) async {
    final response = await _httpClient.post(
      '/utils/hash/verify',
      data: {'string': string, 'hash': hash},
    );
    return response.data['data'] as bool;
  }
}

/// Utilitaires pour la génération de valeurs aléatoires
class RandomUtility {
  final DirectusHttpClient _httpClient;

  RandomUtility(this._httpClient);

  /// Génère une chaîne aléatoire
  ///
  /// [length] Longueur de la chaîne (défaut: 32)
  ///
  /// Retourne une chaîne aléatoire
  Future<String> string({int length = 32}) async {
    final response = await _httpClient.get(
      '/utils/random/string',
      queryParameters: {'length': length},
    );
    return response.data['data'] as String;
  }
}

/// Utilitaires pour la gestion du cache
class CacheUtility {
  final DirectusHttpClient _httpClient;

  CacheUtility(this._httpClient);

  /// Vide le cache des données (`POST /utils/cache/clear`).
  ///
  /// [system] Vide aussi le cache du schéma et des permissions.
  Future<void> clear({bool system = false}) async {
    await _httpClient.post(
      '/utils/cache/clear',
      queryParameters: system ? {'system': true} : null,
    );
  }

  /// Directus ne permet pas de vider le cache d'une seule collection :
  /// cette méthode vide tout le cache des données.
  @Deprecated('Directus vide le cache globalement : utiliser clear().')
  Future<void> clearCollection(String collection) => clear();
}

/// Utilitaires pour le tri des items
class SortUtility {
  final DirectusHttpClient _httpClient;

  SortUtility(this._httpClient);

  /// Réordonne les items d'une collection ayant un champ de tri
  /// (`POST /utils/sort/{collection}`).
  ///
  /// [itemId] Clé primaire de l'item à déplacer
  /// [to] Clé primaire de l'item dont il prend la place (pas un index)
  Future<void> reorder(String collection, Object itemId, Object to) async {
    await _httpClient.post(
      '/utils/sort/$collection',
      data: {'item': itemId, 'to': to},
    );
  }
}

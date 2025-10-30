import '../core/directus_http_client.dart';
import 'items_service.dart';

/// Service pour gérer les dossiers (folders) dans Directus.
///
/// Les dossiers peuvent être utilisés pour organiser les fichiers au sein de la plateforme.
/// Les dossiers sont virtuels et ne sont pas reflétés dans l'adaptateur de stockage.
///
/// Exemple d'utilisation:
/// ```dart
/// // Créer un dossier
/// await client.folders.createFolder({
///   'name': 'Images 2024',
///   'parent': 'parent-folder-id', // optionnel
/// });
///
/// // Récupérer tous les dossiers
/// final folders = await client.folders.getFolders();
///
/// // Récupérer un dossier spécifique
/// final folder = await client.folders.getFolder('folder-id');
/// ```
class FoldersService {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  FoldersService(this._httpClient) {
    _itemsService = ItemsService(_httpClient, 'directus_folders');
  }

  /// Récupère la liste de tous les dossiers
  ///
  /// [query] Paramètres de requête optionnels (filtres, tri, pagination, etc.)
  ///
  /// Exemple:
  /// ```dart
  /// final folders = await client.folders.getFolders(
  ///   query: QueryParameters(
  ///     sort: ['name'],
  ///     limit: 50,
  ///   ),
  /// );
  /// ```
  Future<DirectusResponse<dynamic>> getFolders({QueryParameters? query}) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère un dossier par son ID
  ///
  /// [id] ID du dossier
  /// [query] Paramètres de requête optionnels
  Future<Map<String, dynamic>> getFolder(
    String id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id, query: query);
  }

  /// Crée un nouveau dossier
  ///
  /// [name] Nom du dossier
  /// [parent] ID du dossier parent (optionnel, pour dossiers imbriqués)
  ///
  /// Exemple:
  /// ```dart
  /// // Créer un dossier racine
  /// final rootFolder = await client.folders.createFolder(name: 'Documents');
  ///
  /// // Créer un sous-dossier
  /// final subFolder = await client.folders.createFolder(
  ///   name: 'Rapports 2024',
  ///   parent: rootFolder['id'],
  /// );
  /// ```
  Future<Map<String, dynamic>> createFolder({
    required String name,
    String? parent,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      if (parent != null) 'parent': parent,
    };
    return await _itemsService.createOne(data);
  }

  /// Crée un nouveau dossier avec données complètes
  ///
  /// [data] Données du dossier (name, parent, etc.)
  Future<Map<String, dynamic>> createFolderFromData(
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.createOne(data);
  }

  /// Crée plusieurs dossiers en une seule requête
  ///
  /// [folders] Liste des dossiers à créer
  Future<List<dynamic>> createFolders(
    List<Map<String, dynamic>> folders,
  ) async {
    return await _itemsService.createMany(folders);
  }

  /// Met à jour un dossier existant
  ///
  /// [id] ID du dossier à mettre à jour
  /// [data] Nouvelles données (name, parent)
  ///
  /// Exemple:
  /// ```dart
  /// await client.folders.updateFolder('folder-id', {
  ///   'name': 'Nouveau nom',
  ///   'parent': 'new-parent-id',
  /// });
  /// ```
  Future<Map<String, dynamic>> updateFolder(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Met à jour plusieurs dossiers en une seule requête
  ///
  /// [ids] Liste des IDs des dossiers à mettre à jour
  /// [data] Données à appliquer à tous les dossiers
  Future<List<dynamic>> updateFolders(
    List<String> ids,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateMany(ids, data);
  }

  /// Supprime un dossier
  ///
  /// [id] ID du dossier à supprimer
  ///
  /// ⚠️ Note: Les fichiers dans ce dossier seront déplacés vers le dossier racine.
  Future<void> deleteFolder(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Supprime plusieurs dossiers en une seule requête
  ///
  /// [ids] Liste des IDs des dossiers à supprimer
  ///
  /// ⚠️ Note: Les fichiers dans ces dossiers seront déplacés vers le dossier racine.
  Future<void> deleteFolders(List<String> ids) async {
    await _itemsService.deleteMany(ids);
  }

  /// Récupère tous les dossiers racine (sans parent)
  ///
  /// [query] Paramètres de requête optionnels
  Future<DirectusResponse<dynamic>> getRootFolders({
    QueryParameters? query,
  }) async {
    final mergedQuery = query ?? QueryParameters();
    final filter = mergedQuery.filter ?? {};
    filter['parent'] = {'_null': true};

    return await _itemsService.readMany(
      query: QueryParameters(
        filter: filter,
        fields: mergedQuery.fields,
        limit: mergedQuery.limit,
        offset: mergedQuery.offset,
        sort: mergedQuery.sort,
        search: mergedQuery.search,
        deep: mergedQuery.deep,
      ),
    );
  }

  /// Récupère les sous-dossiers d'un dossier parent
  ///
  /// [parentId] ID du dossier parent
  /// [query] Paramètres de requête optionnels
  ///
  /// Exemple:
  /// ```dart
  /// final subFolders = await client.folders.getSubFolders('parent-id');
  /// for (var folder in subFolders.data) {
  ///   print('Sous-dossier: ${folder['name']}');
  /// }
  /// ```
  Future<DirectusResponse<dynamic>> getSubFolders(
    String parentId, {
    QueryParameters? query,
  }) async {
    final mergedQuery = query ?? QueryParameters();
    final filter = mergedQuery.filter ?? {};
    filter['parent'] = {'_eq': parentId};

    return await _itemsService.readMany(
      query: QueryParameters(
        filter: filter,
        fields: mergedQuery.fields,
        limit: mergedQuery.limit,
        offset: mergedQuery.offset,
        sort: mergedQuery.sort,
        search: mergedQuery.search,
        deep: mergedQuery.deep,
      ),
    );
  }

  /// Déplace un dossier vers un nouveau parent
  ///
  /// [id] ID du dossier à déplacer
  /// [newParentId] ID du nouveau dossier parent (null pour dossier racine)
  Future<Map<String, dynamic>> moveFolder(
    String id,
    String? newParentId,
  ) async {
    return await updateFolder(id, {'parent': newParentId});
  }

  /// Renomme un dossier
  ///
  /// [id] ID du dossier
  /// [newName] Nouveau nom du dossier
  Future<Map<String, dynamic>> renameFolder(String id, String newName) async {
    return await updateFolder(id, {'name': newName});
  }
}

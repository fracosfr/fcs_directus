import 'package:dio/dio.dart';
import '../core/directus_http_client.dart';
import '../models/directus_file.dart';
import 'items_service.dart';
import 'system_items_service.dart';

/// Service pour gérer les fichiers dans Directus.
///
/// Permet d'uploader, télécharger et gérer des fichiers.
class FilesService extends DirectusSystemService<DirectusFile> {
  final DirectusHttpClient _httpClient;
  late final ItemsService<Map<String, dynamic>> _itemsService;

  FilesService(this._httpClient)
    : super(_httpClient, 'directus_files', DirectusFile.factory) {
    _itemsService = ItemsService(_httpClient, 'directus_files');
  }

  /// Récupère la liste des fichiers
  Future<DirectusResponse<dynamic>> getFiles({QueryParameters? query}) async {
    return await _itemsService.readMany(query: query);
  }

  /// Récupère un fichier par son ID
  Future<Map<String, dynamic>> getFile(
    String id, {
    QueryParameters? query,
  }) async {
    return await _itemsService.readOne(id, query: query);
  }

  /// Upload un fichier depuis un chemin local
  ///
  /// [filePath] Chemin du fichier à uploader
  /// [title] Titre du fichier (optionnel)
  /// [folder] ID du dossier de destination (optionnel)
  /// [metadata] Métadonnées additionnelles (optionnel)
  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    String? title,
    String? folder,
    Map<String, dynamic>? metadata,
  }) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;

    // Directus ignore les champs envoyés après le fichier : métadonnées d'abord.
    final formData = FormData.fromMap({
      if (title != null) 'title': title,
      if (folder != null) 'folder': folder,
      if (metadata != null) ...metadata,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _httpClient.post('/files', data: formData);

    return response.data['data'] as Map<String, dynamic>;
  }

  /// Upload un fichier depuis des bytes
  ///
  /// [bytes] Données du fichier
  /// [filename] Nom du fichier
  /// [title] Titre du fichier (optionnel)
  /// [folder] ID du dossier de destination (optionnel)
  /// [metadata] Métadonnées additionnelles (optionnel)
  Future<Map<String, dynamic>> uploadFileFromBytes({
    required List<int> bytes,
    required String filename,
    String? title,
    String? folder,
    Map<String, dynamic>? metadata,
  }) async {
    // Directus ignore les champs envoyés après le fichier : métadonnées d'abord.
    final formData = FormData.fromMap({
      if (title != null) 'title': title,
      if (folder != null) 'folder': folder,
      if (metadata != null) ...metadata,
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });

    final response = await _httpClient.post('/files', data: formData);

    return response.data['data'] as Map<String, dynamic>;
  }

  /// Importe un fichier depuis une URL
  ///
  /// [url] URL du fichier à importer
  /// [title] Titre du fichier (optionnel)
  /// [folder] ID du dossier de destination (optionnel)
  Future<Map<String, dynamic>> importFile({
    required String url,
    String? title,
    String? folder,
  }) async {
    final response = await _httpClient.post(
      '/files/import',
      data: {
        'url': url,
        if (title != null || folder != null)
          'data': {
            if (title != null) 'title': title,
            if (folder != null) 'folder': folder,
          },
      },
    );

    return response.data['data'] as Map<String, dynamic>;
  }

  /// Envoie un fichier et retourne le [DirectusFile] créé (`POST /files`).
  ///
  /// [file] Métadonnées optionnelles (titre, dossier, description...).
  ///
  /// ```dart
  /// final file = await client.files.upload(
  ///   bytes: imageBytes,
  ///   filename: 'photo.jpg',
  ///   file: DirectusFile.empty()..title.set('Photo')..folder.set(folderId),
  /// );
  /// print(file.id);
  /// ```
  Future<DirectusFile> upload({
    required List<int> bytes,
    required String filename,
    DirectusFile? file,
  }) async {
    final data = await uploadFileFromBytes(
      bytes: bytes,
      filename: filename,
      metadata: file?.toJson(),
    );
    return DirectusFile(data);
  }

  /// Remplace le contenu binaire d'un fichier existant
  /// (`PATCH /files/{id}` en multipart), en conservant son identifiant.
  Future<DirectusFile> replace(
    String id, {
    required List<int> bytes,
    required String filename,
    DirectusFile? file,
  }) async {
    final formData = FormData.fromMap({
      if (file != null) ...file.toJsonDirty(),
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _httpClient.patch('/files/$id', data: formData);
    return DirectusFile(response.data['data'] as Map<String, dynamic>);
  }

  /// Importe un fichier depuis une URL et retourne le [DirectusFile] créé
  /// (`POST /files/import`).
  Future<DirectusFile> importFromUrl(String url, {DirectusFile? file}) async {
    final response = await _httpClient.post(
      '/files/import',
      data: {'url': url, if (file != null) 'data': file.toJson()},
    );
    return DirectusFile(response.data['data'] as Map<String, dynamic>);
  }

  /// Met à jour les métadonnées d'un fichier
  ///
  /// [id] ID du fichier
  /// [data] Nouvelles métadonnées
  Future<Map<String, dynamic>> updateFile(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _itemsService.updateOne(id, data);
  }

  /// Supprime un fichier
  ///
  /// [id] ID du fichier à supprimer
  Future<void> deleteFile(String id) async {
    await _itemsService.deleteOne(id);
  }

  /// Génère l'URL pour accéder à un fichier
  ///
  /// [fileId] ID du fichier
  /// [key] Clé de transformation (optionnel, pour les assets transformés)
  String getFileUrl(String fileId, {String? key}) {
    final baseUrl = _httpClient.config.baseUrl;
    if (key != null) {
      return '$baseUrl/assets/$fileId?key=$key';
    }
    return '$baseUrl/assets/$fileId';
  }

  /// Génère l'URL pour un thumbnail
  ///
  /// [fileId] ID du fichier
  /// [width] Largeur du thumbnail (optionnel)
  /// [height] Hauteur du thumbnail (optionnel)
  /// [fit] Mode de fit (cover, contain, inside, outside)
  /// [quality] Qualité (1-100)
  String getThumbnailUrl(
    String fileId, {
    int? width,
    int? height,
    String fit = 'cover',
    int quality = 80,
  }) {
    final baseUrl = _httpClient.config.baseUrl;
    final params = <String>[];

    if (width != null) params.add('width=$width');
    if (height != null) params.add('height=$height');
    params.add('fit=$fit');
    params.add('quality=$quality');

    return '$baseUrl/assets/$fileId?${params.join('&')}';
  }
}

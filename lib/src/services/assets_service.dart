import 'dart:convert';
import '../core/directus_http_client.dart';
import '../models/asset_transforms.dart';

/// Service pour gérer les assets Directus (images transformées).
///
/// Les assets sont des fichiers (généralement des images) qui peuvent être
/// dynamiquement redimensionnés et transformés pour s'adapter à vos besoins.
///
/// **Important**: Ce service génère des URLs pour accéder aux assets transformés.
/// Pour la gestion des fichiers (upload, delete, métadonnées), utilisez `FilesService`.
///
/// Exemple d'utilisation :
/// ```dart
/// final assets = client.assets;
///
/// // URL simple d'un asset
/// final url = assets.getAssetUrl('file-id');
///
/// // Avec transformation type-safe
/// final transform = AssetTransform()
///   ..width = 800
///   ..height = 600
///   ..fit = AssetFit.cover
///   ..quality = 85
///   ..format = AssetFormat.webp;
///
/// final transformedUrl = assets.getAssetUrl('file-id', transforms: [transform]);
///
/// // Avec un preset prédéfini
/// final avatarUrl = assets.getAssetUrl(
///   'file-id',
///   transforms: [AssetPresets.avatar(size: 200)],
/// );
///
/// // Avec une clé de preset configurée dans Directus
/// final keyUrl = assets.getAssetUrl('file-id', key: 'thumbnail');
///
/// // Mode téléchargement
/// final downloadUrl = assets.getAssetUrl('file-id', download: true);
/// ```
class AssetsService {
  final DirectusHttpClient _httpClient;

  AssetsService(this._httpClient);

  /// Génère l'URL pour accéder à un asset
  ///
  /// [fileId] ID du fichier
  /// [key] Clé de transformation prédéfinie dans les paramètres Directus (optionnel)
  /// [transforms] Liste de transformations à appliquer (optionnel)
  /// [download] Force le téléchargement au lieu de l'affichage (optionnel)
  ///
  /// **Note**: Si vous utilisez `key`, les `transforms` sont ignorées.
  ///
  /// Exemple simple:
  /// ```dart
  /// final url = assets.getAssetUrl('abc-123');
  /// // https://directus.example.com/assets/abc-123
  /// ```
  ///
  /// Avec transformations:
  /// ```dart
  /// final url = assets.getAssetUrl(
  ///   'abc-123',
  ///   transforms: [
  ///     AssetTransform()
  ///       ..width = 800
  ///       ..height = 600
  ///       ..fit = AssetFit.cover
  ///       ..quality = 85,
  ///   ],
  /// );
  /// // https://directus.example.com/assets/abc-123?transforms=[...]
  /// ```
  ///
  /// Avec clé prédéfinie:
  /// ```dart
  /// final url = assets.getAssetUrl('abc-123', key: 'thumbnail');
  /// // https://directus.example.com/assets/abc-123?key=thumbnail
  /// ```
  String getAssetUrl(
    String fileId, {
    String? key,
    List<AssetTransform>? transforms,
    bool download = false,
  }) {
    final baseUrl = _httpClient.config.baseUrl;
    final params = <String>[];

    // Si une clé est fournie, elle prend la priorité
    if (key != null) {
      params.add('key=$key');
    } else if (transforms != null && transforms.isNotEmpty) {
      // Convertir les transformations en JSON pour l'API
      final transformsJson = transforms.map((t) => t.toJson()).toList();
      final encoded = Uri.encodeComponent(jsonEncode(transformsJson));
      params.add('transforms=$encoded');
    }

    if (download) {
      params.add('download=true');
    }

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return '$baseUrl/assets/$fileId$query';
  }

  /// Génère une URL pour un thumbnail
  ///
  /// Méthode de commodité pour créer des thumbnails rapidement.
  ///
  /// Exemple:
  /// ```dart
  /// final url = assets.getThumbnailUrl(
  ///   'file-id',
  ///   width: 200,
  ///   height: 200,
  ///   fit: AssetFit.cover,
  ///   quality: 80,
  /// );
  /// ```
  String getThumbnailUrl(
    String fileId, {
    int? width,
    int? height,
    AssetFit fit = AssetFit.cover,
    int quality = 80,
    AssetFormat? format,
  }) {
    final transform = AssetTransform(
      width: width,
      height: height,
      fit: fit,
      quality: quality,
      format: format,
    );

    return getAssetUrl(fileId, transforms: [transform]);
  }

  /// Génère une URL pour un avatar
  ///
  /// Crée automatiquement un thumbnail carré optimisé pour les avatars.
  ///
  /// Exemple:
  /// ```dart
  /// final avatarUrl = assets.getAvatarUrl('file-id', size: 200);
  /// ```
  String getAvatarUrl(String fileId, {int size = 200, int quality = 85}) {
    return getAssetUrl(
      fileId,
      transforms: [AssetPresets.avatar(size: size, quality: quality)],
    );
  }

  /// Génère une URL pour une bannière (16:9)
  ///
  /// Exemple:
  /// ```dart
  /// final bannerUrl = assets.getBannerUrl('file-id', width: 1920);
  /// ```
  String getBannerUrl(String fileId, {int width = 1920, int quality = 85}) {
    return getAssetUrl(
      fileId,
      transforms: [AssetPresets.banner(width: width, quality: quality)],
    );
  }

  /// Génère une URL pour une carte (4:3)
  ///
  /// Exemple:
  /// ```dart
  /// final cardUrl = assets.getCardUrl('file-id', width: 800);
  /// ```
  String getCardUrl(String fileId, {int width = 800, int quality = 80}) {
    return getAssetUrl(
      fileId,
      transforms: [AssetPresets.card(width: width, quality: quality)],
    );
  }

  /// Génère une URL responsive (conserve proportions, limite la largeur)
  ///
  /// Idéal pour les images responsive sur le web.
  ///
  /// Exemple:
  /// ```dart
  /// final responsiveUrl = assets.getResponsiveUrl(
  ///   'file-id',
  ///   maxWidth: 1200,
  ///   quality: 80,
  /// );
  /// ```
  String getResponsiveUrl(
    String fileId, {
    int maxWidth = 1200,
    int quality = 80,
    AssetFormat format = AssetFormat.webp,
  }) {
    return getAssetUrl(
      fileId,
      transforms: [
        AssetPresets.responsive(
          maxWidth: maxWidth,
          quality: quality,
          format: format,
        ),
      ],
    );
  }

  /// Génère une URL optimisée pour mobile
  ///
  /// Exemple:
  /// ```dart
  /// final mobileUrl = assets.getMobileUrl('file-id', maxWidth: 800);
  /// ```
  String getMobileUrl(String fileId, {int maxWidth = 800, int quality = 75}) {
    return getAssetUrl(
      fileId,
      transforms: [AssetPresets.mobile(maxWidth: maxWidth, quality: quality)],
    );
  }

  /// Génère plusieurs URLs pour différentes tailles (srcset)
  ///
  /// Utile pour créer des images responsive avec l'attribut `srcset`.
  ///
  /// Exemple:
  /// ```dart
  /// final urls = assets.getSrcSet(
  ///   'file-id',
  ///   widths: [320, 640, 1024, 1920],
  ///   quality: 80,
  /// );
  /// // {320: 'url1', 640: 'url2', ...}
  ///
  /// // Utilisation dans HTML/Flutter:
  /// // <img srcset="url1 320w, url2 640w, url3 1024w, url4 1920w">
  /// ```
  Map<int, String> getSrcSet(
    String fileId, {
    List<int> widths = const [320, 640, 1024, 1920],
    int quality = 80,
    AssetFormat format = AssetFormat.webp,
    AssetFit fit = AssetFit.inside,
  }) {
    final srcSet = <int, String>{};

    for (final width in widths) {
      final transform = AssetTransform(
        width: width,
        fit: fit,
        quality: quality,
        format: format,
        withoutEnlargement: true,
      );

      srcSet[width] = getAssetUrl(fileId, transforms: [transform]);
    }

    return srcSet;
  }

  /// Génère une URL de téléchargement pour un asset
  ///
  /// Force le navigateur à télécharger le fichier au lieu de l'afficher.
  ///
  /// Exemple:
  /// ```dart
  /// final downloadUrl = assets.getDownloadUrl('file-id');
  /// ```
  String getDownloadUrl(String fileId) {
    return getAssetUrl(fileId, download: true);
  }

  /// Génère une URL avec un focal point personnalisé
  ///
  /// Permet de définir le point focal lors du recadrage.
  ///
  /// Exemple:
  /// ```dart
  /// final url = assets.getAssetWithFocalPoint(
  ///   'file-id',
  ///   width: 800,
  ///   height: 600,
  ///   focalPoint: FocalPoint(0.3, 0.7), // 30% de gauche, 70% de haut
  /// );
  ///
  /// // Ou utiliser un preset
  /// final url = assets.getAssetWithFocalPoint(
  ///   'file-id',
  ///   width: 800,
  ///   height: 600,
  ///   focalPoint: FocalPoint.topLeft,
  /// );
  /// ```
  String getAssetWithFocalPoint(
    String fileId, {
    required int width,
    required int height,
    required FocalPoint focalPoint,
    AssetFit fit = AssetFit.cover,
    int quality = 85,
    AssetFormat? format,
  }) {
    final transform = AssetTransform(
      width: width,
      height: height,
      fit: fit,
      quality: quality,
      format: format,
      focalPoint: focalPoint,
    );

    return getAssetUrl(fileId, transforms: [transform]);
  }

  /// Applique plusieurs transformations en séquence
  ///
  /// Utile pour des manipulations complexes.
  ///
  /// Exemple:
  /// ```dart
  /// final url = assets.getAssetUrl(
  ///   'file-id',
  ///   transforms: [
  ///     AssetTransform()..width = 1000,
  ///     AssetTransform()..quality = 90..format = AssetFormat.webp,
  ///   ],
  /// );
  /// ```
  String getAssetWithMultipleTransforms(
    String fileId,
    List<AssetTransform> transforms,
  ) {
    return getAssetUrl(fileId, transforms: transforms);
  }

  /// Génère une URL pour un placeholder/preview basse qualité
  ///
  /// Idéal pour le lazy loading avec LQIP (Low Quality Image Placeholder).
  ///
  /// Exemple:
  /// ```dart
  /// final placeholderUrl = assets.getPlaceholderUrl('file-id', width: 50);
  /// ```
  String getPlaceholderUrl(String fileId, {int width = 50, int quality = 30}) {
    final transform = AssetTransform(
      width: width,
      fit: AssetFit.inside,
      quality: quality,
      format: AssetFormat.webp,
    );

    return getAssetUrl(fileId, transforms: [transform]);
  }
}

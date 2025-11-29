/// Configuration type-safe pour les transformations d'assets Directus.
///
/// Permet de construire des transformations d'images sans utiliser de JSON brut.
///
/// Exemple d'utilisation :
/// ```dart
/// // Créer une transformation
/// final transform = AssetTransform()
///   ..width = 800
///   ..height = 600
///   ..fit = AssetFit.cover
///   ..quality = 85
///   ..format = AssetFormat.webp;
///
/// // Obtenir l'URL de l'asset transformé
/// final url = client.assets.getAssetUrl('file-id', transforms: [transform]);
/// ```
library;

/// Mode de fit pour le redimensionnement d'images
enum AssetFit {
  /// Redimensionne l'image pour couvrir entièrement les dimensions spécifiées (peut rogner)
  cover('cover'),

  /// Redimensionne l'image pour qu'elle tienne dans les dimensions (conserve tout)
  contain('contain'),

  /// Similaire à contain, mais ne fait qu'agrandir si l'image est plus petite
  inside('inside'),

  /// Similaire à cover, mais ne fait qu'agrandir si l'image est plus petite
  outside('outside');

  final String value;
  const AssetFit(this.value);
}

/// Format de sortie de l'image
enum AssetFormat {
  /// Format JPEG
  jpg('jpg'),

  /// Format PNG
  png('png'),

  /// Format WebP (recommandé pour le web)
  webp('webp'),

  /// Format TIFF
  tiff('tiff'),

  /// Format AVIF (nouvelle génération, très compressé)
  avif('avif');

  final String value;
  const AssetFormat(this.value);
}

/// Position pour le recadrage focal
class FocalPoint {
  /// Position X (0.0 à 1.0, où 0 = gauche, 1 = droite)
  final double x;

  /// Position Y (0.0 à 1.0, où 0 = haut, 1 = bas)
  final double y;

  const FocalPoint(this.x, this.y)
    : assert(x >= 0 && x <= 1, 'x must be between 0 and 1'),
      assert(y >= 0 && y <= 1, 'y must be between 0 and 1');

  /// Centre de l'image
  static const center = FocalPoint(0.5, 0.5);

  /// Coin supérieur gauche
  static const topLeft = FocalPoint(0, 0);

  /// Coin supérieur droit
  static const topRight = FocalPoint(1, 0);

  /// Coin inférieur gauche
  static const bottomLeft = FocalPoint(0, 1);

  /// Coin inférieur droit
  static const bottomRight = FocalPoint(1, 1);

  /// Bord supérieur (centré horizontalement)
  static const top = FocalPoint(0.5, 0);

  /// Bord inférieur (centré horizontalement)
  static const bottom = FocalPoint(0.5, 1);

  /// Bord gauche (centré verticalement)
  static const left = FocalPoint(0, 0.5);

  /// Bord droit (centré verticalement)
  static const right = FocalPoint(1, 0.5);
}

/// Transformation d'asset Directus
///
/// Permet de définir des transformations d'images de manière type-safe.
class AssetTransform {
  /// Largeur cible en pixels
  int? width;

  /// Hauteur cible en pixels
  int? height;

  /// Mode de fit (comment ajuster l'image aux dimensions)
  AssetFit? fit;

  /// Qualité de l'image (1-100)
  int? quality;

  /// Format de sortie
  AssetFormat? format;

  /// Point focal pour le recadrage (0.0-1.0 pour x et y)
  FocalPoint? focalPoint;

  /// Activer le mode sans agrandissement (ne fait que réduire)
  bool? withoutEnlargement;

  AssetTransform({
    this.width,
    this.height,
    this.fit,
    this.quality,
    this.format,
    this.focalPoint,
    this.withoutEnlargement,
  });

  /// Convertit la transformation en Map pour l'API Directus
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (width != null) json['width'] = width;
    if (height != null) json['height'] = height;
    if (fit != null) json['fit'] = fit!.value;
    if (quality != null) json['quality'] = quality;
    if (format != null) json['format'] = format!.value;
    if (withoutEnlargement != null) {
      json['withoutEnlargement'] = withoutEnlargement;
    }
    if (focalPoint != null) {
      json['focal_point_x'] = focalPoint!.x;
      json['focal_point_y'] = focalPoint!.y;
    }

    return json;
  }

  /// Crée une copie de cette transformation avec des modifications
  AssetTransform copyWith({
    int? width,
    int? height,
    AssetFit? fit,
    int? quality,
    AssetFormat? format,
    FocalPoint? focalPoint,
    bool? withoutEnlargement,
  }) {
    return AssetTransform(
      width: width ?? this.width,
      height: height ?? this.height,
      fit: fit ?? this.fit,
      quality: quality ?? this.quality,
      format: format ?? this.format,
      focalPoint: focalPoint ?? this.focalPoint,
      withoutEnlargement: withoutEnlargement ?? this.withoutEnlargement,
    );
  }

  @override
  String toString() {
    return 'AssetTransform(width: $width, height: $height, fit: $fit, '
        'quality: $quality, format: $format, focalPoint: $focalPoint, '
        'withoutEnlargement: $withoutEnlargement)';
  }
}

/// Presets de transformations communes
class AssetPresets {
  AssetPresets._();

  /// Thumbnail carré 150x150
  static AssetTransform thumbnail({int size = 150, int quality = 80}) {
    return AssetTransform(
      width: size,
      height: size,
      fit: AssetFit.cover,
      quality: quality,
      format: AssetFormat.webp,
    );
  }

  /// Image pour avatar circulaire
  static AssetTransform avatar({int size = 200, int quality = 85}) {
    return AssetTransform(
      width: size,
      height: size,
      fit: AssetFit.cover,
      quality: quality,
      format: AssetFormat.webp,
    );
  }

  /// Image pour bannière/header (16:9)
  static AssetTransform banner({int width = 1920, int quality = 85}) {
    return AssetTransform(
      width: width,
      height: (width * 9 / 16).round(),
      fit: AssetFit.cover,
      quality: quality,
      format: AssetFormat.webp,
    );
  }

  /// Image pour carte (4:3)
  static AssetTransform card({int width = 800, int quality = 80}) {
    return AssetTransform(
      width: width,
      height: (width * 3 / 4).round(),
      fit: AssetFit.cover,
      quality: quality,
      format: AssetFormat.webp,
    );
  }

  /// Image responsive pour le web (max width, conserve ratio)
  static AssetTransform responsive({
    int maxWidth = 1200,
    int quality = 80,
    AssetFormat format = AssetFormat.webp,
  }) {
    return AssetTransform(
      width: maxWidth,
      fit: AssetFit.inside,
      quality: quality,
      format: format,
      withoutEnlargement: true,
    );
  }

  /// Image optimisée pour mobile
  static AssetTransform mobile({int maxWidth = 800, int quality = 75}) {
    return AssetTransform(
      width: maxWidth,
      fit: AssetFit.inside,
      quality: quality,
      format: AssetFormat.webp,
      withoutEnlargement: true,
    );
  }

  /// Image pour galerie (conserve proportions)
  static AssetTransform gallery({int maxWidth = 1600, int quality = 90}) {
    return AssetTransform(
      width: maxWidth,
      fit: AssetFit.inside,
      quality: quality,
      format: AssetFormat.webp,
      withoutEnlargement: true,
    );
  }

  /// Image haute qualité
  static AssetTransform highQuality({int? width, int? height}) {
    return AssetTransform(
      width: width,
      height: height,
      fit: AssetFit.inside,
      quality: 95,
      format: AssetFormat.webp,
    );
  }

  /// Image basse qualité (pour placeholder/preview)
  static AssetTransform lowQuality({int width = 100}) {
    return AssetTransform(
      width: width,
      fit: AssetFit.inside,
      quality: 50,
      format: AssetFormat.webp,
    );
  }
}

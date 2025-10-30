import 'package:fcs_directus/fcs_directus.dart';

/// Exemples d'utilisation du service Assets
///
/// Ce fichier démontre comment utiliser le service Assets de Directus
/// pour générer des URLs d'assets transformés de manière type-safe.
///
/// **Important**: Le service Assets génère uniquement des URLs.
/// Pour gérer les fichiers (upload, delete, métadonnées), utilisez FilesService.

void main() async {
  // Configuration du client
  final client = DirectusClient(
    DirectusConfig(baseUrl: 'https://directus.example.com'),
  );

  try {
    // Authentification
    await client.auth.login(email: 'user@example.com', password: 'password');

    // ID d'un fichier exemple
    const fileId = 'abc-123-def-456';

    print('=== EXEMPLES ASSETS SERVICE ===\n');

    // ====================
    // 1. URL Simple
    // ====================
    print('1. URL simple d\'un asset:');
    final simpleUrl = client.assets.getAssetUrl(fileId);
    print('   URL: $simpleUrl');
    print('   -> Retourne le fichier original sans transformation\n');

    // ====================
    // 2. Transformations Type-Safe
    // ====================
    print('2. Transformation type-safe:');
    final transform = AssetTransform(
      width: 800,
      height: 600,
      fit: AssetFit.cover,
      quality: 85,
      format: AssetFormat.webp,
    );
    final transformedUrl = client.assets.getAssetUrl(
      fileId,
      transforms: [transform],
    );
    print('   Paramètres: 800x600, cover, quality 85, webp');
    print('   URL: $transformedUrl\n');

    // ====================
    // 3. Thumbnail
    // ====================
    print('3. Thumbnail avec méthode de commodité:');
    final thumbnailUrl = client.assets.getThumbnailUrl(
      fileId,
      width: 200,
      height: 200,
      fit: AssetFit.cover,
      quality: 80,
    );
    print('   URL: $thumbnailUrl\n');

    // ====================
    // 4. Avatar
    // ====================
    print('4. Avatar (carré, optimisé):');
    final avatarUrl = client.assets.getAvatarUrl(fileId, size: 200);
    print('   URL: $avatarUrl');
    print('   -> Thumbnail carré 200x200, quality 85\n');

    // ====================
    // 5. Bannière
    // ====================
    print('5. Bannière (16:9):');
    final bannerUrl = client.assets.getBannerUrl(fileId, width: 1920);
    print('   URL: $bannerUrl');
    print('   -> 1920x1080 (16:9), quality 85\n');

    // ====================
    // 6. Carte
    // ====================
    print('6. Carte (4:3):');
    final cardUrl = client.assets.getCardUrl(fileId, width: 800);
    print('   URL: $cardUrl');
    print('   -> 800x600 (4:3), quality 80\n');

    // ====================
    // 7. Responsive
    // ====================
    print('7. Image responsive (conserve proportions):');
    final responsiveUrl = client.assets.getResponsiveUrl(
      fileId,
      maxWidth: 1200,
      quality: 80,
      format: AssetFormat.webp,
    );
    print('   URL: $responsiveUrl');
    print('   -> Largeur max 1200px, proportions conservées, webp\n');

    // ====================
    // 8. Mobile
    // ====================
    print('8. Optimisé pour mobile:');
    final mobileUrl = client.assets.getMobileUrl(fileId, maxWidth: 800);
    print('   URL: $mobileUrl');
    print('   -> Max 800px, quality 75, webp\n');

    // ====================
    // 9. SrcSet (images responsive)
    // ====================
    print('9. SrcSet pour images responsive:');
    final srcSet = client.assets.getSrcSet(
      fileId,
      widths: [320, 640, 1024, 1920],
      quality: 80,
      format: AssetFormat.webp,
    );
    print('   SrcSet généré:');
    srcSet.forEach((width, url) {
      print('   - ${width}w: $url');
    });
    print('   -> Utilisable avec <img srcset="...">\n');

    // ====================
    // 10. Preset Prédéfini (configuré dans Directus)
    // ====================
    print('10. Utiliser un preset configuré dans Directus:');
    final presetUrl = client.assets.getAssetUrl(fileId, key: 'thumbnail');
    print('   URL: $presetUrl');
    print(
      '   -> Utilise les paramètres du preset "thumbnail" défini dans Directus\n',
    );

    // ====================
    // 11. Focal Point
    // ====================
    print('11. Recadrage avec focal point:');
    final focalPointUrl = client.assets.getAssetWithFocalPoint(
      fileId,
      width: 800,
      height: 600,
      focalPoint: FocalPoint.topLeft,
      fit: AssetFit.cover,
    );
    print('   URL: $focalPointUrl');
    print('   -> Recadre en gardant le focus en haut à gauche\n');

    print('12. Focal point personnalisé:');
    final customFocalUrl = client.assets.getAssetWithFocalPoint(
      fileId,
      width: 800,
      height: 600,
      focalPoint: const FocalPoint(0.3, 0.7), // 30% gauche, 70% haut
    );
    print('   URL: $customFocalUrl');
    print('   -> Focus à 30% de la gauche, 70% du haut\n');

    // ====================
    // 13. Transformations Multiples
    // ====================
    print('13. Transformations multiples en séquence:');
    final multiTransformUrl = client.assets
        .getAssetWithMultipleTransforms(fileId, [
          AssetTransform(width: 1000),
          AssetTransform(quality: 90, format: AssetFormat.webp),
        ]);
    print('   URL: $multiTransformUrl');
    print('   -> Applique plusieurs transformations successivement\n');

    // ====================
    // 14. Placeholder (LQIP)
    // ====================
    print('14. Placeholder basse qualité (LQIP):');
    final placeholderUrl = client.assets.getPlaceholderUrl(
      fileId,
      width: 50,
      quality: 30,
    );
    print('   URL: $placeholderUrl');
    print('   -> Petite image pour le lazy loading\n');

    // ====================
    // 15. Téléchargement
    // ====================
    print('15. URL de téléchargement:');
    final downloadUrl = client.assets.getDownloadUrl(fileId);
    print('   URL: $downloadUrl');
    print('   -> Force le téléchargement du fichier\n');

    // ====================
    // 16. Presets de AssetPresets
    // ====================
    print('16. Utilisation des presets AssetPresets:');

    print('   a) Thumbnail preset:');
    final presetThumbnail = AssetPresets.thumbnail(size: 200, quality: 80);
    final presetThumbUrl = client.assets.getAssetUrl(
      fileId,
      transforms: [presetThumbnail],
    );
    print('      URL: $presetThumbUrl\n');

    print('   b) Gallery preset:');
    final presetGallery = AssetPresets.gallery(maxWidth: 1200, quality: 85);
    final presetGalleryUrl = client.assets.getAssetUrl(
      fileId,
      transforms: [presetGallery],
    );
    print('      URL: $presetGalleryUrl\n');

    print('   c) High Quality preset:');
    final presetHQ = AssetPresets.highQuality(width: 2000);
    final presetHQUrl = client.assets.getAssetUrl(
      fileId,
      transforms: [presetHQ],
    );
    print('      URL: $presetHQUrl\n');

    print('   d) Low Quality preset:');
    final presetLQ = AssetPresets.lowQuality(width: 800);
    final presetLQUrl = client.assets.getAssetUrl(
      fileId,
      transforms: [presetLQ],
    );
    print('      URL: $presetLQUrl\n');

    // ====================
    // 17. Builder Pattern Complexe
    // ====================
    print('17. Builder pattern pour configuration complexe:');
    final complexTransform = AssetTransform(
      width: 1200,
      height: 800,
      fit: AssetFit.cover,
      quality: 90,
      format: AssetFormat.avif,
      focalPoint: FocalPoint.center,
      withoutEnlargement: true,
    );
    final complexUrl = client.assets.getAssetUrl(
      fileId,
      transforms: [complexTransform],
    );
    print('   Paramètres:');
    print('   - Taille: 1200x800');
    print('   - Fit: cover');
    print('   - Quality: 90');
    print('   - Format: AVIF');
    print('   - Focal: center');
    print('   - Sans agrandissement');
    print('   URL: $complexUrl\n');

    // ====================
    // 18. CopyWith pour Modifications
    // ====================
    print('18. CopyWith pour modifier une transformation:');
    final baseTransform = AssetPresets.card();
    final modifiedTransform = baseTransform.copyWith(
      quality: 95,
      format: AssetFormat.webp,
    );
    final modifiedUrl = client.assets.getAssetUrl(
      fileId,
      transforms: [modifiedTransform],
    );
    print('   Base: Card preset (800x600, quality 80)');
    print('   Modifié: quality 95, format webp');
    print('   URL: $modifiedUrl\n');

    // ====================
    // 19. Formats d'Image
    // ====================
    print('19. Différents formats d\'image:');
    final formats = [
      AssetFormat.jpg,
      AssetFormat.png,
      AssetFormat.webp,
      AssetFormat.avif,
      AssetFormat.tiff,
    ];

    for (final format in formats) {
      final formatUrl = client.assets.getThumbnailUrl(
        fileId,
        width: 400,
        format: format,
      );
      print('   Format ${format.name}: $formatUrl');
    }
    print('');

    // ====================
    // 20. Modes de Fit
    // ====================
    print('20. Différents modes de fit:');
    final fitModes = [
      AssetFit.cover,
      AssetFit.contain,
      AssetFit.inside,
      AssetFit.outside,
    ];

    for (final fit in fitModes) {
      final fitUrl = client.assets.getThumbnailUrl(
        fileId,
        width: 400,
        height: 300,
        fit: fit,
      );
      print('   Fit ${fit.name}: $fitUrl');
    }
    print('');

    // ====================
    // EXEMPLE D'UTILISATION DANS UNE APP FLUTTER
    // ====================
    print('=== EXEMPLE D\'UTILISATION FLUTTER ===\n');

    print('''
// Dans un Widget Flutter:
class ProductImage extends StatelessWidget {
  final String fileId;

  const ProductImage({required this.fileId});

  @override
  Widget build(BuildContext context) {
    final client = DirectusClient.instance; // Singleton
    
    // Image responsive avec placeholder
    return Image.network(
      client.assets.getResponsiveUrl(fileId),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        // Afficher le placeholder pendant le chargement
        return Image.network(
          client.assets.getPlaceholderUrl(fileId),
          fit: BoxFit.cover,
        );
      },
    );
  }
}

// Pour un avatar utilisateur:
CircleAvatar(
  backgroundImage: NetworkImage(
    client.assets.getAvatarUrl(user.avatar, size: 200),
  ),
)

// Pour une galerie avec srcset:
final srcSet = client.assets.getSrcSet(
  fileId,
  widths: [320, 640, 1024, 1920],
);
// Sélectionner l'URL appropriée selon la taille d'écran
''');
  } catch (e) {
    print('Erreur: $e');
  } finally {
    client.dispose();
  }
}

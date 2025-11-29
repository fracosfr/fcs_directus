# Gestion des fichiers et assets

Ce guide explique comment gérer les fichiers et transformer les images avec Directus.

## Fichiers (Files)

### Lister les fichiers

```dart
final files = await client.files.getFiles();

for (final file in files) {
  print('${file['filename_download']} (${file['type']})');
}
```

### Avec filtres et pagination

```dart
final images = await client.files.getFiles(
  query: QueryParameters(
    filter: Filter.field('type').contains('image'),
    sort: ['-uploaded_on'],
    limit: 20,
  ),
);
```

### Obtenir un fichier

```dart
final file = await client.files.getFile('file-uuid');

print('Nom: ${file['filename_download']}');
print('Type: ${file['type']}');
print('Taille: ${file['filesize']} bytes');
print('Dimensions: ${file['width']}x${file['height']}');
```

### Upload depuis un chemin

```dart
final file = await client.files.uploadFile(
  filePath: '/path/to/image.jpg',
  title: 'Mon image',
  description: 'Description optionnelle',
  folder: 'folder-uuid',  // Optionnel
  tags: ['photo', 'nature'],
);

print('Fichier uploadé: ${file['id']}');
```

### Upload depuis des bytes

```dart
import 'dart:io';

final bytes = await File('/path/to/file.pdf').readAsBytes();

final file = await client.files.uploadFileFromBytes(
  bytes: bytes,
  filename: 'document.pdf',
  title: 'Mon document',
  contentType: 'application/pdf',
);
```

### Import depuis une URL

```dart
final file = await client.files.importFile(
  url: 'https://example.com/image.jpg',
  title: 'Image importée',
  folder: 'folder-uuid',
);
```

### Mettre à jour les métadonnées

```dart
await client.files.updateFile('file-uuid', {
  'title': 'Nouveau titre',
  'description': 'Nouvelle description',
  'tags': ['updated', 'photo'],
});
```

### Supprimer un fichier

```dart
await client.files.deleteFile('file-uuid');
```

### Supprimer plusieurs fichiers

```dart
await client.files.deleteFiles(['uuid-1', 'uuid-2', 'uuid-3']);
```

## Dossiers (Folders)

### Lister les dossiers

```dart
final folders = await client.folders.getFolders();

for (final folder in folders) {
  print('${folder['name']} (${folder['id']})');
}
```

### Créer un dossier

```dart
final folder = await client.folders.createFolder({
  'name': 'Photos 2024',
  'parent': 'parent-folder-uuid',  // Optionnel
});
```

### Mettre à jour un dossier

```dart
await client.folders.updateFolder('folder-uuid', {
  'name': 'Nouveau nom',
});
```

### Supprimer un dossier

```dart
await client.folders.deleteFolder('folder-uuid');
```

## Assets (Transformation d'images)

Le service `assets` permet de générer des URLs avec transformations d'images.

### URL basique

```dart
final url = client.assets.getAssetUrl('file-uuid');
// https://your-directus.com/assets/file-uuid
```

### Avec transformations

```dart
final url = client.assets.getAssetUrl(
  'file-uuid',
  transforms: [
    AssetTransform(
      width: 800,
      height: 600,
      fit: AssetFit.cover,
      quality: 80,
      format: AssetFormat.webp,
    ),
  ],
);
```

### Types de fit

| Fit | Description |
|-----|-------------|
| `AssetFit.cover` | Remplit la zone, peut rogner |
| `AssetFit.contain` | Contenu entier visible, peut avoir des marges |
| `AssetFit.inside` | Redimensionne à l'intérieur des dimensions |
| `AssetFit.outside` | Redimensionne à l'extérieur des dimensions |

### Formats disponibles

| Format | Extension |
|--------|-----------|
| `AssetFormat.jpg` | .jpg |
| `AssetFormat.png` | .png |
| `AssetFormat.webp` | .webp |
| `AssetFormat.tiff` | .tiff |
| `AssetFormat.avif` | .avif |

### Helpers prédéfinis

```dart
// Avatar carré
final avatarUrl = client.assets.getAvatarUrl('file-id', size: 200);
// 200x200, cover, webp

// Bannière large
final bannerUrl = client.assets.getBannerUrl('file-id', width: 1920);
// Largeur 1920, hauteur auto

// Card / vignette
final cardUrl = client.assets.getCardUrl('file-id', width: 400);
// 400x300, cover

// Image mobile
final mobileUrl = client.assets.getMobileUrl('file-id', maxWidth: 800);
// Max 800px de large

// Placeholder LQIP (Low Quality Image Placeholder)
final placeholderUrl = client.assets.getPlaceholderUrl('file-id');
// Très petite image pour effet blur-up
```

### Focal Point

Définissez un point focal pour le recadrage :

```dart
final url = client.assets.getAssetWithFocalPoint(
  'file-id',
  width: 800,
  height: 600,
  focalPoint: FocalPoint(0.3, 0.7),  // 30% depuis la gauche, 70% depuis le haut
);
```

### Srcset pour images responsive

Générez un srcset pour les images responsive :

```dart
final srcSet = client.assets.getSrcSet(
  'file-id',
  widths: [320, 640, 1024, 1440, 1920],
  quality: 80,
  format: AssetFormat.webp,
);

// Retourne: Map<int, String>
// {
//   320: 'https://.../assets/file-id?width=320&quality=80&format=webp',
//   640: 'https://.../assets/file-id?width=640&quality=80&format=webp',
//   ...
// }

// Utilisation en HTML
final srcSetString = srcSet.entries
  .map((e) => '${e.value} ${e.key}w')
  .join(', ');
```

### Utilisation avec Flutter

```dart
// Widget Image avec transformation
Image.network(
  client.assets.getAssetUrl(
    'file-id',
    transforms: [
      AssetTransform(
        width: 400,
        height: 300,
        fit: AssetFit.cover,
        quality: 85,
        format: AssetFormat.webp,
      ),
    ],
  ),
  fit: BoxFit.cover,
)

// Avec CachedNetworkImage
CachedNetworkImage(
  imageUrl: client.assets.getAvatarUrl(user.avatarId, size: 100),
  placeholder: (_, __) => CircularProgressIndicator(),
  errorWidget: (_, __, ___) => Icon(Icons.person),
)
```

### Presets Directus

Si vous avez configuré des presets dans Directus :

```dart
final url = client.assets.getAssetUrl(
  'file-id',
  key: 'thumbnail',  // Nom du preset
);
```

### URL de téléchargement

Pour forcer le téléchargement :

```dart
final downloadUrl = client.assets.getDownloadUrl('file-id');
// Ajoute ?download=true
```

## Workflow complet : Galerie d'images

```dart
class GalleryService {
  final DirectusClient _client;
  
  GalleryService(this._client);
  
  // Charger les images d'un dossier
  Future<List<GalleryImage>> getImagesInFolder(String folderId) async {
    final files = await _client.files.getFiles(
      query: QueryParameters(
        filter: Filter.and([
          Filter.field('folder').equals(folderId),
          Filter.field('type').contains('image'),
        ]),
        sort: ['-uploaded_on'],
      ),
    );
    
    return files.map((f) => GalleryImage(
      id: f['id'],
      title: f['title'] ?? f['filename_download'],
      thumbnail: _client.assets.getCardUrl(f['id'], width: 300),
      fullSize: _client.assets.getAssetUrl(f['id']),
    )).toList();
  }
  
  // Upload avec miniatures auto-générées
  Future<GalleryImage> uploadImage(String path, String title) async {
    final file = await _client.files.uploadFile(
      filePath: path,
      title: title,
      folder: 'gallery-folder-id',
    );
    
    return GalleryImage(
      id: file['id'],
      title: title,
      thumbnail: _client.assets.getCardUrl(file['id'], width: 300),
      fullSize: _client.assets.getAssetUrl(file['id']),
    );
  }
}

class GalleryImage {
  final String id;
  final String title;
  final String thumbnail;
  final String fullSize;
  
  GalleryImage({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.fullSize,
  });
}
```

## Widget Flutter pour avatar utilisateur

```dart
class DirectusAvatar extends StatelessWidget {
  final String? fileId;
  final double size;
  final DirectusClient client;
  
  const DirectusAvatar({
    required this.client,
    this.fileId,
    this.size = 40,
  });
  
  @override
  Widget build(BuildContext context) {
    if (fileId == null || fileId!.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        child: Icon(Icons.person, size: size * 0.6),
      );
    }
    
    return CircleAvatar(
      radius: size / 2,
      backgroundImage: NetworkImage(
        client.assets.getAvatarUrl(fileId!, size: size.toInt() * 2),
      ),
    );
  }
}
```

## Widget Flutter pour image responsive

```dart
class DirectusImage extends StatelessWidget {
  final String fileId;
  final DirectusClient client;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const DirectusImage({
    required this.client,
    required this.fileId,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcule la largeur optimale
        final width = constraints.maxWidth.toInt();
        final optimalWidth = _getOptimalWidth(width);
        
        return Image.network(
          client.assets.getAssetUrl(
            fileId,
            transforms: [
              AssetTransform(
                width: optimalWidth,
                quality: 85,
                format: AssetFormat.webp,
              ),
            ],
          ),
          fit: fit,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return placeholder ?? Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
              ),
            );
          },
          errorBuilder: (_, __, ___) {
            return errorWidget ?? Icon(Icons.broken_image);
          },
        );
      },
    );
  }
  
  int _getOptimalWidth(int containerWidth) {
    // Breakpoints standards
    const breakpoints = [320, 640, 768, 1024, 1280, 1920];
    return breakpoints.firstWhere(
      (bp) => bp >= containerWidth,
      orElse: () => breakpoints.last,
    );
  }
}
```

## Bonnes pratiques

### 1. Toujours spécifier des dimensions

```dart
// ❌ Charge l'image originale (potentiellement énorme)
client.assets.getAssetUrl('file-id')

// ✅ Spécifie les dimensions
client.assets.getAssetUrl('file-id', transforms: [
  AssetTransform(width: 800, quality: 85),
])
```

### 2. Utiliser WebP quand possible

```dart
AssetTransform(
  width: 800,
  format: AssetFormat.webp,  // Plus léger que jpg/png
  quality: 85,
)
```

### 3. Implémenter le lazy loading

```dart
// Flutter: utilisez des packages comme cached_network_image
CachedNetworkImage(
  imageUrl: url,
  placeholder: (_, __) => shimmerPlaceholder,
)
```

### 4. Précharger les images critiques

```dart
@override
void initState() {
  super.initState();
  precacheImage(
    NetworkImage(client.assets.getAssetUrl('hero-image-id')),
    context,
  );
}
```

### 5. Gérer les erreurs d'upload

```dart
try {
  await client.files.uploadFile(filePath: path, title: title);
} on DirectusValidationException catch (e) {
  // Fichier trop grand, type non autorisé, etc.
  print('Validation: ${e.message}');
} on DirectusException catch (e) {
  print('Erreur: ${e.message}');
}
```

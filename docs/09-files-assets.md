# Gestion des fichiers et assets

Ce guide explique comment gérer les fichiers et transformer les images avec Directus.

## Fichiers (Files)

`client.files` manipule des `DirectusFile` (voir [Services système](12-system-services.md)).

### Lister et lire

```dart
final page = await client.files.readMany(
  query: QueryParameters(
    filter: Filter.field('type').startsWith('image/'),
    sort: ['-uploaded_on'],
    limit: 20,
    meta: ['filter_count'],
  ),
);

for (final file in page.data) {
  print('${file.filenameDownload.value} — ${file.filesize.value} octets');
  print('${file.width.value}x${file.height.value}, image: ${file.isImage}');
}

final file = await client.files.readOne('file-uuid');
```

### Upload (objet)

```dart
final bytes = await File('/path/to/photo.jpg').readAsBytes();

final file = await client.files.upload(
  bytes: bytes,
  filename: 'photo.jpg',
  file: DirectusFile.empty()
    ..title.set('Ma photo')
    ..description.set('Prise en montagne')
    ..folder.set('folder-uuid')
    ..tags.set(['photo', 'nature']),
);
print('Fichier envoyé : ${file.id}');
```

Les métadonnées sont envoyées **avant** le binaire dans le multipart : Directus ignore les champs placés après le fichier.

Variantes acceptant des `Map` : `uploadFile(filePath: ...)` (VM uniquement, pas Flutter Web) et `uploadFileFromBytes(bytes: ..., filename: ...)`. Elles prennent `title`, `folder` et `metadata`.

> Depuis Directus 12.5, `storage` doit correspondre à un emplacement de `STORAGE_LOCATIONS`. Sinon Directus renvoie `INVALID_PAYLOAD`.

### Remplacer le contenu d'un fichier

```dart
await client.files.replace('file-uuid', bytes: newBytes, filename: 'photo-v2.jpg');
```

### Import depuis une URL

```dart
final imported = await client.files.importFromUrl(
  'https://example.com/image.jpg',
  file: DirectusFile.empty()..title.set('Image importée')..folder.set('folder-uuid'),
);
```

### Mettre à jour les métadonnées

```dart
final file = await client.files.readOne('file-uuid');
file.title.set('Nouveau titre');
file.tags.set(['updated']);
await client.files.updateOne(file); // seuls les champs modifiés sont envoyés
```

### Supprimer

```dart
await client.files.deleteOne(file);
await client.files.deleteMany(keys: ['uuid-1', 'uuid-2']);
```

### Télécharger

```dart
final bytes = await client.assets.download('file-uuid');
final zip = await client.assets.downloadFilesZip(['uuid-1', 'uuid-2']);
final folderZip = await client.assets.downloadFolderZip('folder-uuid');
```

## Dossiers (Folders)

`client.folders` manipule des `DirectusFolder`.

```dart
// Lister (depuis Directus 12.4, les admins voient aussi les dossiers de flows)
final page = await client.folders.readMany(
  query: QueryParameters(filter: Filter.field('type').equals('files')),
);
for (final folder in page.data) {
  print('${folder.name.value} (${folder.id}) racine: ${folder.isRootFolder}');
}

// Créer
final photos = await client.folders.createOne(
  DirectusFolder.empty()
    ..name.set('Photos 2026')
    ..parent.set('parent-folder-uuid'), // optionnel
);

// Renommer
photos!.name.set('Photos');
await client.folders.updateOne(photos);

// Supprimer
await client.folders.deleteOne(photos);
```

Helpers : `getRootFolders()`, `getSubFolders(parentId)`, `moveFolder()`, `renameFolder()`.

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

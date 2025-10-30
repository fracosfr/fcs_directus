# File Management

Guide complet de la gestion des fichiers et assets avec fcs_directus.

## 📁 Introduction

Directus fournit un système complet de gestion de fichiers (Digital Asset Management) avec support des transformations d'images, métadonnées, et organisation en dossiers.

## 📤 Upload de fichiers

### Upload depuis un fichier local

```dart
import 'dart:io';

final file = File('/path/to/image.jpg');

final result = await directus.files.upload(
  file: file,
  title: 'Mon image',
  description: 'Description de l'image',
  folder: 'folder-id', // Optionnel
  tags: ['photo', 'nature'],
);

print('Fichier uploadé: ${result.data?['id']}');
```

### Upload depuis des bytes

```dart
import 'dart:typed_data';

final Uint8List bytes = ...; // Vos données binaires

final result = await directus.files.uploadFromBytes(
  bytes: bytes,
  filename: 'image.jpg',
  title: 'Mon image',
  type: 'image/jpeg',
);
```

### Upload avec image_picker (Flutter)

```dart
import 'package:image_picker/image_picker.dart';

Future<void> uploadPhoto() async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  
  if (image == null) return;
  
  final bytes = await image.readAsBytes();
  
  final result = await directus.files.uploadFromBytes(
    bytes: bytes,
    filename: image.name,
    title: 'Photo depuis galerie',
    type: 'image/${image.name.split('.').last}',
  );
  
  print('✅ Photo uploadée: ${result.data?['id']}');
}
```

### Import depuis URL

```dart
final result = await directus.files.import(
  url: 'https://example.com/image.jpg',
  title: 'Image importée',
);
```

## 📥 Télécharger des fichiers

### Obtenir l'URL d'un fichier

```dart
final fileId = 'file-id';
final fileUrl = directus.files.getFileUrl(fileId);

print('URL: $fileUrl');
// https://your-directus-instance.com/assets/file-id
```

### Lire les métadonnées

```dart
final result = await directus.files.readOne(id: 'file-id');

final file = result.data;
print('Titre: ${file?['title']}');
print('Type: ${file?['type']}');
print('Taille: ${file?['filesize']} bytes');
print('Largeur: ${file?['width']}');
print('Hauteur: ${file?['height']}');
```

### Liste des fichiers

```dart
final files = await directus.files.readMany(
  query: QueryParameters(
    filter: Filter.field('type').startsWith('image/'),
    sort: ['-uploaded_on'],
    limit: 20,
  ),
);

for (final file in files.data ?? []) {
  print('${file['title']}: ${file['filename_download']}');
}
```

## 🖼️ Transformations d'images

### Redimensionner

```dart
final transform = AssetTransform(
  width: 400,
  height: 300,
  fit: AssetFit.cover,
  quality: 80,
);

final url = directus.files.getFileUrl(
  'file-id',
  transform: transform,
);

// URL: .../assets/file-id?width=400&height=300&fit=cover&quality=80
```

### Options de fit

```dart
// Cover: remplit les dimensions, crop si nécessaire
AssetFit.cover

// Contain: contient dans les dimensions, préserve ratio
AssetFit.contain

// Inside: redimensionne pour tenir dedans
AssetFit.inside

// Outside: redimensionne pour remplir
AssetFit.outside
```

### Format

```dart
final transform = AssetTransform(
  width: 800,
  format: AssetFormat.webp,
  quality: 85,
);
```

### Formats supportés

```dart
AssetFormat.jpg
AssetFormat.png
AssetFormat.webp
AssetFormat.tiff
AssetFormat.avif
```

### Transformations avancées

```dart
final transform = AssetTransform(
  width: 600,
  height: 400,
  fit: AssetFit.cover,
  format: AssetFormat.webp,
  quality: 85,
  
  // Focal point (pour le crop intelligent)
  focalPointX: 50, // 0-100
  focalPointY: 50, // 0-100
  
  // Recadrage manuel
  cropX: 0,
  cropY: 0,
  cropWidth: 1000,
  cropHeight: 1000,
);
```

## 🎨 Presets de transformations

### Créer des presets

Dans Directus, créez des presets réutilisables :

```dart
// Preset défini dans Directus: "thumbnail" = 200x200, cover, webp
final url = directus.files.getFileUrl(
  'file-id',
  preset: 'thumbnail',
);
```

### Presets communs

```dart
class ImagePresets {
  static const thumbnail = 'thumbnail';      // 200x200
  static const small = 'small';             // 400x400
  static const medium = 'medium';           // 800x800
  static const large = 'large';             // 1200x1200
  static const hero = 'hero';               // 1920x1080
}

// Utilisation
final url = directus.files.getFileUrl(fileId, preset: ImagePresets.thumbnail);
```

## 📂 Organisation en dossiers

### Créer un dossier

```dart
final folder = await directus.folders.createOne(item: {
  'name': 'Photos de produits',
  'parent': null, // null = racine, ou ID d'un dossier parent
});

final folderId = folder.data?['id'];
```

### Lister les dossiers

```dart
final folders = await directus.folders.readMany(
  query: QueryParameters(
    filter: {'parent': {'_null': true}}, // Dossiers racine
  ),
);
```

### Upload dans un dossier

```dart
await directus.files.upload(
  file: file,
  folder: folderId,
  title: 'Image dans dossier',
);
```

### Hiérarchie de dossiers

```dart
// Créer une structure
final productsFolder = await directus.folders.createOne(
  item: {'name': 'Products'},
);

final electronicsFolder = await directus.folders.createOne(
  item: {
    'name': 'Electronics',
    'parent': productsFolder.data?['id'],
  },
);

// Upload dans sous-dossier
await directus.files.upload(
  file: laptopImage,
  folder: electronicsFolder.data?['id'],
);
```

## ✏️ Mettre à jour un fichier

### Métadonnées

```dart
await directus.files.updateOne(
  id: 'file-id',
  item: {
    'title': 'Nouveau titre',
    'description': 'Nouvelle description',
    'tags': ['updated', 'new-tag'],
    'folder': 'new-folder-id',
  },
);
```

### Remplacer le fichier

```dart
// Supprimer l'ancien et uploader le nouveau
await directus.files.deleteOne(id: 'old-file-id');

final newFile = await directus.files.upload(
  file: File('/path/to/new-file.jpg'),
  title: 'Fichier remplacé',
);
```

## 🗑️ Supprimer des fichiers

```dart
// Supprimer un fichier
await directus.files.deleteOne(id: 'file-id');

// Supprimer plusieurs fichiers
await directus.files.deleteMany(ids: ['id1', 'id2', 'id3']);

// Supprimer tous les fichiers d'un dossier
final filesInFolder = await directus.files.readMany(
  query: QueryParameters(
    filter: {'folder': {'_eq': 'folder-id'}},
    fields: ['id'],
  ),
);

final ids = filesInFolder.data?.map((f) => f['id'] as String).toList() ?? [];
await directus.files.deleteMany(ids: ids);
```

## 🎯 Exemples pratiques

### Galerie d'images

```dart
class ImageGallery extends StatefulWidget {
  @override
  _ImageGalleryState createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  List<Map<String, dynamic>> images = [];
  
  @override
  void initState() {
    super.initState();
    _loadImages();
  }
  
  Future<void> _loadImages() async {
    final result = await directus.files.readMany(
      query: QueryParameters(
        filter: Filter.field('type').startsWith('image/'),
        sort: ['-uploaded_on'],
        limit: 50,
      ),
    );
    
    setState(() {
      images = result.data ?? [];
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        final url = directus.files.getFileUrl(
          image['id'],
          transform: AssetTransform(
            width: 300,
            height: 300,
            fit: AssetFit.cover,
            format: AssetFormat.webp,
          ),
        );
        
        return Image.network(url, fit: BoxFit.cover);
      },
    );
  }
}
```

### Upload avec progress

```dart
Future<void> uploadWithProgress(File file) async {
  print('📤 Upload en cours...');
  
  try {
    final result = await directus.files.upload(
      file: file,
      onUploadProgress: (sent, total) {
        final progress = (sent / total * 100).toStringAsFixed(0);
        print('Progress: $progress%');
      },
    );
    
    print('✅ Upload terminé: ${result.data?['id']}');
  } catch (e) {
    print('❌ Erreur upload: $e');
  }
}
```

### Avatar utilisateur

```dart
class UserProfile {
  Future<void> updateAvatar(File imageFile) async {
    // 1. Upload l'image
    final uploadResult = await directus.files.upload(
      file: imageFile,
      folder: 'avatars',
      title: 'Avatar ${directus.auth.userId}',
    );
    
    final avatarId = uploadResult.data?['id'];
    
    // 2. Mettre à jour l'utilisateur
    await directus.users.updateOne(
      id: directus.auth.userId!,
      item: {'avatar': avatarId},
    );
    
    print('✅ Avatar mis à jour');
  }
  
  String getAvatarUrl(String userId, {int size = 100}) {
    return directus.files.getFileUrl(
      userId,
      transform: AssetTransform(
        width: size,
        height: size,
        fit: AssetFit.cover,
        format: AssetFormat.webp,
      ),
    );
  }
}
```

## 💡 Bonnes pratiques

### 1. Utiliser les transformations côté serveur

✅ **Bon** :
```dart
// Transformation côté serveur
final url = directus.files.getFileUrl(
  fileId,
  transform: AssetTransform(width: 400),
);
```

❌ **À éviter** :
```dart
// Image complète, redimensionnée côté client
final url = directus.files.getFileUrl(fileId);
// Puis redimensionner avec Flutter
```

### 2. Utiliser des presets

```dart
// Définir des presets dans Directus
final thumbnail = directus.files.getFileUrl(id, preset: 'thumbnail');
final hero = directus.files.getFileUrl(id, preset: 'hero');
```

### 3. Organiser avec des dossiers

```dart
// Structure claire
- Products/
  - Electronics/
  - Clothing/
- Users/
  - Avatars/
  - Covers/
```

### 4. Compresser avant upload

```dart
import 'package:image/image.dart' as img;

Future<File> compressImage(File file) async {
  final image = img.decodeImage(await file.readAsBytes());
  if (image == null) return file;
  
  final compressed = img.encodeJpg(image, quality: 85);
  final compressedFile = File('${file.path}_compressed.jpg');
  await compressedFile.writeAsBytes(compressed);
  
  return compressedFile;
}
```

### 5. Gérer les erreurs

```dart
try {
  await directus.files.upload(file: file);
} on DirectusException catch (e) {
  if (e.code == 413) {
    print('Fichier trop volumineux');
  } else if (e.code == 415) {
    print('Type de fichier non supporté');
  }
}
```

## ⚠️ Limitations

- Taille maximale des fichiers (configurable dans Directus)
- Types de fichiers autorisés (configurable)
- Quota de stockage (selon hébergement)
- Transformations limitées aux images

## 🔗 Prochaines étapes

- [**Error Handling**](11-error-handling.md) - Gestion erreurs
- [**Services**](08-services.md) - Services disponibles

## 📚 Référence API

- [FilesService](api-reference/services/files-service.md)
- [FoldersService](api-reference/services/folders-service.md)
- [AssetTransform](api-reference/models/asset-transforms.md)

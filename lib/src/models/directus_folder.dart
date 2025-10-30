import 'directus_model.dart';

/// Représente un dossier (folder) Directus.
///
/// Les dossiers permettent d'organiser les fichiers de manière hiérarchique
/// dans Directus. Ils sont utilisés pour créer une structure de dossiers
/// virtuels pour les fichiers.
///
/// Exemple d'utilisation :
/// ```dart
/// // Créer un dossier racine
/// final folder = DirectusFolder.empty()
///   ..name.set('New York');
/// await client.folders.createFolder(folder.toMap());
///
/// // Créer un sous-dossier
/// final subfolder = DirectusFolder.empty()
///   ..name.set('Photos')
///   ..parent.set('parent-folder-id');
/// await client.folders.createFolder(subfolder.toMap());
///
/// // Récupérer les dossiers racines
/// final rootFolders = await client.folders.getRootFolders();
///
/// // Récupérer les sous-dossiers
/// final subfolders = await client.folders.getSubFolders('parent-folder-id');
/// ```
class DirectusFolder extends DirectusModel {
  /// Nom du dossier
  late final name = stringValue('name');

  /// Identifiant du dossier parent (Many-to-One vers folders)
  /// Permet de créer une hiérarchie de dossiers imbriqués
  /// Null si c'est un dossier racine
  late final parent = stringValue('parent');

  DirectusFolder(super.data);
  DirectusFolder.empty() : super.empty();

  @override
  String get itemName => 'directus_folders';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusFolder factory(Map<String, dynamic> data) =>
      DirectusFolder(data);

  /// Vérifie si le dossier est un dossier racine (sans parent)
  bool get isRootFolder => parent.valueOrNull == null;

  /// Vérifie si le dossier a un parent
  bool get hasParent => parent.isNotEmpty;

  /// Obtient le dossier parent s'il a été chargé avec deep
  DirectusFolder? get parentFolder =>
      getDirectusModelOrNull<DirectusFolder>('parent');

  /// Obtient le nom du dossier parent
  String? get parentName => parentFolder?.name.valueOrNull;

  /// Obtient un résumé du dossier
  String get summary {
    final folderName = name.valueOrNull ?? 'Dossier sans nom';
    if (isRootFolder) {
      return '$folderName (racine)';
    }
    final parentName = this.parentName ?? 'parent inconnu';
    return '$folderName (parent: $parentName)';
  }
}

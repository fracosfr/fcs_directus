import 'directus_model.dart';

/// Représente un fichier Directus (`directus_files`).
///
/// ```dart
/// final page = await client.files.readMany(
///   query: QueryParameters(filter: Filter.field('type').startsWith('image/')),
/// );
/// for (final file in page.data) {
///   print('${file.filenameDownload.value} (${file.filesize.value} octets)');
/// }
///
/// final file = await client.files.readOne('file-id');
/// file.title.set('Nouveau titre');
/// await client.files.updateOne(file);
/// ```
class DirectusFile extends DirectusModel {
  /// Emplacement de stockage (doit correspondre à `STORAGE_LOCATIONS`)
  late final storage = stringValue('storage');

  /// Nom du fichier sur le disque
  late final filenameDisk = stringValue('filename_disk');

  /// Nom du fichier proposé au téléchargement
  late final filenameDownload = stringValue('filename_download');

  /// Titre du fichier
  late final title = stringValue('title');

  /// Type MIME (ex: `image/jpeg`)
  late final type = stringValue('type');

  /// Dossier parent (Many-to-One vers `directus_folders`)
  late final folder = stringValue('folder');

  /// Utilisateur ayant envoyé le fichier
  late final uploadedBy = stringValue('uploaded_by');

  /// Date d'envoi
  late final uploadedOn = dateTimeValue('uploaded_on');

  /// Taille en octets
  late final filesize = intValue('filesize');

  /// Largeur (images)
  late final width = intValue('width');

  /// Hauteur (images)
  late final height = intValue('height');

  /// Durée en secondes (audio/vidéo)
  late final duration = intValue('duration');

  /// Description du fichier
  late final description = stringValue('description');

  /// Localisation
  late final location = stringValue('location');

  /// Tags
  late final tags = listValue<String>('tags');

  /// Métadonnées extraites (EXIF, IPTC...)
  late final metadata = jsonValue('metadata');

  /// Point focal horizontal (px)
  late final focalPointX = intValue('focal_point_x');

  /// Point focal vertical (px)
  late final focalPointY = intValue('focal_point_y');

  DirectusFile(super.data);
  DirectusFile.empty() : super.empty();

  @override
  String get itemName => 'directus_files';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusFile factory(Map<String, dynamic> data) => DirectusFile(data);

  /// Vrai si le fichier est une image
  bool get isImage => type.value.startsWith('image/');

  /// Vrai si le fichier est une vidéo
  bool get isVideo => type.value.startsWith('video/');
}

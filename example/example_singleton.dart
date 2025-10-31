import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation des collections Singleton dans Directus
///
/// Un singleton est une collection qui ne contient qu'un seul item unique,
/// idéal pour les configurations globales, paramètres, etc.
void main() async {
  // Configuration du client
  final directus = DirectusClient(
    DirectusConfig(baseUrl: 'https://your-directus-url.com'),
  );

  // Authentification avec token statique
  await directus.auth.loginWithToken('your-static-token');

  // Exemple 1 : Settings globaux (Map)
  await example1GlobalSettings(directus);

  // Exemple 2 : Settings avec modèle typé
  await example2TypedSettings(directus);

  // Exemple 3 : Settings avec DirectusModel (Active Record)
  await example3ActiveRecordSettings(directus);

  // Exemple 4 : Multi-langues avec singleton
  await example4MultiLanguage(directus);
}

/// Exemple 1 : Gestion des settings globaux avec Map
Future<void> example1GlobalSettings(DirectusClient directus) async {
  print('=== Exemple 1 : Settings Globaux (Map) ===\n');

  final settingsService = directus.items('settings');

  try {
    // Récupérer les settings
    final settings = await settingsService.readSingleton();
    print('Settings actuels:');
    print('  Site name: ${settings['site_name']}');
    print('  Maintenance: ${settings['maintenance_mode']}');
    print('  Contact email: ${settings['contact_email']}');

    // Mettre à jour les settings
    final updated = await settingsService.updateSingleton({
      'site_name': 'Mon Super Site',
      'maintenance_mode': false,
      'contact_email': 'contact@example.com',
    });

    print('\nSettings mis à jour:');
    print('  Site name: ${updated['site_name']}');
    print('  Maintenance: ${updated['maintenance_mode']}');
  } catch (e) {
    print('Erreur: $e');
  }

  print('');
}

/// Exemple 2 : Settings avec modèle Dart typé
Future<void> example2TypedSettings(DirectusClient directus) async {
  print('=== Exemple 2 : Settings avec Modèle Typé ===\n');

  final settingsService = directus.items<AppSettings>('settings');

  try {
    // Récupérer avec conversion en objet typé
    final settings = await settingsService.readSingleton(
      fromJson: (json) => AppSettings.fromJson(json),
    );

    print('Settings actuels (typé):');
    print('  Site name: ${settings.siteName}');
    print('  Maintenance: ${settings.maintenanceMode}');
    print('  Max upload: ${settings.maxUploadSize} MB');
    print('  Logo URL: ${settings.logoUrl}');

    // Mettre à jour avec validation
    final updated = await settingsService.updateSingleton({
      'site_name': 'Nouveau nom',
      'max_upload_size': 50,
      'allowed_file_types': ['jpg', 'png', 'pdf'],
    }, fromJson: (json) => AppSettings.fromJson(json));

    print('\nSettings mis à jour:');
    print('  Site name: ${updated.siteName}');
    print('  Max upload: ${updated.maxUploadSize} MB');
    print('  Types autorisés: ${updated.allowedFileTypes.join(', ')}');
  } catch (e) {
    print('Erreur: $e');
  }

  print('');
}

/// Exemple 3 : Settings avec DirectusModel (Active Record)
Future<void> example3ActiveRecordSettings(DirectusClient directus) async {
  print('=== Exemple 3 : Settings avec DirectusModel ===\n');

  final settingsService = directus.itemsOf<SettingsModel>();

  try {
    // Récupérer en DirectusModel
    final settings = await settingsService.readSingleton();

    print('Settings actuels (DirectusModel):');
    print('  Site name: ${settings.siteName.value}');
    print('  Maintenance: ${settings.maintenanceMode.value}');

    // Modifier et sauvegarder
    settings.siteName.set('Site Modifié via Active Record');
    settings.maintenanceMode.set(true);

    final updated = await settingsService.updateSingleton(settings);

    print('\nSettings mis à jour:');
    print('  Site name: ${updated.siteName.value}');
    print('  Maintenance: ${updated.maintenanceMode.value}');
  } catch (e) {
    print('Erreur: $e');
  }

  print('');
}

/// Exemple 4 : Configuration multi-langues
Future<void> example4MultiLanguage(DirectusClient directus) async {
  print('=== Exemple 4 : Configuration Multi-langues ===\n');

  final translationService = directus.items('translation_config');

  try {
    // Récupérer la config de traduction
    final config = await translationService.readSingleton(
      query: QueryParameters(fields: ['*', 'available_languages.*']),
    );

    print('Configuration traduction:');
    print('  Langue par défaut: ${config['default_language']}');
    print('  Langues disponibles: ${config['available_languages']}');
    print('  Fallback activé: ${config['enable_fallback']}');

    // Ajouter une nouvelle langue
    final languages = List<String>.from(config['available_languages'] ?? []);
    if (!languages.contains('es')) {
      languages.add('es');

      await translationService.updateSingleton({
        'available_languages': languages,
        'last_updated': DateTime.now().toIso8601String(),
      });

      print('\nLangue espagnole ajoutée aux langues disponibles');
    }
  } catch (e) {
    print('Erreur: $e');
  }

  print('');
}

// ============================================================================
// MODÈLES
// ============================================================================

/// Modèle typé pour les settings de l'application
class AppSettings {
  final String siteName;
  final bool maintenanceMode;
  final String contactEmail;
  final int maxUploadSize;
  final String? logoUrl;
  final List<String> allowedFileTypes;
  final Map<String, dynamic>? metadata;

  AppSettings({
    required this.siteName,
    required this.maintenanceMode,
    required this.contactEmail,
    required this.maxUploadSize,
    this.logoUrl,
    this.allowedFileTypes = const [],
    this.metadata,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      siteName: json['site_name'] as String? ?? 'Default Site',
      maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      contactEmail: json['contact_email'] as String? ?? '',
      maxUploadSize: json['max_upload_size'] as int? ?? 10,
      logoUrl: json['logo_url'] as String?,
      allowedFileTypes:
          (json['allowed_file_types'] as List?)?.cast<String>() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'site_name': siteName,
      'maintenance_mode': maintenanceMode,
      'contact_email': contactEmail,
      'max_upload_size': maxUploadSize,
      if (logoUrl != null) 'logo_url': logoUrl,
      'allowed_file_types': allowedFileTypes,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Modèle avec DirectusModel pour utilisation Active Record
class SettingsModel extends DirectusModel {
  SettingsModel(super.data);
  SettingsModel.empty() : super.empty();

  @override
  String get itemName => 'settings';

  // Properties
  late final siteName = stringValue('site_name');
  late final maintenanceMode = boolValue('maintenance_mode');
  late final contactEmail = stringValue('email');
  late final maxUploadSize = intValue('max_upload_size');
  late final logoUrl = stringValue('logo_url');
  late final metadata = jsonValue('metadata');

  /// Activer le mode maintenance
  void enableMaintenance() => maintenanceMode.set(true);

  /// Désactiver le mode maintenance
  void disableMaintenance() => maintenanceMode.set(false);

  /// Vérifier si le type de fichier est autorisé
  bool isFileTypeAllowed(String extension) {
    final allowed = metadata.asList() ?? [];
    return allowed.contains(extension.toLowerCase());
  }
}

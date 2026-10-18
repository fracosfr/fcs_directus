import 'directus_model.dart';

/// Paramètres du projet (`directus_settings`, singleton `/settings`).
///
/// Seuls les champs les plus courants sont typés ; les autres restent
/// accessibles via `getString('cle')`, `jsonValue('cle')`, etc.
///
/// ```dart
/// final settings = await client.settings.read();
/// print(settings.projectName.value);
///
/// settings.projectColor.set('#6644FF');
/// await client.settings.update(settings); // n'envoie que les champs modifiés
/// ```
class DirectusSettings extends DirectusModel {
  late final projectName = stringValue('project_name');
  late final projectUrl = stringValue('project_url');
  late final projectColor = stringValue('project_color');
  late final projectLogo = stringValue('project_logo');
  late final projectDescriptor = stringValue('project_descriptor');
  late final defaultLanguage = stringValue('default_language');
  late final defaultAppearance = stringValue('default_appearance');
  late final publicForeground = stringValue('public_foreground');
  late final publicBackground = stringValue('public_background');
  late final publicNote = stringValue('public_note');
  late final authLoginAttempts = intValue('auth_login_attempts');
  late final authPasswordPolicy = stringValue('auth_password_policy');
  late final storageAssetTransform = stringValue('storage_asset_transform');
  late final storageAssetPresets = jsonValue('storage_asset_presets');
  late final storageDefaultFolder = stringValue('storage_default_folder');
  late final moduleBar = jsonValue('module_bar');
  late final projectOwner = stringValue('project_owner');
  late final projectUsage = stringValue('project_usage');
  late final orgName = stringValue('org_name');

  DirectusSettings(super.data);
  DirectusSettings.empty() : super.empty();

  @override
  String get itemName => 'directus_settings';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusSettings factory(Map<String, dynamic> data) =>
      DirectusSettings(data);
}

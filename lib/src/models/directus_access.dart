import 'directus_model.dart';

/// Lien d'attribution d'une policy à un rôle ou à un utilisateur
/// (`directus_access`, endpoint `/access`).
///
/// ```dart
/// final link = DirectusAccess.empty()
///   ..policy.set('policy-id')
///   ..user.set('user-id');
/// await client.access.createOne(link);
/// ```
class DirectusAccess extends DirectusModel {
  /// Rôle bénéficiaire (exclusif avec [user])
  late final role = stringValue('role');

  /// Utilisateur bénéficiaire (exclusif avec [role])
  late final user = stringValue('user');

  /// Policy attribuée
  late final policy = stringValue('policy');

  /// Ordre de tri
  late final sort = intValue('sort');

  DirectusAccess(super.data);
  DirectusAccess.empty() : super.empty();

  @override
  String get itemName => 'directus_access';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusAccess factory(Map<String, dynamic> data) =>
      DirectusAccess(data);
}

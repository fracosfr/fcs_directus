import 'directus_model.dart';

/// Représente une politique Directus avec toutes les propriétés système.
///
/// Les politiques définissent un ensemble spécifique de permissions d'accès
/// et constituent une unité composable qui peut être attribuée à la fois
/// aux rôles et aux utilisateurs.
///
/// Exemple d'utilisation :
/// ```dart
/// final policy = DirectusPolicy(data);
///
/// // Vérifier si c'est une politique admin
/// if (policy.isAdminPolicy) {
///   print('Cette politique donne un accès complet');
/// }
///
/// // Vérifier l'accès à l'application
/// if (policy.hasAppAccess) {
///   print('Peut accéder au Data Studio');
/// }
///
/// // Vérifier si 2FA est requis
/// if (policy.requiresTwoFactor) {
///   print('Authentification à deux facteurs obligatoire');
/// }
/// ```
class DirectusPolicy extends DirectusModel {
  /// Nom de la politique
  late final name = stringValue('name');

  /// Icône de la politique (affichée dans le Data Studio)
  late final icon = stringValue('icon');

  /// Description de la politique (affichée dans le Data Studio)
  late final description = stringValue('description');

  /// Liste CSV d'adresses IP auxquelles cette politique s'applique
  /// Permet de configurer une liste blanche d'adresses IP
  /// Si vide, aucune restriction IP n'est appliquée
  late final ipAccess = stringValue('ip_access');

  /// Indique si l'authentification à deux facteurs est requise
  /// pour les utilisateurs ayant cette politique
  late final enforceTfa = boolValue('enforce_tfa');

  /// Si cette politique accorde à l'utilisateur un accès administrateur
  /// Cela signifie que les utilisateurs avec cette politique ont
  /// des permissions complètes sur tout
  late final adminAccess = boolValue('admin_access');

  /// Indique si les utilisateurs avec cette politique ont accès
  /// à l'utilisation du Data Studio
  late final appAccess = boolValue('app_access');

  /// Les utilisateurs auxquels cette politique est directement attribuée
  /// N'inclut pas les utilisateurs qui reçoivent cette politique via un rôle
  /// Many-to-many vers users via access
  late final users = listValue<String>('users');

  /// Les rôles auxquels cette politique est attribuée
  /// Many-to-many vers roles via access
  late final roles = listValue<String>('roles');

  /// Les permissions attribuées à cette politique
  /// One-to-many vers permissions
  late final permissions = listValue<String>('permissions');

  DirectusPolicy(super.data);
  DirectusPolicy.empty() : super.empty();

  @override
  String get itemName => 'directus_policies';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusPolicy factory(Map<String, dynamic> data) =>
      DirectusPolicy(data);

  /// Vérifie si c'est une politique d'administration complète
  bool get isAdminPolicy => adminAccess.value == true;

  /// Vérifie si la politique donne accès à l'application Data Studio
  bool get hasAppAccess => appAccess.value == true;

  /// Vérifie si l'authentification à deux facteurs est requise
  bool get requiresTwoFactor => enforceTfa.value == true;

  /// Vérifie si la politique a des restrictions IP
  bool get hasIpRestrictions => ipAccess.isNotEmpty;

  /// Vérifie si la politique a des permissions définies
  bool get hasPermissions => permissions.isNotEmpty;

  /// Vérifie si la politique est attribuée à des utilisateurs
  bool get hasUsers => users.isNotEmpty;

  /// Vérifie si la politique est attribuée à des rôles
  bool get hasRoles => roles.isNotEmpty;

  /// Active l'accès administrateur
  void enableAdminAccess() => adminAccess.set(true);

  /// Désactive l'accès administrateur
  void disableAdminAccess() => adminAccess.set(false);

  /// Active l'accès à l'application
  void enableAppAccess() => appAccess.set(true);

  /// Désactive l'accès à l'application
  void disableAppAccess() => appAccess.set(false);

  /// Active l'obligation d'authentification à deux facteurs
  void enableTwoFactor() => enforceTfa.set(true);

  /// Désactive l'obligation d'authentification à deux facteurs
  void disableTwoFactor() => enforceTfa.set(false);

  /// Définit les restrictions IP (format CSV)
  void setIpRestrictions(List<String> ips) {
    ipAccess.set(ips.join(','));
  }

  /// Obtient la liste des IPs autorisées
  List<String> getIpList() {
    final ips = ipAccess.valueOrNull;
    if (ips == null || ips.isEmpty) return [];
    return ips
        .split(',')
        .map((ip) => ip.trim())
        .where((ip) => ip.isNotEmpty)
        .toList();
  }
}

import 'directus_model.dart';
import 'directus_role.dart';
import 'directus_policy.dart';

/// Représente un utilisateur Directus avec toutes les propriétés système.
///
/// Cette classe peut être étendue pour ajouter des champs personnalisés :
///
/// ```dart
/// class CustomUser extends DirectusUser {
///   late final department = stringValue('department');
///   late final phoneNumber = stringValue('phone_number');
///   late final isVerified = boolValue('is_verified');
///
///   CustomUser(super.data);
///   CustomUser.empty() : super.empty();
///
///   static CustomUser factory(Map<String, dynamic> data) => CustomUser(data);
/// }
///
/// // Utilisation
/// DirectusClient.registerFactory(CustomUser.factory);
/// final users = client.itemsOf<CustomUser>();
/// ```
class DirectusUser extends DirectusModel {
  // Note: id, dateCreated, dateUpdated, userCreated, userUpdated sont hérités de DirectusModel

  /// Prénom de l'utilisateur
  late final firstName = stringValue('first_name');

  /// Nom de famille de l'utilisateur
  late final lastName = stringValue('last_name');

  /// Adresse email unique de l'utilisateur
  late final email = stringValue('email');

  /// Mot de passe de l'utilisateur (uniquement en écriture)
  late final password = stringValue('password');

  /// Localisation de l'utilisateur
  late final location = stringValue('location');

  /// Titre/Fonction de l'utilisateur
  late final title = stringValue('title');

  /// Description de l'utilisateur
  late final description = stringValue('description');

  /// Tags associés à l'utilisateur
  late final tags = listValue<String>('tags');

  /// Avatar de l'utilisateur (Many-to-One vers files)
  late final avatar = stringValue('avatar');

  /// Langue de l'interface Directus pour cet utilisateur
  late final language = stringValue('language');

  /// Secret 2FA pour la génération de mots de passe à usage unique
  late final tfaSecret = stringValue('tfa_secret');

  /// Statut de l'utilisateur : active, invited, draft, suspended, deleted
  late final status = stringValue('status');

  /// Rôle de l'utilisateur (Many-to-One vers roles)
  late final role = modelValue<DirectusRole>('role');

  /// Token statique pour l'utilisateur
  late final token = stringValue('token');

  /// Politiques associées à cet utilisateur (Many-to-Many vers policies)
  late final policies = modelListValue<DirectusPolicy>('policies');

  /// Date et heure de la dernière utilisation de l'API
  late final lastAccess = dateTimeValue('last_access');

  /// Dernière page visitée par l'utilisateur
  late final lastPage = stringValue('last_page');

  /// Fournisseur d'authentification utilisé pour l'enregistrement
  late final provider = stringValue('provider');

  /// Identifiant de l'utilisateur dans le fournisseur tiers
  late final externalIdentifier = stringValue('external_identifier');

  /// Données d'authentification fournies par le fournisseur tiers
  late final authData = objectValue('auth_data');

  /// Si activé, l'utilisateur recevra des emails pour les notifications
  late final emailNotifications = boolValue('email_notifications');

  /// Apparence de l'interface : auto, light, dark
  late final appearance = stringValue('appearance');

  /// Thème à utiliser en mode sombre
  late final themeDark = stringValue('theme_dark');

  /// Thème à utiliser en mode clair
  late final themeLight = stringValue('theme_light');

  /// Personnalisation du thème clair
  late final themeLightOverrides = objectValue('theme_light_overrides');

  /// Personnalisation du thème sombre
  late final themeDarkOverrides = objectValue('theme_dark_overrides');

  DirectusUser(super.data);
  DirectusUser.empty() : super.empty();

  @override
  String get itemName => 'directus_users';

  /// Factory pour l'enregistrement dans DirectusClient
  static DirectusUser factory(Map<String, dynamic> data) => DirectusUser(data);

  /// Obtient le nom complet de l'utilisateur
  String? get fullName {
    final first = firstName.valueOrNull;
    final last = lastName.valueOrNull;
    if (first == null && last == null) return null;
    if (first == null) return last;
    if (last == null) return first;
    return '$first $last';
  }

  /// Vérifie si l'utilisateur est actif
  bool get isActive => status.value == 'active';

  /// Vérifie si l'utilisateur est invité
  bool get isInvited => status.value == 'invited';

  /// Vérifie si l'utilisateur est suspendu
  bool get isSuspended => status.value == 'suspended';

  /// Vérifie si l'utilisateur est en brouillon
  bool get isDraft => status.value == 'draft';

  /// Vérifie si l'utilisateur a activé la 2FA
  bool get hasTwoFactorAuth => tfaSecret.isNotEmpty;

  /// Vérifie si l'utilisateur a un avatar
  bool get hasAvatar => avatar.isNotEmpty;

  /// Active l'utilisateur
  void activate() => status.set('active');

  /// Suspend l'utilisateur
  void suspend() => status.set('suspended');

  /// Change l'apparence de l'interface
  void setAppearance(String mode) {
    if (!['auto', 'light', 'dark'].contains(mode)) {
      throw ArgumentError('Mode must be: auto, light, or dark');
    }
    appearance.set(mode);
  }

  late final policiesItem = modelListValueM2M<DirectusPolicy>(
    'policies',
    "policy",
  );

  /// Récupère toutes les politiques de l'utilisateur
  ///
  /// Cette méthode retourne les politiques assignées directement à l'utilisateur
  /// ainsi que celles héritées de son rôle, en éliminant les doublons.
  ///
  /// Pour que cette méthode fonctionne correctement, l'utilisateur doit être récupéré
  /// avec les champs suivants :
  /// - `policies.*` pour les politiques directes
  /// - `role.policies.*` pour les politiques du rôle
  ///
  /// Exemple :
  /// ```dart
  /// final me = await users.me(
  ///   query: QueryParameters()
  ///     ..fields = ['*', 'policies.*', 'role.policies.*'],
  /// );
  ///
  /// final allPolicies = me.getAllPolicies();
  /// print('Total policies: ${allPolicies.length}');
  ///
  /// for (final policy in allPolicies) {
  ///   print('- ${policy.name.value}: admin=${policy.isAdminPolicy}');
  /// }
  /// ```
  List<DirectusPolicy> getAllPolicies() {
    // Récupérer les politiques directes de l'utilisateur
    final userPolicies = policiesItem.value;

    // Récupérer les politiques du rôle
    final userRole = role.value;
    final rolePolicies = userRole?.policiesItem.value ?? [];

    // Combiner les deux listes
    final allPolicies = <DirectusPolicy>[...userPolicies];

    // Ajouter les politiques du rôle qui ne sont pas déjà présentes
    for (final rolePolicy in rolePolicies) {
      // Vérifier si la politique n'est pas déjà dans la liste
      // On compare par ID
      final policyId = rolePolicy.id;
      if (policyId == null) continue;

      final alreadyExists = allPolicies.any((p) => p.id == policyId);

      if (!alreadyExists) {
        allPolicies.add(rolePolicy);
      }
    }

    return allPolicies;
  }
}

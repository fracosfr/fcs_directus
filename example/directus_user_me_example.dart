import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation de me() avec DirectusUser typé
///
/// Démontre :
/// - Utilisation avec DirectusUser par défaut
/// - Utilisation avec classe personnalisée
/// - Enregistrement de factory
/// - Manipulation de l'utilisateur connecté

void main() async {
  // Configuration du client Directus
  final config = DirectusConfig(baseUrl: 'https://directus.example.com');
  final client = DirectusClient(config);

  // Authentification
  await client.auth.login(email: 'admin@example.com', password: 'password');

  final users = client.users;

  print('=== DirectusUser me() Examples ===\n');

  // ========================================
  // 1. Utilisation avec DirectusUser par défaut
  // ========================================
  print('1. Using Default DirectusUser');

  // Récupérer l'utilisateur connecté
  final me = await users.me();

  print('User ID: ${me.id}');
  print('Email: ${me.email}');
  print('Full Name: ${me.fullName}');
  print('Status: ${me.status}');
  print('Is Active: ${me.isActive}');
  print('Language: ${me.language}');
  print('Has 2FA: ${me.hasTwoFactorAuth}');

  // Utiliser les property wrappers
  print('\nFirst Name: ${me.firstName.value}');
  print('Last Name: ${me.lastName.value}');
  print('Role: ${me.role.value}');

  print('\n========================================\n');

  // ========================================
  // 2. Modifier l'utilisateur courant
  // ========================================
  print('2. Updating Current User');

  // Modifier avec les property wrappers
  me.firstName.set('John');
  me.lastName.set('Updated');
  me.language.set('fr-FR');
  me.appearance.set('dark');
  me.emailNotifications.set(true);

  // Sauvegarder les modifications
  final updated = await users.updateMe(me.toJson());
  print('User updated: ${updated.fullName}');
  print('Language: ${updated.language}');
  print('Appearance: ${updated.appearance}');

  print('\n========================================\n');

  // ========================================
  // 3. Utilisation avec classe personnalisée
  // ========================================
  print('3. Using Custom User Class');

  // Enregistrer la factory pour CustomUser
  DirectusModel.registerFactory<CustomUser>(CustomUser.factory);

  // Récupérer l'utilisateur avec le type personnalisé
  final customMe = await users.me<CustomUser>();

  print('User: ${customMe.fullName}');
  print('Email: ${customMe.email}');

  // Accéder aux champs personnalisés
  print('Department: ${customMe.department.value}');
  print('Phone: ${customMe.phoneNumber.value}');
  print('Verified: ${customMe.isVerified.value}');
  print('Experience: ${customMe.yearsOfExperience.value} years');

  // Utiliser les méthodes personnalisées
  print('Can access admin: ${customMe.canAccessAdmin}');
  print('Display info: ${customMe.displayInfo}');

  // Modifier les champs personnalisés
  customMe.department.set('Engineering');
  customMe.phoneNumber.set('+33 6 12 34 56 78');
  customMe.isVerified.set(true);
  customMe.yearsOfExperience.set(5);

  // Utiliser les méthodes utilitaires
  customMe.incrementExperience();
  print(
    'Experience after increment: ${customMe.yearsOfExperience.value} years',
  );

  // Sauvegarder
  final updatedCustom = await users.updateMe<CustomUser>(customMe.toJson());
  print('Custom user updated: ${updatedCustom.displayInfo}');

  print('\n========================================\n');

  // ========================================
  // 4. Cas d'usage pratiques
  // ========================================
  print('4. Practical Use Cases');

  // Vérifier les permissions
  final currentUser = await users.me();
  if (currentUser.isActive) {
    print('✓ User is active');
  }

  if (currentUser.hasTwoFactorAuth) {
    print('✓ 2FA is enabled');
  }

  // Changer l'apparence en fonction de l'heure
  final hour = DateTime.now().hour;
  final appearance = (hour >= 6 && hour < 18) ? 'light' : 'dark';
  currentUser.setAppearance(appearance);
  await users.updateMe(currentUser.toJson());
  print('Appearance set to: $appearance');

  // Activer les notifications si pas déjà fait
  if (!currentUser.emailNotifications.value) {
    currentUser.emailNotifications.set(true);
    await users.updateMe(currentUser.toJson());
    print('Email notifications enabled');
  }

  // Récupérer avec des champs spécifiques
  final meWithFields = await users.me(
    query: QueryParameters(
      fields: ['id', 'email', 'first_name', 'last_name', 'role'],
    ),
  );
  print('User with specific fields: ${meWithFields.email}');

  print('\n========================================\n');

  // ========================================
  // 5. Gestion des erreurs
  // ========================================
  print('5. Error Handling');

  try {
    // Essayer d'utiliser un type personnalisé sans factory
    await users.me<AnotherCustomUser>();
  } catch (e) {
    print('Expected error: $e');
    // StateError: No factory registered for type AnotherCustomUser
  }

  // Enregistrer la factory puis réessayer
  DirectusModel.registerFactory<AnotherCustomUser>(AnotherCustomUser.factory);
  final anotherMe = await users.me<AnotherCustomUser>();
  print('Success with registered factory: ${anotherMe.email}');

  // Nettoyer
  client.dispose();

  print('\n=== Examples Complete ===');
}

/// Exemple de classe personnalisée héritant de DirectusUser
///
/// Ajoute des champs spécifiques à votre application.
class CustomUser extends DirectusUser {
  // Champs personnalisés
  late final department = stringValue('department');
  late final phoneNumber = stringValue('phone_number');
  late final isVerified = boolValue('is_verified');
  late final joinDate = dateTimeValue('join_date');
  late final yearsOfExperience = intValue('years_of_experience');

  CustomUser(super.data);
  CustomUser.empty() : super.empty();

  static CustomUser factory(Map<String, dynamic> data) => CustomUser(data);

  // Méthodes personnalisées
  void incrementExperience() {
    yearsOfExperience.increment();
  }

  bool get canAccessAdmin {
    return isActive && isVerified.value && department.value == 'Engineering';
  }

  String get displayInfo {
    return '${fullName ?? email.value} (${department.valueOrNull ?? "No dept"})';
  }
}

/// Autre exemple de classe personnalisée
class AnotherCustomUser extends DirectusUser {
  late final badgeNumber = stringValue('badge_number');
  late final accessLevel = intValue('access_level');

  AnotherCustomUser(super.data);
  AnotherCustomUser.empty() : super.empty();

  static AnotherCustomUser factory(Map<String, dynamic> data) {
    return AnotherCustomUser(data);
  }
}

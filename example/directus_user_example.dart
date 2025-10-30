import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation de DirectusUser et UsersService
///
/// Démontre :
/// - Utilisation du modèle DirectusUser
/// - Toutes les opérations CRUD sur les utilisateurs
/// - Gestion de l'utilisateur courant (/me)
/// - Invitations et enregistrement
/// - Two-Factor Authentication (2FA)
/// - Classe personnalisée héritant de DirectusUser

void main() async {
  // Configuration du client Directus
  final config = DirectusConfig(baseUrl: 'https://directus.example.com');
  final client = DirectusClient(config);

  // Authentification
  await client.auth.login(email: 'admin@example.com', password: 'password');

  final users = client.users;

  print('=== DirectusUser Examples ===\n');

  // ========================================
  // 1. CRUD de base
  // ========================================
  print('1. CRUD Operations');

  // Récupérer tous les utilisateurs
  final allUsers = await users.getUsers(
    query: QueryParameters(
      fields: ['id', 'first_name', 'last_name', 'email', 'status'],
      filter: {
        'status': {'_eq': 'active'},
      },
      limit: 10,
    ),
  );
  print('Active users: ${allUsers.data.length}');

  // Récupérer un utilisateur spécifique
  final user = await users.getUser('user-id-123');
  print('User: ${user['first_name']} ${user['last_name']}');

  // Créer un nouvel utilisateur
  final newUser = await users.createUser({
    'email': 'newuser@example.com',
    'password': 'SecurePassword123!',
    'first_name': 'John',
    'last_name': 'Doe',
    'role': 'role-id-abc',
    'status': 'active',
  });
  print('New user created: ${newUser['id']}');

  // Créer plusieurs utilisateurs
  final multipleUsers = await users.createUsers([
    {
      'email': 'user1@example.com',
      'password': 'pass1',
      'first_name': 'Alice',
      'role': 'role-id',
    },
    {
      'email': 'user2@example.com',
      'password': 'pass2',
      'first_name': 'Bob',
      'role': 'role-id',
    },
  ]);
  print('Created ${multipleUsers.length} users\n');

  // Mettre à jour un utilisateur
  final updated = await users.updateUser('user-id-123', {
    'first_name': 'Jane',
    'last_name': 'Smith',
  });
  print('Updated user: ${updated['first_name']}');

  // Mettre à jour plusieurs utilisateurs
  await users.updateUsers(
    keys: ['user-id-1', 'user-id-2'],
    data: {'status': 'suspended'},
  );

  // Supprimer un utilisateur
  await users.deleteUser('user-id-to-delete');

  // Supprimer plusieurs utilisateurs
  await users.deleteUsers(['id-1', 'id-2', 'id-3']);

  print('\n========================================\n');

  // ========================================
  // 2. Utilisateur courant (/me)
  // ========================================
  print('2. Current User Operations');

  // Récupérer l'utilisateur courant
  final me = await users.me();
  print('Current user: ${me.email.value}');
  print('Role: ${me.role.value}');

  // Mettre à jour l'utilisateur courant
  me.firstName.set('Updated');
  me.language.set('fr-FR');
  me.appearance.set('dark');
  await users.updateMe(me.toJson());
  print('Profile updated');

  // Mettre à jour la dernière page visitée
  await users.updateLastPage('/admin/content/articles');

  print('\n========================================\n');

  // ========================================
  // 3. Invitations
  // ========================================
  print('3. User Invitations');

  // Inviter un seul utilisateur
  await users.inviteUsers(email: 'newuser@example.com', roleId: 'role-id-abc');
  print('Invitation sent to newuser@example.com');

  // Inviter plusieurs utilisateurs
  await users.inviteUsers(
    email: ['user1@company.com', 'user2@company.com', 'user3@company.com'],
    roleId: 'role-id-abc',
  );
  print('Invitations sent to 3 users');

  // Inviter avec URL personnalisée
  await users.inviteUsers(
    email: 'vip@example.com',
    roleId: 'admin-role-id',
    inviteUrl: 'https://myapp.com/join',
  );

  // L'utilisateur invité accepte l'invitation
  // (Cette action serait faite depuis l'email par l'utilisateur invité)
  await users.acceptInvite(
    token: 'invitation-token-from-email',
    password: 'NewSecurePassword123!',
  );
  print('Invitation accepted');

  print('\n========================================\n');

  // ========================================
  // 4. Enregistrement public
  // ========================================
  print('4. Public Registration');

  // Enregistrer un nouvel utilisateur (auto-inscription)
  await users.register(
    email: 'public@example.com',
    password: 'Password123!',
    firstName: 'Public',
    lastName: 'User',
  );
  print('User registered (verification email sent)');

  // Vérifier l'email
  // (Cette action serait faite depuis l'email par l'utilisateur)
  await users.verifyEmail('verification-token-from-email');
  print('Email verified');

  print('\n========================================\n');

  // ========================================
  // 5. Two-Factor Authentication (2FA)
  // ========================================
  print('5. Two-Factor Authentication');

  // Générer un secret 2FA
  final tfaSecret = await users.generateTwoFactorSecret();
  print('2FA Secret: ${tfaSecret['secret']}');
  print('QR Code URL: ${tfaSecret['otpauth_url']}');
  // Afficher ce QR code à l'utilisateur dans votre app

  // L'utilisateur scanne le QR code et génère un OTP
  // Activer la 2FA
  await users.enableTwoFactor(
    secret: tfaSecret['secret'] as String,
    otp: '123456', // Code OTP généré par l'app d'authentification
  );
  print('2FA enabled');

  // Plus tard, pour désactiver la 2FA
  await users.disableTwoFactor('654321'); // OTP actuel
  print('2FA disabled');

  print('\n========================================\n');

  // ========================================
  // 6. Utilisation avec le modèle DirectusUser
  // ========================================
  print('6. Using DirectusUser Model');

  // Récupérer un utilisateur et l'encapsuler dans DirectusUser
  final userData = await users.getUser('user-id-123');
  final directusUser = DirectusUser(userData);

  print('User: ${directusUser.fullName ?? directusUser.email}');
  print('  Status: ${directusUser.status}');
  print('  Active: ${directusUser.isActive}');
  print('  Has 2FA: ${directusUser.hasTwoFactorAuth}');
  print('  Has Avatar: ${directusUser.hasAvatar}');

  // Créer un utilisateur avec le modèle
  final modelUser = DirectusUser.empty()
    ..email.set('model@example.com')
    ..password.set('Pass123!')
    ..firstName.set('Model')
    ..lastName.set('User')
    ..role.setById('role-id')
    ..language.set('fr-FR')
    ..appearance.set('dark')
    ..emailNotifications.set(true);

  final createdData = await users.createUser(modelUser.toJson());
  final createdUser = DirectusUser(createdData);
  print('\nUser created via model: ${createdUser.id}');

  // Utiliser les méthodes pratiques
  createdUser.activate();
  print('User activated');

  createdUser.setAppearance('light');
  print('Appearance changed to light mode');

  await users.updateUser(createdUser.id!, createdUser.toJson());

  print('\n========================================\n');

  // ========================================
  // 7. Classe personnalisée héritant de DirectusUser
  // ========================================
  print('7. Custom User Class');

  // Voir la classe CustomUser en bas de ce fichier

  // Créer un utilisateur avec champs personnalisés
  final customUser = CustomUser.empty()
    ..email.set('custom@example.com')
    ..password.set('Password123!')
    ..firstName.set('Custom')
    ..lastName.set('User')
    ..role.setById('role-id')
    // Champs personnalisés
    ..department.set('Engineering')
    ..phoneNumber.set('+33 6 12 34 56 78')
    ..isVerified.set(true)
    ..joinDate.setToday()
    ..yearsOfExperience.set(5);

  final customUserData = await users.createUser(customUser.toJson());
  final createdCustomUser = CustomUser(customUserData);
  print('Custom user created: ${createdCustomUser.id}');
  print('  Department: ${createdCustomUser.department}');
  print('  Phone: ${createdCustomUser.phoneNumber}');
  print('  Verified: ${createdCustomUser.isVerified}');
  print('  Experience: ${createdCustomUser.yearsOfExperience} years');

  // Utiliser les méthodes personnalisées
  createdCustomUser.incrementExperience();
  print(
    '  Experience incremented: ${createdCustomUser.yearsOfExperience} years',
  );

  print('  Can access admin: ${createdCustomUser.canAccessAdmin}');

  await users.updateUser(createdCustomUser.id!, createdCustomUser.toJson());

  // Récupérer tous les utilisateurs personnalisés
  final allCustomUsers = await users.getUsers(
    query: QueryParameters(
      filter: {
        'is_verified': {'_eq': true},
      },
    ),
  );
  print('\nVerified custom users: ${allCustomUsers.data.length}');

  // Nettoyer
  client.dispose();
}

/// Exemple de classe personnalisée héritant de DirectusUser
///
/// Permet d'ajouter des champs spécifiques à votre application
/// tout en conservant tous les champs système de Directus.
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
    return '${fullName ?? email} (${department.valueOrNull ?? "No dept"})';
  }
}

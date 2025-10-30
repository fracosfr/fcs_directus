import 'package:fcs_directus/fcs_directus.dart';

/// Exemple d'utilisation du système de tracking des modifications (dirty tracking)
/// dans DirectusModel.
///
/// Cette fonctionnalité permet de :
/// - Tracker automatiquement les champs modifiés
/// - Envoyer uniquement les modifications lors des UPDATE
/// - Gérer de manière transparente les relations Many-to-One et Many-to-Many
/// - Annuler les modifications ou marquer le modèle comme propre

void main() async {
  // Configuration du client
  final config = DirectusConfig(baseUrl: 'https://directus.example.com');
  final client = DirectusClient(config);

  // Authentification
  await client.auth.login(email: 'admin@example.com', password: 'password');

  final users = client.users;

  print('=== DIRTY TRACKING DANS DIRECTUS MODEL ===\n');

  // ========================================
  // 1. CRÉATION - Pas de dirty tracking
  // ========================================
  print('1. CRÉATION D\'UN UTILISATEUR');
  print('-' * 50);

  final newUser = DirectusUser.empty();
  print('isDirty après création vide: ${newUser.isDirty}'); // false
  print('dirtyFields: ${newUser.dirtyFields}\n'); // {}

  // Remplir les champs
  newUser.email.set('john.doe@example.com');
  print('isDirty après email: ${newUser.isDirty}'); // true
  print('dirtyFields: ${newUser.dirtyFields}'); // {email}

  newUser.password.set('SecurePass123!');
  newUser.firstName.set('John');
  newUser.lastName.set('Doe');
  newUser.role.setById('role-admin-123');

  print('isDirty: ${newUser.isDirty}'); // true
  print(
    'dirtyFields: ${newUser.dirtyFields}',
  ); // {email, password, first_name, last_name, role}

  // Pour la création, on utilise toJson() qui retourne tout
  print('\nJSON pour CREATE:');
  print(newUser.toJson());

  // Créer l'utilisateur
  // final created = await users.createUser(newUser.toJson());
  print('\n');

  // ========================================
  // 2. RÉCUPÉRATION ET MODIFICATION
  // ========================================
  print('2. RÉCUPÉRATION ET MODIFICATION');
  print('-' * 50);

  // Simuler la récupération depuis Directus
  final userData = {
    'id': 'user-123',
    'email': 'john.doe@example.com',
    'first_name': 'John',
    'last_name': 'Doe',
    'status': 'active',
    'role': {
      'id': 'role-admin-123',
      'name': 'Administrator',
      'icon': 'verified_user',
    },
    'policies': [
      {'id': 'policy-1', 'name': 'Full Access'},
      {'id': 'policy-2', 'name': 'Admin Panel'},
    ],
    'date_created': '2025-01-01T10:00:00Z',
    'date_updated': '2025-01-15T14:30:00Z',
  };

  final user = DirectusUser(userData);

  print('isDirty après chargement: ${user.isDirty}'); // false
  print('dirtyFields: ${user.dirtyFields}'); // {}
  print('Email actuel: ${user.email.value}'); // john.doe@example.com

  // Modifier quelques champs
  user.firstName.set('Jean');
  print('\nAprès modification firstName:');
  print('isDirty: ${user.isDirty}'); // true
  print('dirtyFields: ${user.dirtyFields}'); // {first_name}
  print('Valeur actuelle: ${user.firstName.value}'); // Jean
  print('Valeur originale: ${user.getOriginalValue('first_name')}'); // John

  user.lastName.set('Dupont');
  user.appearance.set('dark');

  print('\nAprès modifications supplémentaires:');
  print('isDirty: ${user.isDirty}'); // true
  print(
    'dirtyFields: ${user.dirtyFields}',
  ); // {first_name, last_name, appearance}

  print('\n');

  // ========================================
  // 3. UPDATE AVEC toJsonDirty()
  // ========================================
  print('3. UPDATE AVEC DIRTY TRACKING');
  print('-' * 50);

  // Avec toJson() : Envoie TOUT (y compris les relations complètes)
  print('toJson() - Données complètes:');
  final fullJson = user.toJson();
  print('Nombre de clés: ${fullJson.keys.length}');
  print('Contient role complet: ${fullJson['role'] is Map}'); // true
  print('Role: ${fullJson['role']}\n');

  // Avec toJsonDirty() : Envoie uniquement les modifications
  print('toJsonDirty() - Uniquement les modifications:');
  final dirtyJson = user.toJsonDirty();
  print('Nombre de clés: ${dirtyJson.keys.length}'); // 3
  print('Données: $dirtyJson');
  // {first_name: Jean, last_name: Dupont, appearance: dark}

  // Envoyer à Directus
  // await users.updateUser(user.id!, user.toJsonDirty());
  print('\n');

  // ========================================
  // 4. MODIFICATION DE RELATIONS
  // ========================================
  print('4. GESTION DES RELATIONS');
  print('-' * 50);

  // Le rôle est un objet complet après récupération
  print('Rôle actuel (objet complet):');
  print('  role.value.name = ${user.role.value?.name.value}'); // Administrator

  // Modifier le rôle
  user.role.setById('role-editor-456');

  print('\nAprès modification du rôle:');
  print('isDirtyField("role"): ${user.isDirtyField('role')}'); // true

  // toJsonDirty() extrait automatiquement l'ID
  final dirtyWithRole = user.toJsonDirty();
  print('toJsonDirty() pour le rôle:');
  print('  role: ${dirtyWithRole['role']}'); // role-editor-456 (juste l'ID)

  // Modifier les politiques (Many-to-Many)
  user.policies.setByIds(['policy-3', 'policy-4']);

  print('\nAprès modification des politiques:');
  final dirtyWithPolicies = user.toJsonDirty();
  print('toJsonDirty() pour les politiques:');
  print('  policies: ${dirtyWithPolicies['policies']}'); // [policy-3, policy-4]
  print('\n');

  // ========================================
  // 5. ANNULATION DES MODIFICATIONS (revert)
  // ========================================
  print('5. ANNULATION DES MODIFICATIONS');
  print('-' * 50);

  print('Avant revert:');
  print('firstName: ${user.firstName.value}'); // Jean
  print('isDirty: ${user.isDirty}'); // true
  print('dirtyFields: ${user.dirtyFields}');

  // Annuler toutes les modifications
  user.revert();

  print('\nAprès revert:');
  print('firstName: ${user.firstName.value}'); // John (restauré)
  print('lastName: ${user.lastName.value}'); // Doe (restauré)
  print('isDirty: ${user.isDirty}'); // false
  print('dirtyFields: ${user.dirtyFields}'); // {}
  print('\n');

  // ========================================
  // 6. MARQUER COMME PROPRE (markClean)
  // ========================================
  print('6. MARQUER COMME PROPRE APRÈS SAUVEGARDE');
  print('-' * 50);

  // Modifier à nouveau
  user.firstName.set('Jean');
  user.appearance.set('light');

  print('Avant sauvegarde:');
  print('isDirty: ${user.isDirty}'); // true
  print('dirtyFields: ${user.dirtyFields}'); // {first_name, appearance}

  // Simuler la sauvegarde
  // await users.updateUser(user.id!, user.toJsonDirty());

  // Marquer comme propre après succès
  user.markClean();

  print('\nAprès markClean():');
  print('isDirty: ${user.isDirty}'); // false
  print('dirtyFields: ${user.dirtyFields}'); // {}
  print('firstName conservé: ${user.firstName.value}'); // Jean
  print('\n');

  // ========================================
  // 7. WORKFLOW COMPLET
  // ========================================
  print('7. WORKFLOW COMPLET');
  print('-' * 50);

  print('ÉTAPE 1: Récupérer');
  // final fetchedUser = DirectusUser(await users.getUser('user-123'));
  // print('isDirty: ${fetchedUser.isDirty}'); // false

  print('\nÉTAPE 2: Modifier');
  // fetchedUser.firstName.set('Modified');
  // fetchedUser.status.set('invited');
  // print('isDirty: ${fetchedUser.isDirty}'); // true
  // print('dirtyFields: ${fetchedUser.dirtyFields}'); // {first_name, status}

  print('\nÉTAPE 3: Envoyer uniquement les modifications');
  // await users.updateUser(
  //   fetchedUser.id!,
  //   fetchedUser.toJsonDirty(),  // Seulement {first_name: Modified, status: invited}
  // );

  print('\nÉTAPE 4: Marquer comme propre');
  // fetchedUser.markClean();
  // print('isDirty: ${fetchedUser.isDirty}'); // false

  print('\n');

  // ========================================
  // 8. COMPARAISON DES MÉTHODES
  // ========================================
  print('8. COMPARAISON DES MÉTHODES DE SÉRIALISATION');
  print('-' * 50);

  final testUser = DirectusUser({
    'id': 'test-123',
    'email': 'test@example.com',
    'first_name': 'Test',
    'role': {'id': 'role-123', 'name': 'Admin'},
    'date_created': '2025-01-01T10:00:00Z',
  });

  testUser.firstName.set('Modified');

  print('toJson() - Tout:');
  print('  ${testUser.toJson().keys}');

  print('\ntoMap() - Sans champs système:');
  print('  ${testUser.toMap().keys}');

  print('\ntoJsonDirty() - Uniquement modifications:');
  print('  ${testUser.toJsonDirty().keys}'); // {first_name}

  print('\n=== FIN DES EXEMPLES ===');

  client.dispose();
}

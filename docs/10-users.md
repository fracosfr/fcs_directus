# Gestion des utilisateurs

Ce guide couvre toutes les opérations liées aux utilisateurs Directus.

## Opérations CRUD

### Lister les utilisateurs

```dart
final users = await client.users.getUsers();

for (final user in users) {
  print('${user['first_name']} ${user['last_name']} (${user['email']})');
}
```

### Avec filtres

```dart
final activeUsers = await client.users.getUsers(
  query: QueryParameters(
    filter: Filter.field('status').equals('active'),
    sort: ['last_name', 'first_name'],
  ),
);
```

### Obtenir un utilisateur

```dart
final user = await client.users.getUser('user-uuid');

print('Email: ${user['email']}');
print('Nom: ${user['first_name']} ${user['last_name']}');
```

### Avec relations

```dart
final user = await client.users.getUser(
  'user-uuid',
  query: QueryParameters(
    deep: Deep({
      'role': DeepQuery().fields(['id', 'name', 'admin_access']),
      'avatar': DeepQuery().fields(['id', 'filename_download']),
    }),
  ),
);
```

### Créer un utilisateur

```dart
final newUser = await client.users.createUser({
  'email': 'user@example.com',
  'password': 'secure-password',
  'first_name': 'John',
  'last_name': 'Doe',
  'role': 'role-uuid',
  'status': 'active',
});
```

### Avec modèle DirectusUser

```dart
final newUser = DirectusUser.empty()
  ..email.set('user@example.com')
  ..password.set('secure-password')
  ..firstName.set('John')
  ..lastName.set('Doe')
  ..role.setById('role-uuid');

final created = await client.users.createUser(newUser.toJson());
```

### Mettre à jour un utilisateur

```dart
await client.users.updateUser('user-uuid', {
  'first_name': 'Jane',
  'title': 'Manager',
});
```

### Avec modèle

```dart
final user = DirectusUser(await client.users.getUser('user-uuid'));
user.firstName.set('Jane');
user.title.set('Manager');

await client.users.updateUser(user.id!, user.toJsonDirty());
```

### Supprimer un utilisateur

```dart
await client.users.deleteUser('user-uuid');
```

## Utilisateur courant

### Obtenir mes informations

```dart
final me = await client.users.me();

print('Connecté en tant que: ${me['email']}');
print('Rôle: ${me['role']}');
```

### Avec modèle typé

```dart
final me = await client.users.me<DirectusUser>();

print('Email: ${me.email.value}');
print('Nom complet: ${me.fullName}');
```

### Mettre à jour mon profil

```dart
await client.users.updateMe({
  'first_name': 'Jean',
  'language': 'fr-FR',
  'theme_light': 'auto',
});
```

## Invitations

### Inviter des utilisateurs

```dart
await client.users.inviteUsers(
  email: ['user1@example.com', 'user2@example.com'],
  roleId: 'role-uuid',
  inviteUrl: 'https://myapp.com/accept-invite',  // Optionnel
);
```

### Accepter une invitation

```dart
await client.users.acceptInvite(
  token: 'invite-token-from-email',
  password: 'user-chosen-password',
);
```

## Inscription publique

Si l'inscription publique est activée dans Directus :

### S'inscrire

```dart
await client.users.register(
  email: 'new@example.com',
  password: 'password',
  firstName: 'John',
  lastName: 'Doe',
);
```

### Vérifier l'email

```dart
await client.users.verifyEmail('verification-token-from-email');
```

## Two-Factor Authentication (2FA)

### Générer un secret

```dart
final tfa = await client.users.generateTwoFactorSecret('user-password');

if (tfa != null) {
  print('Secret: ${tfa.secret}');
  print('QR Code URL: ${tfa.qrCodeUrl}');
  
  // Afficher le QR code à l'utilisateur pour qu'il le scanne
  // avec son app d'authentification (Google Authenticator, etc.)
}
```

### Activer le 2FA

Après que l'utilisateur ait scanné le QR code et généré un code :

```dart
await client.users.enableTwoFactor(
  secret: tfa.secret,
  otp: '123456',  // Code de l'app d'authentification
);

print('2FA activé !');
```

### Désactiver le 2FA

```dart
await client.users.disableTwoFactor('123456');  // Code OTP requis

print('2FA désactivé');
```

## Gestion des policies

### Ajouter des policies à un utilisateur

```dart
await client.users.addPoliciesToUser(
  userId: 'user-uuid',
  policyIds: ['policy-1', 'policy-2'],
);
```

### Retirer des policies

```dart
await client.users.removePoliciesFromUser(
  userId: 'user-uuid',
  policyIds: ['policy-1'],
);
```

## Modèle DirectusUser

La librairie fournit un modèle pré-construit pour les utilisateurs :

```dart
class DirectusUser extends DirectusModel {
  DirectusUser(super.data);
  
  factory DirectusUser.empty() => DirectusUser({});
  
  @override
  String get itemName => 'directus_users';
  
  // Propriétés principales
  late final email = stringValue('email');
  late final password = stringValue('password');  // Écriture seule
  late final firstName = stringValue('first_name');
  late final lastName = stringValue('last_name');
  late final title = stringValue('title');
  late final description = stringValue('description');
  late final location = stringValue('location');
  late final language = stringValue('language');
  late final status = stringValue('status');
  
  // Relations
  late final role = modelValue<DirectusRole>('role');
  late final avatar = modelValue<DirectusFile>('avatar');
  
  // Propriétés calculées
  String get fullName => '${firstName.value} ${lastName.value}'.trim();
  bool get isActive => status.value == 'active';
}
```

### Utilisation

```dart
final users = await client.users.getUsers<DirectusUser>();

for (final user in users) {
  print('${user.fullName} - ${user.email.value}');
  
  if (user.avatar.isLoaded) {
    print('Avatar: ${user.avatar.model?.filename.value}');
  }
}
```

### Étendre DirectusUser

Ajoutez vos propres champs personnalisés :

```dart
class AppUser extends DirectusUser {
  AppUser(super.data);
  
  factory AppUser.empty() => AppUser({});
  
  // Champs personnalisés ajoutés à directus_users
  late final company = stringValue('company');
  late final phone = stringValue('phone');
  late final department = stringValue('department');
  late final permissions = jsonValue('custom_permissions');
  
  // Relations personnalisées
  late final manager = modelValue<AppUser>('manager');
  late final team = modelListValue<AppUser>('team_members');
}

// Enregistrer la factory
DirectusModel.registerFactory<AppUser>(AppUser.new);

// Utiliser
final me = await client.users.me<AppUser>();
print('Département: ${me.department.value}');
```

## Rôles

### Lister les rôles

```dart
final roles = await client.roles.getRoles();

for (final role in roles) {
  print('${role['name']} (admin: ${role['admin_access']})');
}
```

### Créer un rôle

```dart
final role = await client.roles.createRole({
  'name': 'Editor',
  'description': 'Can edit content',
  'admin_access': false,
  'app_access': true,
  'ip_access': null,
  'enforce_tfa': false,
});
```

### Mettre à jour un rôle

```dart
await client.roles.updateRole('role-uuid', {
  'name': 'Senior Editor',
});
```

### Supprimer un rôle

```dart
await client.roles.deleteRole('role-uuid');
```

## Policies

### Lister les policies

```dart
final policies = await client.policies.getPolicies();
```

### Créer une policy

```dart
final policy = await client.policies.createPolicy({
  'name': 'Read Only',
  'description': 'Can only read data',
});
```

### Mettre à jour

```dart
await client.policies.updatePolicy('policy-uuid', {
  'name': 'Read and Comment',
});
```

### Supprimer

```dart
await client.policies.deletePolicy('policy-uuid');
```

## Permissions

### Lister les permissions

```dart
final permissions = await client.permissions.getPermissions(
  query: QueryParameters(
    filter: Filter.field('role').equals('role-uuid'),
  ),
);
```

### Créer une permission

```dart
final permission = await client.permissions.createPermission({
  'role': 'role-uuid',
  'collection': 'articles',
  'action': 'read',
  'fields': ['*'],
  'permissions': {
    'status': {'_eq': 'published'},
  },
});
```

### Actions disponibles

- `create` : Créer des items
- `read` : Lire des items
- `update` : Modifier des items
- `delete` : Supprimer des items
- `share` : Partager des items

### Mettre à jour

```dart
await client.permissions.updatePermission('permission-uuid', {
  'fields': ['id', 'title', 'content'],
});
```

### Supprimer

```dart
await client.permissions.deletePermission('permission-uuid');
```

## Exemple complet : Système d'utilisateurs

```dart
class UserService {
  final DirectusClient _client;
  
  UserService(this._client);
  
  // === Authentification ===
  
  Future<AppUser> login(String email, String password) async {
    await _client.auth.login(email: email, password: password);
    return await getCurrentUser();
  }
  
  Future<AppUser> getCurrentUser() async {
    return await _client.users.me<AppUser>();
  }
  
  // === Gestion du profil ===
  
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (phone != null) updates['phone'] = phone;
    
    await _client.users.updateMe(updates);
  }
  
  Future<void> updateAvatar(String filePath) async {
    final file = await _client.files.uploadFile(
      filePath: filePath,
      title: 'Avatar',
    );
    await _client.users.updateMe({'avatar': file['id']});
  }
  
  // === 2FA ===
  
  Future<TwoFactorSecret?> setup2FA(String password) async {
    return await _client.users.generateTwoFactorSecret(password);
  }
  
  Future<void> enable2FA(String secret, String otp) async {
    await _client.users.enableTwoFactor(secret: secret, otp: otp);
  }
  
  Future<void> disable2FA(String otp) async {
    await _client.users.disableTwoFactor(otp);
  }
  
  // === Administration ===
  
  Future<List<AppUser>> getTeamMembers() async {
    final me = await getCurrentUser();
    return await _client.users.getUsers<AppUser>(
      query: QueryParameters(
        filter: Filter.field('manager').equals(me.id!),
      ),
    );
  }
  
  Future<AppUser> createTeamMember({
    required String email,
    required String firstName,
    required String lastName,
    required String roleId,
  }) async {
    final result = await _client.users.createUser({
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': roleId,
      'status': 'invited',
    });
    
    await _client.users.inviteUsers(
      email: [email],
      roleId: roleId,
    );
    
    return AppUser(result);
  }
  
  Future<void> deactivateUser(String userId) async {
    await _client.users.updateUser(userId, {'status': 'suspended'});
  }
}
```

## Bonnes pratiques

### 1. Ne jamais exposer les mots de passe

```dart
// ❌ Le mot de passe ne doit jamais être lu
final user = await client.users.getUser('uuid');
print(user['password']);  // null (jamais retourné par Directus)

// ✅ Utiliser password uniquement en écriture
await client.users.updateMe({'password': 'new-password'});
```

### 2. Valider côté client

```dart
Future<void> updateProfile(String firstName, String lastName) async {
  // Validation
  if (firstName.isEmpty || lastName.isEmpty) {
    throw ValidationException('Nom requis');
  }
  
  await _client.users.updateMe({
    'first_name': firstName,
    'last_name': lastName,
  });
}
```

### 3. Gérer les statuts utilisateur

```dart
// Statuts Directus standards
enum UserStatus { draft, invited, active, suspended, archived }

bool canLogin(String status) {
  return status == 'active';
}
```

### 4. Cacher les données utilisateur

```dart
// Éviter de recharger constamment
AppUser? _cachedUser;
DateTime? _cacheTime;

Future<AppUser> getCurrentUser({bool force = false}) async {
  if (!force && _cachedUser != null && 
      _cacheTime != null && 
      DateTime.now().difference(_cacheTime!) < Duration(minutes: 5)) {
    return _cachedUser!;
  }
  
  _cachedUser = await _client.users.me<AppUser>();
  _cacheTime = DateTime.now();
  return _cachedUser!;
}
```

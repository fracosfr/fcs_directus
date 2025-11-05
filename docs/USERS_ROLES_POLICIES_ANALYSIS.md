# Analyse : DirectusUser, DirectusRole et DirectusPolicy

## ⚠️ Important : Chargement des relations

**Par défaut, les relations ne sont JAMAIS chargées automatiquement.**

Lorsque vous récupérez des utilisateurs, rôles ou politiques, seuls les **IDs des relations** sont retournés par défaut. Vous devez **explicitement demander les champs** avec le paramètre `fields` dans `QueryParameters`.

```dart
// ❌ Relations NON chargées (comportement par défaut)
final user = await client.users.getUser('user-id');
// user.role.value contient seulement l'ID (String)
// user.policies.value contient seulement les IDs

// ✅ Relations chargées
final user = await client.users.getUser(
  'user-id',
  query: QueryParameters()..fields = ['*', 'role.*', 'policies.*'],
);
// user.role.value contient l'objet DirectusRole complet
// user.policies.value contient les objets DirectusPolicy complets
```

**Pourquoi ?** C'est un choix de performance :
- ✅ Réduit la taille des réponses HTTP
- ✅ Améliore les performances
- ✅ Évite de charger des données inutiles
- ✅ Donne le contrôle au développeur

---

## Vue d'ensemble

Le système de permissions Directus repose sur **trois entités principales** qui fonctionnent ensemble pour définir qui peut accéder à quoi dans votre application :

```
┌─────────────────┐     Many-to-One      ┌─────────────────┐
│                 │ ───────────────────> │                 │
│  DirectusUser   │                      │  DirectusRole   │
│                 │ <────────────────── │                 │
└─────────────────┘     One-to-Many      └─────────────────┘
        │                                         │
        │ Many-to-Many                            │ Many-to-Many
        │                                         │
        ∨                                         ∨
┌────────────────────────────────────────────────────────┐
│              DirectusPolicy                            │
│  (Définit les permissions concrètes)                   │
└────────────────────────────────────────────────────────┘
```

### Hiérarchie des permissions

1. **DirectusUser** : Représente un utilisateur individuel
   - Appartient à **un rôle** (Many-to-One)
   - Peut avoir des **politiques directes** (Many-to-Many)
   - Les permissions finales = Politiques du rôle + Politiques directes

2. **DirectusRole** : Groupe organisationnel d'utilisateurs
   - Contient **plusieurs utilisateurs** (One-to-Many)
   - A des **politiques associées** (Many-to-Many)
   - Peut hériter d'un **rôle parent** (hiérarchie)

3. **DirectusPolicy** : Définit les permissions concrètes
   - Attribuée à des **rôles** et/ou des **utilisateurs**
   - Contient des **permissions détaillées** (CRUD par collection)
   - Peut définir : accès admin, accès app, 2FA, restrictions IP

---

## 📋 DirectusUser

### Description

Représente un utilisateur Directus avec toutes ses propriétés système et personnalisées.

### Propriétés principales

#### Informations personnelles
```dart
late final firstName = stringValue('first_name');
late final lastName = stringValue('last_name');
late final email = stringValue('email');
late final avatar = stringValue('avatar');        // Many-to-One vers files
late final location = stringValue('location');
late final title = stringValue('title');
late final description = stringValue('description');
late final tags = listValue<String>('tags');
```

#### Authentification et sécurité
```dart
late final password = stringValue('password');    // Write-only
late final status = stringValue('status');        // active, invited, draft, suspended, deleted
late final token = stringValue('token');          // Static token
late final tfaSecret = stringValue('tfa_secret'); // 2FA secret
late final provider = stringValue('provider');    // Auth provider (default, google, etc.)
late final externalIdentifier = stringValue('external_identifier');
late final authData = objectValue('auth_data');
```

#### Rôle et permissions
```dart
late final role = modelValue<DirectusRole>('role');              // Many-to-One
late final policies = modelListValue<DirectusPolicy>('policies'); // Many-to-Many
```

#### Préférences et UI
```dart
late final language = stringValue('language');
late final appearance = stringValue('appearance'); // auto, light, dark
late final themeDark = stringValue('theme_dark');
late final themeLight = stringValue('theme_light');
late final themeLightOverrides = objectValue('theme_light_overrides');
late final themeDarkOverrides = objectValue('theme_dark_overrides');
late final lastPage = stringValue('last_page');
late final emailNotifications = boolValue('email_notifications');
```

#### Tracking
```dart
late final lastAccess = dateTimeValue('last_access');
```

### Méthodes utilitaires

#### Gestion du nom
```dart
String? get fullName // Combine firstName + lastName
```

#### Vérification du statut
```dart
bool get isActive      // status == 'active'
bool get isInvited     // status == 'invited'
bool get isSuspended   // status == 'suspended'
bool get isDraft       // status == 'draft'
bool get hasTwoFactorAuth // tfaSecret non vide
bool get hasAvatar     // avatar non vide
```

#### Modification du statut
```dart
void activate()        // status = 'active'
void suspend()         // status = 'suspended'
void setAppearance(String mode) // 'auto', 'light', 'dark'
```

#### ⭐ Méthode clé : getAllPolicies()

Récupère toutes les politiques effectives de l'utilisateur en combinant :
- Les politiques directes de l'utilisateur
- Les politiques héritées du rôle

```dart
List<DirectusPolicy> getAllPolicies()
```

**Important** : Pour que cette méthode fonctionne, l'utilisateur doit être récupéré avec les champs suivants :
```dart
final me = await users.me(
  query: QueryParameters()
    ..fields = ['*', 'policies.*', 'role.policies.*'],
);

final allPolicies = me.getAllPolicies();
```

### Extension personnalisée

```dart
class CustomUser extends DirectusUser {
  late final department = stringValue('department');
  late final phoneNumber = stringValue('phone_number');
  late final isVerified = boolValue('is_verified');

  CustomUser(super.data);
  CustomUser.empty() : super.empty();

  static CustomUser factory(Map<String, dynamic> data) => CustomUser(data);
}

// Enregistrement
DirectusModel.registerFactory<CustomUser>(CustomUser.factory);
final users = client.itemsOf<CustomUser>();
```

---

## 👥 DirectusRole

### Description

Les rôles sont la structure organisationnelle principale pour les utilisateurs. Un rôle regroupe des utilisateurs ayant des responsabilités similaires.

### Propriétés principales

```dart
late final name = stringValue('name');                           // Requis
late final icon = stringValue('icon');
late final description = stringValue('description');
late final parent = stringValue('parent');                       // Many-to-One vers roles
late final children = listValue<String>('children');             // One-to-Many vers roles
late final policies = modelListValue<DirectusPolicy>('policies'); // Many-to-Many vers policies
late final users = listValue<String>('users');                   // One-to-Many vers users
```

### Hiérarchie des rôles

Les rôles peuvent avoir une structure hiérarchique :

```
Admin Role
  ├─ Editor Role
  │   └─ Content Writer Role
  └─ Manager Role
      └─ Team Lead Role
```

Un rôle enfant hérite des permissions de son parent.

### Méthodes utilitaires

#### Vérifications
```dart
bool get hasParent     // parent non vide
bool get hasChildren   // children non vide
bool get hasPolicies   // policies non vide
bool get hasUsers      // users non vide

int get childrenCount  // Nombre de sous-rôles
int get policiesCount  // Nombre de politiques
int get usersCount     // Nombre d'utilisateurs
```

#### Gestion du parent
```dart
void setParent(String? parentId)
```

#### Gestion des politiques
```dart
void addPolicy(dynamic policy)      // Ajoute une politique (objet ou ID)
void removePolicy(String policyId)   // Retire une politique
```

#### Gestion des utilisateurs
```dart
void addUser(String userId)    // Ajoute un utilisateur au rôle
void removeUser(String userId) // Retire un utilisateur du rôle
```

### Exemple d'utilisation

```dart
final role = DirectusRole.empty()
  ..name.set('Content Manager')
  ..icon.set('edit')
  ..description.set('Can manage all content');

// Ajouter des politiques
role.addPolicy('policy-id-1');
role.addPolicy(policyObject);

// Définir un parent
role.setParent('admin-role-id');

// Créer le rôle
final created = await client.roles.createRole(role.toJson());
```

---

## 🔒 DirectusPolicy

### Description

Les politiques définissent un ensemble spécifique de permissions d'accès. Elles constituent une unité composable qui peut être attribuée à la fois aux rôles ET aux utilisateurs.

### Propriétés principales

#### Informations de base
```dart
late final name = stringValue('name');                // Requis
late final icon = stringValue('icon');
late final description = stringValue('description');
```

#### Contrôles d'accès
```dart
late final adminAccess = boolValue('admin_access');  // Accès admin complet
late final appAccess = boolValue('app_access');      // Accès au Data Studio
late final enforceTfa = boolValue('enforce_tfa');    // 2FA obligatoire
late final ipAccess = stringValue('ip_access');      // Liste CSV d'IPs autorisées
```

#### Relations
```dart
late final users = listValue<String>('users');            // Many-to-Many vers users
late final roles = listValue<String>('roles');            // Many-to-Many vers roles
late final permissions = listValue<String>('permissions'); // One-to-Many vers permissions
```

### Types de politiques

#### 1. Politique Admin
```dart
if (policy.isAdminPolicy) {
  // Accès complet à tout
}
```

#### 2. Politique App
```dart
if (policy.hasAppAccess) {
  // Peut accéder au Data Studio
}
```

#### 3. Politique avec 2FA
```dart
if (policy.requiresTwoFactor) {
  // Authentification à deux facteurs obligatoire
}
```

#### 4. Politique avec restrictions IP
```dart
if (policy.hasIpRestrictions) {
  final ips = policy.getIpList();
  // Seulement depuis ces IPs
}
```

### Méthodes utilitaires

#### Vérifications
```dart
bool get isAdminPolicy        // admin_access == true
bool get hasAppAccess         // app_access == true
bool get requiresTwoFactor    // enforce_tfa == true
bool get hasIpRestrictions    // ip_access non vide
bool get hasPermissions       // permissions non vide
bool get hasUsers             // users non vide
bool get hasRoles             // roles non vide
```

#### Gestion de l'accès admin
```dart
void enableAdminAccess()
void disableAdminAccess()
```

#### Gestion de l'accès app
```dart
void enableAppAccess()
void disableAppAccess()
```

#### Gestion de la 2FA
```dart
void enableTwoFactor()
void disableTwoFactor()
```

#### Gestion des restrictions IP
```dart
void setIpRestrictions(List<String> ips)  // Définit les IPs autorisées
List<String> getIpList()                   // Récupère la liste des IPs
```

### Exemple d'utilisation

```dart
final policy = DirectusPolicy.empty()
  ..name.set('Content Editor')
  ..icon.set('edit')
  ..description.set('Can edit content but not delete')
  ..appAccess.set(true)
  ..adminAccess.set(false)
  ..enforceTfa.set(false);

// Ajouter des restrictions IP
policy.setIpRestrictions(['192.168.1.0/24', '10.0.0.1']);

// Créer la politique
final created = await client.policies.createPolicy(policy.toJson());
```

---

## 🛠️ Services associés

### UsersService

Service pour gérer les utilisateurs Directus.

#### CRUD de base

**⚠️ Important** : Par défaut, les relations (`role`, `policies`) ne sont **pas** chargées. Seuls les IDs sont retournés.

```dart
// Récupérer tous les utilisateurs (IDs uniquement pour role et policies)
final allUsers = await client.users.getUsers();

// Récupérer avec relations complètes
final allUsers = await client.users.getUsers(
  query: QueryParameters()..fields = ['*', 'role.*', 'policies.*'],
);

// Récupérer un utilisateur (IDs uniquement)
final user = await client.users.getUser('user-id');

// Récupérer avec relations complètes
final user = await client.users.getUser(
  'user-id',
  query: QueryParameters()..fields = ['*', 'role.*', 'policies.*'],
);

// Créer un utilisateur
final newUser = await client.users.createUser(DirectusUser.empty()
  ..email.set('user@example.com')
  ..password.set('secure123')
  ..firstName.set('John')
  ..role.set('role-id'));

// Mettre à jour un utilisateur
final updated = await client.users.updateUser(user);

// Supprimer un utilisateur
await client.users.deleteUser(user);
```

#### Opérations batch
```dart
// Créer plusieurs utilisateurs
final users = await client.users.createUsers([user1, user2, user3]);

// Mettre à jour plusieurs
final updated = await client.users.updateUsers([user1, user2]);

// Supprimer plusieurs
await client.users.deleteUsers([user1, user2, user3]);
```

#### Utilisateur courant (/me)

**⚠️ Important** : Pour utiliser `getAllPolicies()`, chargez les relations avec `fields`.

```dart
// Récupérer l'utilisateur connecté (IDs uniquement)
final me = await client.users.me();
print(me.email.value);
print(me.fullName);

// Récupérer avec relations pour getAllPolicies()
final me = await client.users.me(
  query: QueryParameters()..fields = ['*', 'role.policies.*', 'policies.*'],
);
final allPolicies = me.getAllPolicies();

// Récupérer avec type personnalisé
final me = await client.users.me<CustomUser>(
  query: QueryParameters()..fields = ['*', 'department'],
);
print(me.department.value);

// Mettre à jour l'utilisateur connecté
await client.users.updateMe({
  'first_name': 'John',
  'last_name': 'Doe',
});

// Mettre à jour la dernière page visitée
await client.users.updateLastPage('/content/articles');
```

#### Invitations
```dart
// Inviter un utilisateur
await client.users.inviteUsers(
  email: 'user@example.com',
  roleId: 'role-id',
);

// Inviter plusieurs utilisateurs
await client.users.inviteUsers(
  email: ['user1@example.com', 'user2@example.com'],
  roleId: 'role-id',
  inviteUrl: 'https://myapp.com/invite',
);

// Accepter une invitation
await client.users.acceptInvite(
  token: 'invite-token',
  password: 'chosen-password',
);
```

#### Enregistrement public
```dart
// Permettre l'inscription publique (doit être activé dans les settings)
await client.users.register(
  email: 'newuser@example.com',
  password: 'secure123',
  firstName: 'Jane',
  lastName: 'Smith',
);

// Vérifier l'email après inscription
await client.users.verifyEmail('verification-token');
```

#### Two-Factor Authentication (2FA)
```dart
// Générer un secret 2FA
final tfa = await client.users.generateTwoFactorSecret();
print('Secret: ${tfa['secret']}');
print('QR Code URL: ${tfa['otpauth_url']}');

// Activer la 2FA
await client.users.enableTwoFactor(
  secret: tfa['secret'],
  otp: '123456', // Code généré avec le secret
);

// Désactiver la 2FA
await client.users.disableTwoFactor('123456');
```

### RolesService

Service pour gérer les rôles Directus.

#### CRUD de base
```dart
// Récupérer tous les rôles
final allRoles = await client.roles.getRoles();

// Récupérer un rôle
final role = await client.roles.getRole('role-id');

// Créer un rôle
final newRole = await client.roles.createRole({
  'name': 'Editor',
  'icon': 'edit',
  'description': 'Can edit content',
});

// Mettre à jour un rôle
final updated = await client.roles.updateRole('role-id', {
  'description': 'Updated description',
});

// Supprimer un rôle
await client.roles.deleteRole('role-id');
```

#### Opérations batch
```dart
// Créer plusieurs rôles
final roles = await client.roles.createRoles([
  {'name': 'Editor', 'icon': 'edit'},
  {'name': 'Viewer', 'icon': 'visibility'},
]);

// Mettre à jour plusieurs rôles
final updated = await client.roles.updateRoles(
  keys: ['role-1', 'role-2'],
  data: {'icon': 'group'},
);

// Supprimer plusieurs rôles
await client.roles.deleteRoles([role1, role2, role3]);
```

#### Méthodes utilitaires
```dart
// Récupérer les rôles enfants
final children = await client.roles.getChildRoles('parent-role-id');

// Récupérer le rôle parent
final parent = await client.roles.getParentRole('child-role-id');
if (parent != null) {
  print('Rôle parent: ${parent.name.value}');
}
```

### PoliciesService

Service pour gérer les politiques Directus.

#### CRUD de base
```dart
// Récupérer toutes les politiques
final allPolicies = await client.policies.getPolicies();

// Récupérer une politique
final policy = await client.policies.getPolicy('policy-id');

// Créer une politique
final newPolicy = await client.policies.createPolicy({
  'name': 'Content Manager',
  'icon': 'edit',
  'description': 'Can manage content',
  'app_access': true,
  'admin_access': false,
});

// Mettre à jour une politique
final updated = await client.policies.updatePolicy('policy-id', {
  'description': 'Updated description',
  'enforce_tfa': true,
});

// Supprimer une politique
await client.policies.deletePolicy('policy-id');
```

#### Opérations batch
```dart
// Créer plusieurs politiques
final policies = await client.policies.createPolicies([
  {'name': 'Editor', 'app_access': true},
  {'name': 'Viewer', 'app_access': true},
]);

// Mettre à jour plusieurs politiques
final updated = await client.policies.updatePolicies(
  keys: ['policy-1', 'policy-2'],
  data: {'enforce_tfa': true},
);

// Supprimer plusieurs politiques
await client.policies.deletePolicies(['policy-1', 'policy-2']);
```

#### Méthodes utilitaires
```dart
// Récupérer les politiques admin
final adminPolicies = await client.policies.getAdminPolicies();

// Récupérer les politiques avec accès app
final appPolicies = await client.policies.getAppAccessPolicies();

// Récupérer les politiques avec 2FA obligatoire
final tfaPolicies = await client.policies.getTwoFactorPolicies();
```

---

## 🔄 Relations entre les entités

**⚠️ Important** : Les relations ne sont **jamais chargées automatiquement**. Vous devez toujours spécifier les champs avec le paramètre `fields` dans `QueryParameters`.

### Comportement par défaut

```dart
// ❌ Sans fields - Retourne uniquement les IDs
final user = await client.users.getUser('user-id');
print(user.role.value); // ID du rôle (String)
print(user.policies.value); // Liste d'IDs (List<DirectusPolicy> avec seulement les IDs)

// ✅ Avec fields - Retourne les objets complets
final user = await client.users.getUser(
  'user-id',
  query: QueryParameters()..fields = ['*', 'role.*', 'policies.*'],
);
print(user.role.value?.name.value); // Nom du rôle
print(user.policies.value.first.name.value); // Nom de la politique
```

### User → Role (Many-to-One)
```dart
// Récupérer un utilisateur avec son rôle complet
final user = await client.users.getUser(
  'user-id',
  query: QueryParameters()..fields = ['*', 'role.*'],
);

final userRole = user.role.value;
if (userRole != null) {
  print('Rôle: ${userRole.name.value}');
  print('Icône: ${userRole.icon.value}');
}
```

### User → Policies (Many-to-Many)
```dart
// Récupérer un utilisateur avec ses politiques directes complètes
final user = await client.users.getUser(
  'user-id',
  query: QueryParameters()..fields = ['*', 'policies.*'],
);

for (final policy in user.policies.value) {
  print('Politique: ${policy.name.value}');
  print('Admin: ${policy.isAdminPolicy}');
}
```

### Role → Policies (Many-to-Many)
```dart
// Récupérer un rôle avec ses politiques complètes
final role = await client.roles.getRole(
  'role-id',
  query: QueryParameters()..fields = ['*', 'policies.*'],
);

for (final policy in role.policies.value) {
  print('Politique: ${policy.name.value}');
}
```

### Role → Users (One-to-Many)
```dart
// Récupérer un rôle avec ses utilisateurs complets
final role = await client.roles.getRole(
  'role-id',
  query: QueryParameters()..fields = ['*', 'users.*'],
);

print('${role.usersCount} utilisateurs dans ce rôle');
```

### Toutes les permissions d'un utilisateur

**⚠️ Critique** : Pour que `getAllPolicies()` fonctionne correctement, vous **devez** charger les relations :

```dart
// ✅ BON - Charge les relations nécessaires
final me = await client.users.me(
  query: QueryParameters()
    ..fields = ['*', 'policies.*', 'role.policies.*'],
);

final allPolicies = me.getAllPolicies();
print('Total de ${allPolicies.length} politiques');

for (final policy in allPolicies) {
  print('- ${policy.name.value}');
  print('  Admin: ${policy.isAdminPolicy}');
  print('  App: ${policy.hasAppAccess}');
  print('  2FA: ${policy.requiresTwoFactor}');
}

// ❌ MAUVAIS - getAllPolicies() ne fonctionnera pas correctement
final me = await client.users.me();
final allPolicies = me.getAllPolicies(); // Seulement les IDs
```

---

## 📊 Cas d'usage pratiques

### 1. Créer un système de permissions simple

```dart
// 1. Créer les politiques
final adminPolicy = await client.policies.createPolicy({
  'name': 'Administrator',
  'admin_access': true,
  'app_access': true,
});

final editorPolicy = await client.policies.createPolicy({
  'name': 'Editor',
  'admin_access': false,
  'app_access': true,
});

final viewerPolicy = await client.policies.createPolicy({
  'name': 'Viewer',
  'admin_access': false,
  'app_access': true,
});

// 2. Créer les rôles et assigner les politiques
final adminRole = DirectusRole.empty()
  ..name.set('Admin')
  ..icon.set('admin_panel_settings');
adminRole.addPolicy(adminPolicy);
final createdAdminRole = await client.roles.createRole(adminRole.toJson());

final editorRole = DirectusRole.empty()
  ..name.set('Editor')
  ..icon.set('edit');
editorRole.addPolicy(editorPolicy);
final createdEditorRole = await client.roles.createRole(editorRole.toJson());

// 3. Créer des utilisateurs avec ces rôles
final admin = await client.users.createUser(DirectusUser.empty()
  ..email.set('admin@example.com')
  ..password.set('admin123')
  ..firstName.set('Admin')
  ..role.set(createdAdminRole.id!));

final editor = await client.users.createUser(DirectusUser.empty()
  ..email.set('editor@example.com')
  ..password.set('editor123')
  ..firstName.set('Editor')
  ..role.set(createdEditorRole.id!));
```

### 2. Créer une hiérarchie de rôles

```dart
// Créer le rôle parent (Admin)
final adminRole = await client.roles.createRole({
  'name': 'Administrator',
  'icon': 'shield',
});

// Créer des rôles enfants
final managerRole = DirectusRole.empty()
  ..name.set('Manager')
  ..icon.set('supervisor_account');
managerRole.setParent(adminRole.id!);
final createdManager = await client.roles.createRole(managerRole.toJson());

final teamLeadRole = DirectusRole.empty()
  ..name.set('Team Lead')
  ..icon.set('groups');
teamLeadRole.setParent(createdManager.id!);
await client.roles.createRole(teamLeadRole.toJson());

// Récupérer tous les enfants d'un rôle
final children = await client.roles.getChildRoles(adminRole.id!);
print('${children.length} sous-rôles');
```

### 3. Assigner des politiques supplémentaires à un utilisateur

```dart
// Récupérer l'utilisateur
final user = await client.users.getUser(
  'user-id',
  query: QueryParameters()..fields = ['*', 'policies.*', 'role.policies.*'],
);

// Vérifier ses permissions actuelles
final currentPolicies = user.getAllPolicies();
print('Politiques actuelles: ${currentPolicies.length}');

// Ajouter une politique supplémentaire
// (doit être fait côté serveur via l'API)
await client.users.updateUser(DirectusUser({'id': user.id})
  ..policies.set([
    ...user.policies.value,
    DirectusPolicy({'id': 'new-policy-id'}),
  ]));
```

### 4. Vérifier les permissions d'un utilisateur

```dart
// Récupérer l'utilisateur avec toutes ses politiques
final me = await client.users.me(
  query: QueryParameters()
    ..fields = ['*', 'policies.*', 'role.policies.*'],
);

// Vérifier les politiques
final allPolicies = me.getAllPolicies();

// Vérifier si l'utilisateur est admin
final isAdmin = allPolicies.any((p) => p.isAdminPolicy);
print('Est admin: $isAdmin');

// Vérifier si l'utilisateur a accès à l'app
final hasAppAccess = allPolicies.any((p) => p.hasAppAccess);
print('Accès app: $hasAppAccess');

// Vérifier si 2FA est requis
final requires2FA = allPolicies.any((p) => p.requiresTwoFactor);
print('2FA requis: $requires2FA');

// Vérifier les restrictions IP
final ipRestrictions = allPolicies
    .where((p) => p.hasIpRestrictions)
    .expand((p) => p.getIpList())
    .toSet()
    .toList();
if (ipRestrictions.isNotEmpty) {
  print('IPs autorisées: ${ipRestrictions.join(", ")}');
}
```

### 5. Inviter un utilisateur avec un rôle spécifique

```dart
// Récupérer le rôle "Editor"
final roles = await client.roles.getRoles(
  query: QueryParameters()..filter = Filter.field('name').equals('Editor'),
);

if (roles.data.isNotEmpty) {
  final editorRole = roles.data.first;
  
  // Inviter un nouvel utilisateur
  await client.users.inviteUsers(
    email: 'neweditor@example.com',
    roleId: editorRole.id!,
    inviteUrl: 'https://myapp.com/accept-invite',
  );
  
  print('Invitation envoyée !');
}
```

### 6. Activer la 2FA pour l'utilisateur connecté

```dart
// Générer le secret 2FA
final tfa = await client.users.generateTwoFactorSecret();

// Afficher le QR code à l'utilisateur
// (utiliser un package comme qr_flutter pour générer le QR code)
showQRCode(tfa['otpauth_url']);

// Demander à l'utilisateur de scanner et d'entrer le code
final otp = await askUserForOTP();

// Activer la 2FA
try {
  await client.users.enableTwoFactor(
    secret: tfa['secret'],
    otp: otp,
  );
  print('2FA activée avec succès !');
} on DirectusException catch (e) {
  print('Erreur : ${e.message}');
}
```

### 7. Récupérer toutes les politiques admin

```dart
// Méthode 1 : Via le service
final adminPolicies = await client.policies.getAdminPolicies();
print('${adminPolicies.length} politiques admin');

// Méthode 2 : Via un filtre manuel
final policies = await client.policies.getPolicies(
  query: QueryParameters()
    ..filter = Filter.field('admin_access').equals(true),
);
```

### 8. Suspendre un utilisateur

```dart
// Récupérer l'utilisateur
final user = await client.users.getUser('user-id');

// Suspendre
user.suspend();

// Mettre à jour dans la base
await client.users.updateUser(user);

// Ou directement
await client.users.updateUser(DirectusUser({'id': 'user-id'})
  ..status.set('suspended'));
```

---

## 🎯 Bonnes pratiques

### 1. Toujours spécifier les champs pour les relations

**⚠️ Critique** : Les relations ne sont JAMAIS chargées automatiquement.

```dart
// ✅ BON : Spécifier explicitement les relations à charger
final me = await client.users.me(
  query: QueryParameters()
    ..fields = ['*', 'policies.*', 'role.policies.*'],
);

// ✅ BON : Charger uniquement les champs nécessaires
final users = await client.users.getUsers(
  query: QueryParameters()
    ..fields = ['id', 'email', 'first_name', 'last_name', 'role.name'],
);

// ❌ MAUVAIS : Relations non chargées
final me = await client.users.me();
// me.role.value sera un ID (String), pas un DirectusRole
// me.getAllPolicies() ne fonctionnera pas correctement

// ⚠️ ATTENTION : Charger trop de données
final users = await client.users.getUsers(
  query: QueryParameters()
    ..fields = ['*', 'role.*', 'policies.*', 'role.policies.*'],
);
// Peut être lent si beaucoup d'utilisateurs
```

**Règle d'or** : Chargez uniquement les champs dont vous avez besoin.

### 2. Utiliser getAllPolicies() pour les vérifications

```dart
// ✅ BON : Considère toutes les politiques (directes + rôle)
final allPolicies = user.getAllPolicies();
final isAdmin = allPolicies.any((p) => p.isAdminPolicy);

// ❌ MAUVAIS : Ne considère que les politiques directes
final isAdmin = user.policies.value.any((p) => p.isAdminPolicy);
```

### 3. Créer des politiques réutilisables

```dart
// ✅ BON : Politiques composables
final readPolicy = await client.policies.createPolicy({
  'name': 'Read Only',
  'app_access': true,
});

final writePolicy = await client.policies.createPolicy({
  'name': 'Write Access',
  'app_access': true,
});

// Assigner plusieurs politiques
role.addPolicy(readPolicy);
role.addPolicy(writePolicy);

// ❌ MAUVAIS : Tout dans une seule politique
final monolithicPolicy = await client.policies.createPolicy({
  'name': 'Everything',
  'admin_access': true,
});
```

### 4. Utiliser les types personnalisés

```dart
// ✅ BON : Type-safe
class MyUser extends DirectusUser {
  late final department = stringValue('department');
  MyUser(super.data);
  static MyUser factory(Map<String, dynamic> data) => MyUser(data);
}

DirectusModel.registerFactory<MyUser>(MyUser.factory);
final me = await client.users.me<MyUser>();
print(me.department.value);

// ❌ MAUVAIS : Accès manuel au JSON
final me = await client.users.me();
print(me.data['department']); // Pas type-safe
```

### 5. Gérer les erreurs d'invitation

```dart
// ✅ BON : Gestion d'erreur
try {
  await client.users.inviteUsers(
    email: 'user@example.com',
    roleId: 'role-id',
  );
  print('Invitation envoyée');
} on DirectusException catch (e) {
  if (e.errorCode == 'RECORD_NOT_UNIQUE') {
    print('Utilisateur déjà invité');
  } else {
    print('Erreur: ${e.message}');
  }
}

// ❌ MAUVAIS : Pas de gestion d'erreur
await client.users.inviteUsers(
  email: 'user@example.com',
  roleId: 'role-id',
);
```

### 6. Vérifier le statut avant modification

```dart
// ✅ BON : Vérifier le statut
if (user.isActive) {
  user.suspend();
  await client.users.updateUser(user);
}

// ❌ MAUVAIS : Suspension sans vérification
user.suspend();
await client.users.updateUser(user);
```

### 7. Nettoyer les hiérarchies de rôles

```dart
// ✅ BON : Supprimer les enfants d'abord
final children = await client.roles.getChildRoles('parent-id');
for (final child in children) {
  await client.roles.deleteRole(child.id!);
}
await client.roles.deleteRole('parent-id');

// ❌ MAUVAIS : Supprimer le parent directement
// Peut causer des erreurs d'intégrité référentielle
await client.roles.deleteRole('parent-id');
```

---

## 🔍 Résumé

| Entité | Rôle | Relations principales |
|--------|------|----------------------|
| **DirectusUser** | Représente un utilisateur individuel | • Many-to-One → DirectusRole<br>• Many-to-Many → DirectusPolicy |
| **DirectusRole** | Groupe organisationnel d'utilisateurs | • One-to-Many → DirectusUser<br>• Many-to-Many → DirectusPolicy<br>• Hiérarchie parent/enfants |
| **DirectusPolicy** | Définit les permissions concrètes | • Many-to-Many → DirectusUser<br>• Many-to-Many → DirectusRole<br>• One-to-Many → Permissions |

### Points clés

1. **Hiérarchie** : User → Role → Policies
2. **Héritage** : Un utilisateur hérite des politiques de son rôle
3. **Composition** : Les politiques peuvent être combinées
4. **Flexibilité** : Les utilisateurs peuvent avoir des politiques directes en plus de celles du rôle
5. **Granularité** : Les politiques permettent un contrôle fin des permissions

### Permissions effectives d'un utilisateur

```
Permissions finales = Politiques du rôle ∪ Politiques directes
```

Utilisez `user.getAllPolicies()` pour obtenir l'ensemble complet des politiques.

---

**Voir aussi :**
- [Documentation Authentication](./03-authentication.md)
- [Documentation Services](./08-services.md)
- [API Reference Users](../doc/api/fcs_directus/UsersService-class.html)
- [API Reference Roles](../doc/api/fcs_directus/RolesService-class.html)
- [API Reference Policies](../doc/api/fcs_directus/PoliciesService-class.html)

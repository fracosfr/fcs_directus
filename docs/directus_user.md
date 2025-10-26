# DirectusUser - Modèle utilisateur système

Le modèle `DirectusUser` représente un utilisateur Directus avec toutes les propriétés système prévues par la documentation officielle.

## Table des matières

- [Utilisation basique](#utilisation-basique)
- [Propriétés disponibles](#propriétés-disponibles)
- [Méthodes utilitaires](#méthodes-utilitaires)
- [Classe personnalisée](#classe-personnalisée)
- [Service utilisateur](#service-utilisateur)

## Utilisation basique

```dart
import 'package:fcs_directus/fcs_directus.dart';

// Récupérer un utilisateur
final userData = await client.users.getUser('user-id');
final user = DirectusUser(userData);

// Accéder aux propriétés
print('Nom: ${user.fullName}');
print('Email: ${user.email}');
print('Statut: ${user.status}');
print('Actif: ${user.isActive}');

// Créer un nouvel utilisateur
final newUser = DirectusUser.empty()
  ..email.set('john@example.com')
  ..password.set('SecurePass123!')
  ..firstName.set('John')
  ..lastName.set('Doe')
  ..role.set('role-id')
  ..language.set('fr-FR')
  ..emailNotifications.set(true);

final created = await client.users.createUser(newUser.toJson());
```

## Propriétés disponibles

### Propriétés héritées de DirectusModel

- `id` : String? - Identifiant unique
- `dateCreated` : DateTime? - Date de création
- `dateUpdated` : DateTime? - Date de modification
- `userCreated` : String? - ID de l'utilisateur créateur
- `userUpdated` : String? - ID de l'utilisateur modificateur

### Propriétés spécifiques à DirectusUser

Toutes les propriétés utilisent le système de **property wrappers** pour une syntaxe simplifiée :

#### Informations personnelles
- `firstName` : StringProperty - Prénom
- `lastName` : StringProperty - Nom de famille  
- `email` : StringProperty - Adresse email unique
- `password` : StringProperty - Mot de passe (écriture seule)

#### Profil
- `location` : StringProperty - Localisation
- `title` : StringProperty - Titre/fonction
- `description` : StringProperty - Description
- `avatar` : StringProperty - Avatar (Many-to-One vers files)
- `tags` : ListProperty<String> - Tags associés

#### Configuration
- `language` : StringProperty - Langue de l'interface (ex: 'en-US', 'fr-FR')
- `appearance` : StringProperty - Apparence ('auto', 'light', 'dark')
- `themeLight` : StringProperty - Thème mode clair
- `themeDark` : StringProperty - Thème mode sombre
- `themeLightOverrides` : ObjectProperty - Personnalisation thème clair
- `themeDarkOverrides` : ObjectProperty - Personnalisation thème sombre

#### Sécurité et authentification
- `status` : StringProperty - Statut ('active', 'invited', 'draft', 'suspended', 'deleted')
- `role` : StringProperty - Rôle (Many-to-One vers roles)
- `policies` : StringProperty - Politiques (Many-to-Many vers policies)
- `token` : StringProperty - Token statique
- `tfaSecret` : StringProperty - Secret 2FA
- `provider` : StringProperty - Fournisseur d'authentification
- `externalIdentifier` : StringProperty - ID dans le fournisseur tiers
- `authData` : ObjectProperty - Données d'authentification tierces

#### Notifications et tracking
- `emailNotifications` : BoolProperty - Recevoir des emails
- `lastAccess` : DateTimeProperty - Dernière utilisation de l'API
- `lastPage` : StringProperty - Dernière page visitée

## Méthodes utilitaires

### Getters de commodité

```dart
// Nom complet
String? fullName = user.fullName; // "John Doe"

// Vérifications de statut
bool isActive = user.isActive;       // status == 'active'
bool isInvited = user.isInvited;     // status == 'invited'
bool isSuspended = user.isSuspended; // status == 'suspended'
bool isDraft = user.isDraft;         // status == 'draft'

// Vérifications de sécurité
bool hasTfa = user.hasTwoFactorAuth; // 2FA activé
bool hasAvatar = user.hasAvatar;     // Avatar défini
```

### Méthodes de modification

```dart
// Changer le statut
user.activate();  // status = 'active'
user.suspend();   // status = 'suspended'

// Changer l'apparence
user.setAppearance('dark');  // Accepte: 'auto', 'light', 'dark'

// Sauvegarder les modifications
await client.users.updateUser(user.id!, user.toJson());
```

## Classe personnalisée

Vous pouvez facilement étendre `DirectusUser` pour ajouter vos champs personnalisés :

```dart
class CustomUser extends DirectusUser {
  // Vos champs personnalisés
  late final department = stringValue('department');
  late final phoneNumber = stringValue('phone_number');
  late final isVerified = boolValue('is_verified');
  late final joinDate = dateTimeValue('join_date');
  late final yearsOfExperience = intValue('years_of_experience');

  CustomUser(super.data);
  CustomUser.empty() : super.empty();

  static CustomUser factory(Map<String, dynamic> data) => CustomUser(data);

  // Vos méthodes personnalisées
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

// Utilisation
final user = CustomUser.empty()
  ..email.set('dev@company.com')
  ..firstName.set('Alice')
  ..role.set('role-id')
  // Champs personnalisés
  ..department.set('Engineering')
  ..phoneNumber.set('+33 6 12 34 56 78')
  ..isVerified.set(true)
  ..yearsOfExperience.set(3);

await client.users.createUser(user.toJson());
```

## Service utilisateur

Le `UsersService` offre toutes les opérations prévues par l'API Directus :

### CRUD de base

```dart
final users = client.users;

// Lister tous les utilisateurs
final allUsers = await users.getUsers(
  query: QueryParameters(
    fields: ['id', 'first_name', 'email', 'status'],
    filter: {'status': {'_eq': 'active'}},
  ),
);

// Récupérer un utilisateur
final user = await users.getUser('user-id');

// Créer un utilisateur
final newUser = await users.createUser({
  'email': 'user@example.com',
  'password': 'Password123!',
  'first_name': 'John',
  'role': 'role-id',
});

// Créer plusieurs utilisateurs
final multipleUsers = await users.createUsers([
  {'email': 'user1@example.com', 'password': 'pass1', 'role': 'role-id'},
  {'email': 'user2@example.com', 'password': 'pass2', 'role': 'role-id'},
]);

// Mettre à jour un utilisateur
await users.updateUser('user-id', {
  'first_name': 'Jane',
  'status': 'active',
});

// Mettre à jour plusieurs utilisateurs
await users.updateUsers(
  keys: ['id1', 'id2'],
  data: {'status': 'active'},
);

// Supprimer un utilisateur
await users.deleteUser('user-id');

// Supprimer plusieurs utilisateurs
await users.deleteUsers(['id1', 'id2', 'id3']);
```

### Utilisateur courant (/me)

```dart
// Récupérer l'utilisateur connecté
final me = await users.me();

// Mettre à jour le profil
await users.updateMe({
  'first_name': 'Updated',
  'language': 'fr-FR',
  'appearance': 'dark',
});

// Suivre la dernière page visitée
await users.updateLastPage('/admin/content/articles');
```

### Invitations

```dart
// Inviter un utilisateur
await users.inviteUsers(
  email: 'newuser@example.com',
  roleId: 'role-id',
);

// Inviter plusieurs utilisateurs
await users.inviteUsers(
  email: ['user1@example.com', 'user2@example.com'],
  roleId: 'role-id',
);

// Inviter avec URL personnalisée
await users.inviteUsers(
  email: 'vip@example.com',
  roleId: 'admin-role-id',
  inviteUrl: 'https://myapp.com/join',
);

// L'utilisateur invité accepte (côté utilisateur)
await users.acceptInvite(
  token: 'invitation-token-from-email',
  password: 'NewPassword123!',
);
```

### Enregistrement public

```dart
// Activer dans les paramètres Directus avant utilisation

// Enregistrer un nouvel utilisateur
await users.register(
  email: 'public@example.com',
  password: 'Password123!',
  firstName: 'Public',
  lastName: 'User',
);

// Vérifier l'email (côté utilisateur)
await users.verifyEmail('verification-token-from-email');
```

### Two-Factor Authentication (2FA)

```dart
// Générer un secret 2FA
final tfa = await users.generateTwoFactorSecret();
print('Secret: ${tfa['secret']}');
print('QR Code URL: ${tfa['otpauth_url']}');
// Afficher le QR code à l'utilisateur

// Activer la 2FA
await users.enableTwoFactor(
  secret: tfa['secret'],
  otp: '123456', // Code OTP de l'app d'authentification
);

// Désactiver la 2FA
await users.disableTwoFactor('654321'); // OTP actuel
```

## Exemples complets

Consultez le fichier `example/directus_user_example.dart` pour des exemples détaillés incluant :

- Toutes les opérations CRUD
- Gestion de l'utilisateur courant
- Invitations et enregistrement
- Configuration 2FA
- Classe personnalisée avec champs additionnels

## Notes importantes

1. **Champs requis** : Pour créer un utilisateur, `email` et `password` sont requis (sauf authentification externe)

2. **Statuts disponibles** :
   - `active` : Utilisateur actif
   - `invited` : Invité, en attente d'acceptation
   - `draft` : Brouillon
   - `suspended` : Suspendu
   - `deleted` : Supprimé (soft delete)

3. **Apparence** : Accepte uniquement `auto`, `light`, ou `dark`

4. **2FA** : Le secret 2FA doit être généré puis validé avec un code OTP avant activation

5. **Property Wrappers** : Utilisez `.set()` pour modifier et `.value` pour lire :
   ```dart
   user.email.set('new@example.com');  // Écriture
   String email = user.email.value;     // Lecture
   String? email = user.email.valueOrNull; // Lecture nullable
   ```

6. **Héritage** : Les champs `id`, `dateCreated`, `dateUpdated`, `userCreated`, `userUpdated` sont hérités de `DirectusModel`

## Ressources

- [Documentation Directus Users API](https://docs.directus.io/reference/system/users.html)
- [Property Wrappers Guide](property_wrappers.md)
- [Exemples DirectusModel](basic_usage.dart)

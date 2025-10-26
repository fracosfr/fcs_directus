# DirectusUser - Guide rapide

## Création

✅ **Modèle DirectusUser créé** avec toutes les propriétés Directus
✅ **UsersService complet** avec toutes les opérations de l'API
✅ **Property wrappers** pour une syntaxe simplifiée
✅ **Extensible** via héritage pour champs personnalisés
✅ **76/76 tests passent**

## Fichiers créés/modifiés

### Nouveaux fichiers
- `lib/src/models/directus_user.dart` - Modèle utilisateur complet
- `example/directus_user_example.dart` - Exemples d'utilisation complets (300+ lignes)
- `docs/directus_user.md` - Documentation détaillée

### Fichiers modifiés
- `lib/src/services/users_service.dart` - Service étendu avec toutes les opérations :
  - CRUD complet (single + batch)
  - Opérations /me (utilisateur courant)
  - Invitations (invite + accept)
  - Enregistrement public (register + verify)
  - 2FA (generate + enable + disable)
  - Tracking (last page)
- `lib/fcs_directus.dart` - Export de DirectusUser

## Utilisation rapide

```dart
import 'package:fcs_directus/fcs_directus.dart';

// 1. CRUD basique
final users = client.users;

// Lister
final allUsers = await users.getUsers();

// Lire un
final user = await users.getUser('user-id');

// Créer
final newUser = DirectusUser.empty()
  ..email.set('john@example.com')
  ..password.set('Pass123!')
  ..firstName.set('John')
  ..role.set('role-id');
await users.createUser(newUser.toJson());

// Mettre à jour
user.firstName.set('Jane');
user.activate();
await users.updateUser(user.id!, user.toJson());

// Supprimer
await users.deleteUser('user-id');

// 2. Utilisateur courant
final me = await users.me();
await users.updateMe({'first_name': 'Updated'});

// 3. Invitations
await users.inviteUsers(
  email: 'new@example.com',
  roleId: 'role-id',
);
await users.acceptInvite(token: 'token', password: 'pass');

// 4. Enregistrement public
await users.register(
  email: 'public@example.com',
  password: 'Pass123!',
);
await users.verifyEmail('verification-token');

// 5. 2FA
final tfa = await users.generateTwoFactorSecret();
await users.enableTwoFactor(secret: tfa['secret'], otp: '123456');
await users.disableTwoFactor('654321');
```

## Classe personnalisée

```dart
class CustomUser extends DirectusUser {
  // Vos champs
  late final department = stringValue('department');
  late final phoneNumber = stringValue('phone_number');
  late final isVerified = boolValue('is_verified');
  late final yearsOfExperience = intValue('years_of_experience');

  CustomUser(super.data);
  CustomUser.empty() : super.empty();

  // Vos méthodes
  void incrementExperience() => yearsOfExperience.increment();
  bool get canAccessAdmin => isActive && isVerified.value;
}

// Utilisation
final user = CustomUser.empty()
  ..email.set('dev@company.com')
  ..department.set('Engineering')
  ..isVerified.set(true);
```

## Propriétés principales

### Informations
- `firstName`, `lastName`, `email`
- `location`, `title`, `description`
- `avatar`, `tags`

### Configuration  
- `language` (ex: 'fr-FR')
- `appearance` ('auto', 'light', 'dark')
- `themeLight`, `themeDark`

### Sécurité
- `status` ('active', 'invited', 'suspended', etc.)
- `role`, `policies`, `token`
- `tfaSecret`, `provider`, `authData`

### Tracking
- `emailNotifications`
- `lastAccess`, `lastPage`

## Méthodes utiles

```dart
// Getters
user.fullName           // "John Doe"
user.isActive           // true
user.hasTwoFactorAuth   // true

// Actions
user.activate()                 // status = 'active'
user.suspend()                  // status = 'suspended'
user.setAppearance('dark')      // appearance = 'dark'
```

## API UsersService

### CRUD
- `getUsers()` - Liste avec query params
- `getUser(id)` - Un utilisateur
- `createUser(data)` - Créer un
- `createUsers([data])` - Créer plusieurs
- `updateUser(id, data)` - Mettre à jour un
- `updateUsers(keys, data)` - Mettre à jour plusieurs
- `deleteUser(id)` - Supprimer un
- `deleteUsers([ids])` - Supprimer plusieurs

### Utilisateur courant
- `me()` - Récupérer /me
- `updateMe(data)` - Mettre à jour /me
- `updateLastPage(page)` - Tracker page

### Invitations
- `inviteUsers(email, roleId, [inviteUrl])` - Inviter
- `acceptInvite(token, password)` - Accepter

### Enregistrement
- `register(email, password, ...)` - S'inscrire
- `verifyEmail(token)` - Vérifier email

### 2FA
- `generateTwoFactorSecret()` - Générer secret
- `enableTwoFactor(secret, otp)` - Activer
- `disableTwoFactor(otp)` - Désactiver

## Tests

```bash
flutter test  # 76/76 ✅
```

## Documentation

- [Documentation complète](docs/directus_user.md)
- [Exemples](example/directus_user_example.dart)
- [API Directus Users](https://docs.directus.io/reference/system/users.html)

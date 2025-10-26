# me() et updateMe() - Méthodes typées

Les méthodes `me()` et `updateMe()` du `UsersService` retournent maintenant des objets `DirectusUser` typés au lieu de `Map<String, dynamic>`.

## Avantages

✅ **Type-safe** : Accès typé aux propriétés avec auto-complétion  
✅ **Property Wrappers** : Syntaxe simplifiée avec `.set()` et `.value`  
✅ **Extensible** : Support des classes personnalisées héritées  
✅ **Factory System** : Injection de vos propres classes via factory  

## Utilisation basique

### Avec DirectusUser par défaut

```dart
// Récupérer l'utilisateur connecté
final me = await client.users.me();

// Accès typé aux propriétés
print(me.email.value);           // String
print(me.firstName.value);       // String
print(me.fullName);              // String? (getter)
print(me.isActive);              // bool (getter)
print(me.hasTwoFactorAuth);      // bool (getter)

// Modifier les propriétés
me.firstName.set('John');
me.lastName.set('Doe');
me.language.set('fr-FR');
me.appearance.set('dark');

// Sauvegarder
final updated = await client.users.updateMe(me.toJson());
print(updated.fullName);  // "John Doe"
```

## Avec classe personnalisée

### 1. Créer votre classe

```dart
class MyUser extends DirectusUser {
  // Vos champs personnalisés
  late final department = stringValue('department');
  late final phoneNumber = stringValue('phone_number');
  late final isVerified = boolValue('is_verified');
  late final accessLevel = intValue('access_level');

  MyUser(super.data);
  MyUser.empty() : super.empty();

  // Factory requise
  static MyUser factory(Map<String, dynamic> data) => MyUser(data);

  // Vos méthodes personnalisées
  bool get canAccessAdmin => isActive && isVerified.value && accessLevel.value >= 5;
  
  String get displayName => '${fullName ?? email.value} (${department.valueOrNull ?? "N/A"})';
}
```

### 2. Enregistrer la factory

```dart
// Une seule fois au démarrage de l'app
DirectusModel.registerFactory<MyUser>(MyUser.factory);
```

### 3. Utiliser avec le type personnalisé

```dart
// Récupérer avec le type personnalisé
final me = await client.users.me<MyUser>();

// Accès aux champs de DirectusUser
print(me.email.value);
print(me.fullName);
print(me.isActive);

// Accès aux champs personnalisés
print(me.department.value);      // "Engineering"
print(me.phoneNumber.value);     // "+33 6 12 34 56 78"
print(me.isVerified.value);      // true
print(me.accessLevel.value);     // 5

// Utiliser vos méthodes
print(me.canAccessAdmin);        // true
print(me.displayName);           // "John Doe (Engineering)"

// Modifier
me.department.set('Sales');
me.accessLevel.increment();

// Sauvegarder avec type personnalisé
final updated = await client.users.updateMe<MyUser>(me.toJson());
print(updated.department.value); // "Sales"
```

## Avec query parameters

```dart
// Récupérer seulement certains champs
final me = await client.users.me(
  query: QueryParameters(
    fields: ['id', 'email', 'first_name', 'last_name', 'role'],
  ),
);

// Avec classe personnalisée et query
final myMe = await client.users.me<MyUser>(
  query: QueryParameters(
    fields: ['*', 'department', 'phone_number'],
  ),
);
```

## Gestion des erreurs

```dart
try {
  // Oubli d'enregistrer la factory
  final me = await client.users.me<MyUser>();
} catch (e) {
  // StateError: No factory registered for type MyUser.
  // Please register a factory using DirectusModel.registerFactory<MyUser>(...)
}

// Solution : enregistrer la factory
DirectusModel.registerFactory<MyUser>(MyUser.factory);
final me = await client.users.me<MyUser>(); // ✅ Fonctionne
```

## Exemples pratiques

### Vérifier les permissions

```dart
final me = await client.users.me();

if (!me.isActive) {
  throw Exception('User account is not active');
}

if (!me.hasTwoFactorAuth) {
  // Proposer d'activer la 2FA
  showTwoFactorSetup();
}
```

### Changer l'apparence selon l'heure

```dart
final me = await client.users.me();
final hour = DateTime.now().hour;
final isDaytime = hour >= 6 && hour < 18;

me.setAppearance(isDaytime ? 'light' : 'dark');
await client.users.updateMe(me.toJson());
```

### Activer les notifications

```dart
final me = await client.users.me();

if (!me.emailNotifications.value) {
  me.emailNotifications.set(true);
  await client.users.updateMe(me.toJson());
  print('Email notifications enabled');
}
```

### Dashboard utilisateur

```dart
class UserDashboard extends StatelessWidget {
  Future<void> loadUser() async {
    final me = await client.users.me<MyUser>();
    
    setState(() {
      userName = me.fullName ?? me.email.value;
      userDepartment = me.department.value;
      userRole = me.role.value;
      canAdmin = me.canAccessAdmin;
      lastAccess = me.lastAccess ?? DateTime.now();
    });
  }
}
```

## Migration depuis Map<String, dynamic>

### Avant (Map)
```dart
final me = await client.users.me();
final email = me['email'] as String?;
final firstName = me['first_name'] as String?;
final isActive = me['status'] == 'active';

me['first_name'] = 'John';
await client.users.updateMe(me);
```

### Après (DirectusUser)
```dart
final me = await client.users.me();
final email = me.email.value;
final firstName = me.firstName.value;
final isActive = me.isActive;

me.firstName.set('John');
await client.users.updateMe(me.toJson());
```

## Comparaison des approches

| Fonctionnalité | Map | DirectusUser | MyUser extends DirectusUser |
|----------------|-----|--------------|------------------------------|
| Type-safe | ❌ | ✅ | ✅ |
| Auto-complétion | ❌ | ✅ | ✅ |
| Property wrappers | ❌ | ✅ | ✅ |
| Champs personnalisés | ⚠️ Manuel | ❌ | ✅ |
| Méthodes utilitaires | ❌ | ✅ | ✅ + Custom |
| Validation IDE | ❌ | ✅ | ✅ |

## Notes importantes

1. **Factory requise** : Pour utiliser un type personnalisé, vous DEVEZ enregistrer une factory avant le premier appel
   ```dart
   DirectusModel.registerFactory<MyUser>(MyUser.factory);
   ```

2. **Type par défaut** : Sans paramètre de type, `me()` retourne `DirectusUser`
   ```dart
   final me = await users.me();        // DirectusUser
   final myMe = await users.me<MyUser>(); // MyUser
   ```

3. **toJson() requis** : Pour sauvegarder, utilisez `.toJson()`
   ```dart
   await users.updateMe(me.toJson());
   ```

4. **Héritage** : Les champs `id`, `dateCreated`, `dateUpdated` sont hérités de `DirectusModel`
   ```dart
   print(me.id);           // String? (hérité)
   print(me.dateCreated);  // DateTime? (hérité)
   ```

5. **Property wrappers** : Utilisez `.value` pour lire, `.set()` pour écrire
   ```dart
   String email = me.email.value;     // Lecture
   me.email.set('new@example.com');   // Écriture
   ```

## Voir aussi

- [DirectusUser Documentation](directus_user.md)
- [Property Wrappers Guide](property_wrappers.md)
- [Exemple complet](../example/directus_user_me_example.dart)

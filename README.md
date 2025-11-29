# fcs_directus

[![Pub Version](https://img.shields.io/pub/v/fcs_directus)](https://pub.dev/packages/fcs_directus)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Directus](https://img.shields.io/badge/Directus-v11.1.0-blue)](https://directus.io)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue)](https://dart.dev)

Une librairie Dart/Flutter complète pour interagir avec l'API Directus. Fournit une interface type-safe, orientée objet avec support REST et WebSocket pour tous les endpoints Directus v11.1+.

## ✨ Fonctionnalités

- 🚀 **API complète** : Support de 31 services couvrant 96% des endpoints Directus
- 🔐 **Authentification** : Login/logout, refresh automatique, OAuth, 2FA
- 🔄 **Auto-refresh** : Gestion automatique de l'expiration des tokens avec callbacks
- 📦 **CRUD typé** : Opérations Create, Read, Update, Delete avec type-safety
- 🔍 **Filtres type-safe** : Builder intuitif sans manipuler JSON
- 🔗 **Relations** : Deep queries pour charger les relations imbriquées
- 📊 **Agrégations** : Count, sum, avg, min, max avec groupBy
- ⚡ **WebSocket** : Mises à jour temps réel sur toutes les collections
- 🎨 **Active Record Pattern** : Modèles avec stockage JSON interne
- 🛠️ **Property Wrappers** : API simplifiée pour l'accès aux propriétés
- 🎯 **Enums type-safe** : Conversion automatique String ↔ Enum
- 🖼️ **Asset Transforms** : Redimensionnement, focal points, formats
- 🧪 **Tests** : Tests unitaires inclus
- 📝 **Documentation** : Documentation complète générée avec dart doc

## 📦 Installation

Ajoutez la dépendance dans votre `pubspec.yaml` :

```yaml
dependencies:
  fcs_directus: ^2.0.0
```

Puis exécutez :

```bash
flutter pub get
```

## 🚀 Démarrage rapide

### Configuration de base

```dart
import 'package:fcs_directus/fcs_directus.dart';

// Configuration du client
final config = DirectusConfig(
  baseUrl: 'https://your-directus-instance.com',
  timeout: Duration(seconds: 30),
  enableLogging: true, // Pour le debug
);

// Création du client
final client = DirectusClient(config);
```

### Authentification

```dart
// Connexion avec email/password
final response = await client.auth.login(
  email: 'user@example.com',
  password: 'your-password',
);

print('Token: ${response.accessToken}');
print('Expire dans: ${response.expiresIn} secondes');

// Connexion avec token statique
await client.auth.loginWithToken('votre-token-statique');

// Connexion OAuth
final providers = await client.auth.listOAuthProviders();
final url = client.auth.getOAuthUrl('google', redirect: 'myapp://callback');

// Déconnexion
await client.auth.logout();

// Rafraîchir le token manuellement
await client.auth.refresh();

// Restaurer une session
await client.auth.restoreSession(savedRefreshToken);
```

### ⚡ Refresh automatique avec persistance

Le client gère automatiquement l'expiration des tokens et peut vous notifier pour persister les nouveaux tokens :

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    
    // ✅ Callback appelé lors d'un refresh réussi
    onTokenRefreshed: (accessToken, refreshToken) async {
      await storage.write(key: 'access_token', value: accessToken);
      if (refreshToken != null) {
        await storage.write(key: 'refresh_token', value: refreshToken);
      }
    },
    
    // ❌ Callback appelé lors d'une erreur d'authentification
    onAuthError: (exception) async {
      if (exception.errorCode == 'TOKEN_REFRESH_FAILED') {
        await storage.deleteAll();
        // Rediriger vers la page de login
      }
    },
  ),
);
```

### Opérations CRUD basiques

```dart
// === Créer ===
final newArticle = await client.items('articles').createOne({
  'title': 'Mon premier article',
  'content': 'Contenu de l\'article',
  'status': 'published',
});

// Créer plusieurs items
await client.items('articles').createMany([
  {'title': 'Article 1'},
  {'title': 'Article 2'},
]);

// === Lire ===
// Plusieurs items
final response = await client.items('articles').readMany();
print('${response.data.length} articles trouvés');

// Un item spécifique
final article = await client.items('articles').readOne('1');

// Singleton (ex: settings)
final settings = await client.items('settings').readSingleton();

// === Mettre à jour ===
await client.items('articles').updateOne('1', {'title': 'Nouveau titre'});

// Mettre à jour plusieurs items
await client.items('articles').updateMany(
  keys: ['1', '2', '3'],
  data: {'status': 'published'},
);

// === Supprimer ===
await client.items('articles').deleteOne('1');

// Supprimer plusieurs items
await client.items('articles').deleteMany(keys: ['1', '2', '3']);

// Supprimer avec filtre
await client.items('articles').deleteMany(
  filter: Filter.field('status').equals('archived'),
);
```

## 🎯 Modèles personnalisés

Créez vos propres classes pour représenter vos collections Directus :

### Approche 1 : Getters/Setters classiques

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  String get title => getString('title');
  set title(String value) => setString('title', value);
  
  String get content => getString('content');
  set content(String value) => setString('content', value);
  
  String get status => getString('status', defaultValue: 'draft');
  set status(String value) => setString('status', value);
  
  int get viewCount => getInt('view_count');
  set viewCount(int value) => setInt('view_count', value);
}
```

### Approche 2 : Property Wrappers (recommandée)

```dart
class Product extends DirectusModel {
  Product(super.data);
  
  @override
  String get itemName => 'products';
  
  late final name = stringValue('name');
  late final price = doubleValue('price');
  late final stock = intValue('stock');
  late final active = boolValue('active');
  late final createdAt = dateTimeValue('date_created');
  late final metadata = jsonValue('metadata');
  
  // Relation Many-to-One
  late final category = modelValue<Category>('category');
  
  // Relation Many-to-Many (table de jonction)
  late final tags = modelListValueM2M<Tag>('tags', 'tags_id');
}

// Utilisation
final product = Product({'name': 'Laptop', 'price': 999.99});
print(product.name.value);        // 'Laptop'
product.price.set(899.99);        // Modification
product.stock.increment();        // Helpers intégrés
product.active.toggle();          // Toggle boolean
```

### Enums type-safe

```dart
enum ArticleStatus { draft, review, published, archived }

class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  late final title = stringValue('title');
  
  // Conversion automatique String ↔ Enum
  late final status = enumValue<ArticleStatus>(
    'status',
    ArticleStatus.draft,    // Valeur par défaut
    ArticleStatus.values,   // Toutes les valeurs
  );
  
  // Helpers
  bool get isPublished => status.is_(ArticleStatus.published);
  bool get canEdit => status.isOneOf([ArticleStatus.draft, ArticleStatus.review]);
}

// Utilisation
final article = Article({'status': 'published'});
print(article.status.value);    // ArticleStatus.published (Enum)
print(article.status.asString); // "published"
article.status.set(ArticleStatus.draft);
```

### Dirty tracking (suivi des modifications)

```dart
final user = DirectusUser(await client.users.getUser('123'));

// Modifier des champs
user.firstName.set('Jean');
user.email.set('jean@example.com');

// Vérifier les modifications
print(user.isDirty);              // true
print(user.dirtyFields);          // {'first_name', 'email'}
print(user.isDirtyField('email')); // true

// Envoyer uniquement les modifications
await client.users.updateUser(user);  // Utilise toJsonDirty() automatiquement

// Réinitialiser le tracking
user.markClean();

// Ou annuler les modifications
user.revert();
```

### Registrer les factories

```dart
// Enregistrer les factories une seule fois au démarrage
DirectusModel.registerFactory<Article>(Article.new);
DirectusModel.registerFactory<Product>(Product.new);
DirectusModel.registerFactory<Category>(Category.new);

// Utiliser avec le service typé
final articles = await client.itemsOf<Article>().readMany();
for (final article in articles.data) {
  print(article.title.value);  // Type-safe !
}
```

## 🔍 Filtres type-safe

```dart
// Filtre simple
final query = QueryParameters(
  filter: Filter.field('status').equals('published'),
);

// Combinaison AND
final query = QueryParameters(
  filter: Filter.and([
    Filter.field('price').greaterThan(100),
    Filter.field('stock').greaterThan(0),
    Filter.field('category').equals('electronics'),
  ]),
);

// Combinaison OR
final query = QueryParameters(
  filter: Filter.or([
    Filter.field('featured').equals(true),
    Filter.field('price').lessThan(50),
  ]),
);

// Filtres imbriqués complexes
final query = QueryParameters(
  filter: Filter.and([
    Filter.field('status').equals('published'),
    Filter.or([
      Filter.field('category').inList(['electronics', 'computers']),
      Filter.field('featured').equals(true),
    ]),
    Filter.field('price').between(100, 1000),
  ]),
);

// Filtres sur relations (notation pointée)
final query = QueryParameters(
  filter: Filter.field('author.role.name').equals('admin'),
);
```

### Opérateurs disponibles

| Catégorie | Opérateurs |
|-----------|------------|
| **Comparaison** | `equals`, `notEquals`, `lessThan`, `lessThanOrEqual`, `greaterThan`, `greaterThanOrEqual` |
| **Collection** | `inList`, `notInList`, `between`, `notBetween` |
| **Chaînes** | `contains`, `notContains`, `startsWith`, `endsWith`, `containsInsensitive`, `startsWithInsensitive`, `endsWithInsensitive` |
| **NULL** | `isNull`, `isNotNull`, `isEmpty`, `isNotEmpty` |
| **Relations** | `Filter.some()`, `Filter.none()`, `Filter.relation()` |
| **Géo** | `intersects`, `notIntersects`, `intersectsBBox`, `notIntersectsBBox` |

## 🔗 Deep Queries (Relations)

```dart
// Charger une relation simple
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery().fields(['id', 'name', 'email']),
  }),
);

// Relations multiples avec filtres et tri
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery()
      .fields(['id', 'name', 'avatar'])
      .filter(Filter.field('status').equals('active')),
    'categories': DeepQuery()
      .fields(['id', 'name'])
      .limit(5)
      .sortDesc('name'),
    'comments': DeepQuery()
      .filter(Filter.field('approved').equals(true))
      .limit(10),
  }),
);

// Relations imbriquées (nested)
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery()
      .fields(['id', 'name'])
      .deep({
        'company': DeepQuery().fields(['name', 'website']),
      }),
  }),
);

// Utilisation
final articles = await client.items('articles').readMany(query: query);
```

## 📊 Agrégations et GroupBy

```dart
// Compter les items
final result = await client.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()..count(['*']),
  ),
);

// Statistiques multiples
final result = await client.items('orders').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count(['*'])
      ..countDistinct(['customer_id'])
      ..sum(['total', 'quantity'])
      ..avg(['rating'])
      ..min(['price'])
      ..max(['price']),
  ),
);

// Avec groupBy
final result = await client.items('sales').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..sum(['amount'])
      ..avg(['quantity']),
    groupBy: GroupBy.fields(['category', 'year']),
  ),
);
```

## 📄 Tri et Pagination

```dart
// Tri
final query = QueryParameters(
  sort: ['category', '-price'],  // Catégorie ASC, prix DESC
);

// Pagination offset
final query = QueryParameters(
  limit: 20,
  offset: 40,
);

// Pagination par page
final query = QueryParameters(
  limit: 20,
  page: 3,
);

// Sélection de champs
final query = QueryParameters(
  fields: ['id', 'title', 'status', 'author.name'],
);

// Recherche full-text
final query = QueryParameters(
  search: 'laptop gaming',
);
```

## ⚡ WebSocket (Temps réel)

```dart
// Créer le client WebSocket
final wsClient = DirectusWebSocketClient(config, accessToken: token);

// Connexion
await wsClient.connect();

// S'abonner à une collection
final uid = await wsClient.subscribe(
  collection: 'articles',
  onMessage: (message) {
    switch (message.event) {
      case DirectusItemEvent.create:
        print('Nouvel article: ${message.data}');
        break;
      case DirectusItemEvent.update:
        print('Article modifié: ${message.data}');
        break;
      case DirectusItemEvent.delete:
        print('Article supprimé');
        break;
    }
  },
);

// S'abonner avec événement spécifique
await wsClient.subscribeToCreate(
  collection: 'notifications',
  onMessage: (msg) => print('Nouvelle notification !'),
);

// Helpers pour collections système
await wsClient.subscribeToUsers(onMessage: handleUserChange);
await wsClient.subscribeToFiles(onMessage: handleFileChange);
await wsClient.subscribeToNotifications(onMessage: handleNotification);

// Se désabonner
await wsClient.unsubscribe(uid);

// Fermer
await wsClient.disconnect();
await wsClient.dispose();
```

## 📁 Gestion des fichiers

```dart
// Upload depuis un chemin local
final file = await client.files.uploadFile(
  filePath: '/path/to/image.jpg',
  title: 'Mon image',
  folder: 'folder-uuid',
);

// Upload depuis des bytes
final file = await client.files.uploadFileFromBytes(
  bytes: imageBytes,
  filename: 'photo.png',
  title: 'Ma photo',
);

// Import depuis une URL
final file = await client.files.importFile(
  url: 'https://example.com/image.jpg',
  title: 'Image importée',
);

// Récupérer les métadonnées
final files = await client.files.getFiles(
  query: QueryParameters(
    filter: Filter.field('type').contains('image'),
  ),
);
```

## 🖼️ Transformation d'assets

```dart
// URL avec transformations
final url = client.assets.getAssetUrl(
  'file-uuid',
  transforms: [
    AssetTransform(
      width: 800,
      height: 600,
      fit: AssetFit.cover,
      quality: 80,
      format: AssetFormat.webp,
    ),
  ],
);

// Helpers prédéfinis
final avatarUrl = client.assets.getAvatarUrl('file-id', size: 200);
final bannerUrl = client.assets.getBannerUrl('file-id', width: 1920);
final cardUrl = client.assets.getCardUrl('file-id', width: 400);
final mobileUrl = client.assets.getMobileUrl('file-id', maxWidth: 800);
final placeholderUrl = client.assets.getPlaceholderUrl('file-id'); // LQIP

// Focal point
final url = client.assets.getAssetWithFocalPoint(
  'file-id',
  width: 800,
  height: 600,
  focalPoint: FocalPoint(0.3, 0.7),  // 30% depuis la gauche, 70% depuis le haut
);

// Srcset pour images responsive
final srcSet = client.assets.getSrcSet(
  'file-id',
  widths: [320, 640, 1024, 1920],
  quality: 80,
  format: AssetFormat.webp,
);
// Retourne: {320: 'url1', 640: 'url2', ...}

// Avec preset Directus
final url = client.assets.getAssetUrl('file-id', key: 'thumbnail');

// URL de téléchargement
final downloadUrl = client.assets.getDownloadUrl('file-id');
```

## 👥 Gestion des utilisateurs

```dart
// CRUD utilisateurs
final users = await client.users.getUsers();
final user = await client.users.getUser('user-id');

final newUser = await client.users.createUser(DirectusUser.empty()
  ..email.set('user@example.com')
  ..password.set('secure123')
  ..firstName.set('John')
  ..role.setById('role-id'));

await client.users.updateUser(user);
await client.users.deleteUser(user);

// Utilisateur courant
final me = await client.users.me<DirectusUser>();
await client.users.updateMe({'first_name': 'Jean'});

// Invitations
await client.users.inviteUsers(
  email: ['user1@example.com', 'user2@example.com'],
  roleId: 'role-id',
);
await client.users.acceptInvite(token: 'invite-token', password: 'password');

// Inscription publique
await client.users.register(
  email: 'new@example.com',
  password: 'password',
  firstName: 'John',
);
await client.users.verifyEmail('verification-token');

// Two-Factor Authentication
final tfa = await client.users.generateTwoFactorSecret('password');
await client.users.enableTwoFactor(secret: tfa!.secret, otp: '123456');
await client.users.disableTwoFactor('123456');

// Gestion des policies
await client.users.addPoliciesToUser(
  userId: 'user-id',
  policyIds: ['policy-1', 'policy-2'],
);
```

## 🛡️ Services disponibles

| Service | Description |
|---------|-------------|
| `auth` | Authentification (login, logout, refresh, OAuth, 2FA) |
| `items(collection)` | CRUD générique sur n'importe quelle collection |
| `itemsOf<T>()` | CRUD typé avec modèles personnalisés |
| `users` | Gestion des utilisateurs, invitations, 2FA |
| `roles` | Gestion des rôles |
| `policies` | Gestion des politiques d'accès |
| `permissions` | Gestion des permissions |
| `files` | Upload et gestion des fichiers |
| `assets` | Transformation d'images |
| `folders` | Organisation des fichiers |
| `collections` | Gestion du schéma des collections |
| `fields` | Gestion des champs |
| `relations` | Gestion des relations |
| `activity` | Logs d'activité (lecture seule) |
| `revisions` | Historique des modifications |
| `comments` | Commentaires sur les items |
| `notifications` | Notifications utilisateurs |
| `presets` | Préférences utilisateurs |
| `dashboards` | Tableaux de bord Insights |
| `panels` | Panneaux de tableaux de bord |
| `flows` | Automatisation et workflows |
| `operations` | Opérations des flows |
| `shares` | Partage d'items |
| `versions` | Versioning de contenu |
| `translations` | Traductions personnalisées |
| `extensions` | Extensions installées |
| `schema` | Snapshot/Apply du schéma |
| `settings` | Paramètres globaux |
| `server` | Info serveur (ping, health, specs) |
| `utilities` | Hash, random, cache, sort, import/export |
| `metrics` | Métriques Prometheus |
| `websocket` | Mises à jour temps réel |

## 🚨 Gestion des erreurs

```dart
try {
  await client.items('articles').readOne('999');
} on DirectusNotFoundException catch (e) {
  print('Non trouvé: ${e.message}');
} on DirectusAuthException catch (e) {
  if (e.isOtpRequired) {
    print('Code 2FA requis');
  } else if (e.isInvalidCredentials) {
    print('Identifiants incorrects');
  } else if (e.isInvalidToken) {
    print('Token expiré');
  } else if (e.isUserSuspended) {
    print('Compte suspendu');
  }
} on DirectusValidationException catch (e) {
  print('Validation: ${e.message}');
  if (e.fieldErrors != null) {
    e.fieldErrors!.forEach((field, errors) {
      print('  $field: ${errors.join(", ")}');
    });
  }
} on DirectusPermissionException catch (e) {
  print('Permission refusée: ${e.message}');
} on DirectusRateLimitException catch (e) {
  print('Rate limit atteint');
} on DirectusNetworkException catch (e) {
  print('Erreur réseau: ${e.message}');
} on DirectusServerException catch (e) {
  print('Erreur serveur: ${e.message}');
} on DirectusException catch (e) {
  print('Erreur: ${e.message} (${e.errorCode})');
}
```

### Codes d'erreur Directus

Tous les codes d'erreur officiels sont disponibles via l'enum `DirectusErrorCode` :
- `invalidCredentials`, `invalidToken`, `tokenExpired`, `invalidOtp`, `userSuspended`
- `invalidPayload`, `invalidQuery`, `unprocessableContent`
- `forbidden`, `routeNotFound`
- `requestsExceeded`, `limitExceeded`
- Et plus encore...

## 🧹 Nettoyage des ressources

```dart
// À la fin de l'utilisation
client.dispose();  // Ferme le client HTTP

// Pour WebSocket
await wsClient.disconnect();
await wsClient.dispose();

// Effacer les tokens manuellement
client.clearTokens();
```

## 📚 Documentation

- **API complète** : Générée avec `dart doc` dans `/doc/api/`
- **Documentation** : Fichiers `.md` dans `/docs/`

```bash
# Générer la documentation
dart doc

# Ouvrir
open doc/api/index.html
```

## 🧪 Tests

```bash
flutter test
```

## 🤝 Contribution

Les contributions sont les bienvenues ! Voir [CONTRIBUTING.md](CONTRIBUTING.md).

## 📄 Licence

Ce projet est sous licence MIT. Voir [LICENSE](LICENSE).

## 🔗 Liens

- [Documentation Directus](https://directus.io/docs)
- [API Reference Directus](https://directus.io/docs/api)
- [GitHub](https://github.com/fracosfr/fcs_directus)
- [Pub.dev](https://pub.dev/packages/fcs_directus)

---

Développé avec ❤️ pour la communauté Flutter & Directus

# fcs_directus

[![Pub Version](https://img.shields.io/pub/v/fcs_directus)](https://pub.dev/packages/fcs_directus)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Une librairie Dart/Flutter complète pour interagir avec l'API Directus. Fournit une interface type-safe, orientée objet avec support REST et WebSocket pour tous les endpoints Directus.

## ✨ Fonctionnalités

- 🚀 **API complète** : Support de tous les endpoints Directus (30+ services)
- 🔐 **Authentification** : Login/logout, refresh tokens, OAuth
- 📦 **CRUD typé** : Opérations Create, Read, Update, Delete avec type-safety
- 🔍 **Filtres type-safe** : Builder intuitif sans manipuler JSON
- 🔗 **Relations** : Deep queries pour charger les relations imbriquées
- 📊 **Agrégations** : Count, sum, avg, min, max avec groupBy
- ⚡ **WebSocket** : Mises à jour temps réel sur toutes les collections
- 🎨 **Active Record Pattern** : Modèles avec stockage JSON interne
- 🛠️ **Property Wrappers** : API simplifiée pour l'accès aux propriétés
- 🧪 **Tests** : Tests unitaires inclus
- 📝 **Documentation** : Documentation complète générée avec dart doc

## 📦 Installation

Ajoutez la dépendance dans votre `pubspec.yaml` :

```yaml
dependencies:
  fcs_directus: ^1.0.0
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
// Connexion
try {
  final response = await client.auth.login(
    email: 'user@example.com',
    password: 'your-password',
  );
  
  print('Token: ${response.accessToken}');
  print('Expire dans: ${response.expiresIn} secondes');
} on DirectusException catch (e) {
  print('Erreur: ${e.message}');
}

// Déconnexion
await client.auth.logout();

// Rafraîchir le token
await client.auth.refresh();
```

### Opérations CRUD basiques

```dart
// Créer un item
final newArticle = await client.items('articles').createOne({
  'title': 'Mon premier article',
  'content': 'Contenu de l\'article',
  'status': 'published',
});

// Lire plusieurs items
final articles = await client.items('articles').readMany();
print('${articles.data.length} articles trouvés');

// Lire un item spécifique
final article = await client.items('articles').readOne('1');

// Mettre à jour un item
await client.items('articles').updateOne('1', {
  'title': 'Titre modifié',
});

// Supprimer un item
await client.items('articles').deleteOne('1');
```

## 🎯 Utilisation avancée

### Modèles personnalisés

Créez vos propres classes pour représenter vos collections Directus :

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  // Approche 1 : Getters/Setters classiques
  String get title => getString('title');
  set title(String value) => setString('title', value);
  
  String get content => getString('content');
  set content(String value) => setString('content', value);
  
  String get status => getString('status', defaultValue: 'draft');
  set status(String value) => setString('status', value);
  
  int get viewCount => getInt('view_count');
  set viewCount(int value) => setInt('view_count', value);
  
  bool get featured => getBool('featured');
  set featured(bool value) => setBool('featured', value);
}

// Approche 2 : Property Wrappers (API simplifiée)
class Product extends DirectusModel {
  Product(super.data);
  
  @override
  String get itemName => 'products';
  
  late final name = stringValue('name');
  late final price = doubleValue('price');
  late final stock = intValue('stock');
  late final active = boolValue('active');
}

// Utilisation
final product = Product({'name': 'Laptop', 'price': 999.99});
print(product.name); // 'Laptop'
product.price.set(899.99); // Modification
```

### Registrer les factories de modèles

Pour utiliser des modèles typés avec les services :

```dart
// Enregistrer la factory
DirectusModel.registerFactory<Article>((data) => Article(data));
DirectusModel.registerFactory<Product>((data) => Product(data));

// Utiliser avec le service items
final articles = await client.itemsOf<Article>().readMany();
for (final article in articles.data) {
  print(article.title); // Type-safe !
}
```

### Filtres type-safe

Construisez des requêtes complexes sans manipuler JSON :

```dart
// Filtre simple
final query = QueryParameters(
  filter: Filter.field('status').equals('published'),
);

// Filtres combinés avec AND
final query = QueryParameters(
  filter: Filter.and([
    Filter.field('price').greaterThan(100),
    Filter.field('stock').greaterThan(0),
    Filter.field('category').equals('electronics'),
  ]),
);

// Filtres avec OR
final query = QueryParameters(
  filter: Filter.or([
    Filter.field('featured').equals(true),
    Filter.field('price').lessThan(50),
  ]),
);

// Opérateurs de chaîne
final query = QueryParameters(
  filter: Filter.field('title').contains('laptop'),
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

// Utilisation
final products = await client.items('products').readMany(query: query);
```

#### Opérateurs disponibles

**Comparaison :**
- `equals(value)` - Égal à
- `notEquals(value)` - Différent de
- `lessThan(value)` - Inférieur à
- `lessThanOrEqual(value)` - Inférieur ou égal à
- `greaterThan(value)` - Supérieur à
- `greaterThanOrEqual(value)` - Supérieur ou égal à

**Collection :**
- `inList(values)` - Dans la liste
- `notInList(values)` - Pas dans la liste
- `between(min, max)` - Entre deux valeurs
- `notBetween(min, max)` - Pas entre deux valeurs

**Chaînes :**
- `contains(text)` - Contient
- `notContains(text)` - Ne contient pas
- `startsWith(text)` - Commence par
- `endsWith(text)` - Se termine par
- `containsInsensitive(text)` - Contient (insensible à la casse)

**NULL :**
- `isNull()` - Est NULL
- `isNotNull()` - N'est pas NULL

**Booléens :**
- `isTrue()` - Est vrai
- `isFalse()` - Est faux

### Deep queries (Relations)

Chargez les relations imbriquées de manière élégante :

```dart
// Charger une relation simple
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery().fields(['id', 'name', 'email']),
  }),
);

// Relations multiples avec filtres
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery()
      .fields(['id', 'name', 'avatar'])
      .filter(Filter.field('status').equals('active')),
    'categories': DeepQuery()
      .fields(['id', 'name'])
      .limit(5)
      .sort('-name'),
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

### Agrégations et groupBy

Effectuez des calculs statistiques sur vos données :

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

### Tri et pagination

```dart
// Tri simple
final query = QueryParameters(
  sort: ['name'], // Ordre croissant
);

// Tri décroissant
final query = QueryParameters(
  sort: ['-created_at'], // Ordre décroissant
);

// Tri multiple
final query = QueryParameters(
  sort: ['category', '-price'], // Par catégorie puis prix décroissant
);

// Pagination avec limit/offset
final query = QueryParameters(
  limit: 20,
  offset: 40,
);

// Pagination avec page
final query = QueryParameters(
  limit: 20,
  page: 3, // Page 3 (items 41-60)
);

// Sélection de champs
final query = QueryParameters(
  fields: ['id', 'title', 'status', 'author.name'],
);
```

### Recherche full-text

```dart
final query = QueryParameters(
  search: 'laptop',
);

final products = await client.items('products').readMany(query: query);
```

## 🔄 WebSocket (Temps réel)

Recevez des mises à jour en temps réel depuis Directus :

```dart
// Configuration avec authentification
final wsConfig = DirectusConfig(
  baseUrl: 'https://your-directus-instance.com',
);

final wsClient = DirectusWebSocketClient(wsConfig);

// Connexion
await wsClient.connect(accessToken: 'your-access-token');

// S'abonner à une collection
final subscription = wsClient.subscribe(
  collection: 'articles',
  onEvent: (event, data) {
    switch (event) {
      case DirectusItemEvent.create:
        print('Nouvel article créé: ${data['id']}');
        break;
      case DirectusItemEvent.update:
        print('Article modifié: ${data['id']}');
        break;
      case DirectusItemEvent.delete:
        print('Article supprimé');
        break;
    }
  },
);

// S'abonner avec filtre
final subscription = wsClient.subscribe(
  collection: 'products',
  query: {
    'filter': {
      'status': {'_eq': 'published'},
    },
  },
  onEvent: (event, data) {
    print('Événement sur produit publié: $event');
  },
);

// Se désabonner
await wsClient.unsubscribe(subscription.uid);

// Collections système supportées
wsClient.subscribe(collection: 'directus_users', ...);
wsClient.subscribe(collection: 'directus_files', ...);
wsClient.subscribe(collection: 'directus_notifications', ...);

// Fermer la connexion
await wsClient.disconnect();
```

## 📁 Gestion des fichiers

### Upload de fichiers

```dart
// Upload depuis un chemin local
final file = await client.files.uploadFile(
  filePath: '/path/to/image.jpg',
  title: 'Mon image',
  folder: 'folder-uuid', // Optionnel
);

print('Fichier uploadé: ${file['id']}');

// Upload depuis des bytes
final bytes = await File('/path/to/file.pdf').readAsBytes();
final file = await client.files.uploadFileFromBytes(
  bytes: bytes,
  filename: 'document.pdf',
  title: 'Mon document',
);

// Import depuis une URL
final file = await client.files.importFile(
  url: 'https://example.com/image.jpg',
  title: 'Image importée',
);

// Lister les fichiers
final files = await client.files.getFiles(
  query: QueryParameters(
    filter: Filter.field('type').contains('image'),
    limit: 20,
  ),
);
```

### Transformation d'assets

```dart
// Construire une URL d'asset avec transformations
final transform = AssetTransform(
  width: 800,
  height: 600,
  fit: AssetFit.cover,
  quality: 80,
  format: AssetFormat.webp,
);

final url = client.assets.buildAssetUrl(
  fileId: 'file-uuid',
  transform: transform,
);

// Avec un preset
final url = client.assets.buildAssetUrl(
  fileId: 'file-uuid',
  preset: 'thumbnail',
);
```

## 👥 Gestion des utilisateurs

```dart
// Créer un utilisateur
final user = await client.users.createUser({
  'email': 'newuser@example.com',
  'password': 'secure-password',
  'first_name': 'John',
  'last_name': 'Doe',
  'role': 'role-uuid',
});

// Lister les utilisateurs
final users = await client.users.getUsers(
  query: QueryParameters(
    filter: Filter.field('status').equals('active'),
  ),
);

// Mettre à jour un utilisateur
await client.users.updateUser('user-uuid', {
  'first_name': 'Jane',
});

// Obtenir l'utilisateur courant
final me = await client.users.me();
print('Connecté en tant que: ${me['email']}');

// Inviter un utilisateur
await client.users.inviteUser({
  'email': 'invite@example.com',
  'role': 'role-uuid',
});
```

## 🔐 Permissions et Rôles

```dart
// Créer un rôle
final role = await client.roles.createRole({
  'name': 'Editor',
  'description': 'Can edit content',
});

// Lister les rôles
final roles = await client.roles.getRoles();

// Créer une permission
final permission = await client.permissions.createPermission({
  'role': 'role-uuid',
  'collection': 'articles',
  'action': 'read',
  'fields': ['*'],
});

// Lister les permissions
final permissions = await client.permissions.getPermissions(
  query: QueryParameters(
    filter: Filter.field('role').equals('role-uuid'),
  ),
);
```

## 📊 Autres services

### Collections

```dart
// Lister les collections
final collections = await client.collections.getCollections();

// Obtenir une collection spécifique
final collection = await client.collections.getCollection('articles');
```

### Fields

```dart
// Lister les champs d'une collection
final fields = await client.fields.getFields('articles');

// Créer un champ
final field = await client.fields.createField('articles', {
  'field': 'subtitle',
  'type': 'string',
  'meta': {
    'interface': 'input',
    'width': 'full',
  },
});
```

### Activity (Logs)

```dart
// Obtenir les logs d'activité
final activities = await client.activity.getActivity(
  query: QueryParameters(
    filter: Filter.field('action').equals('create'),
    limit: 50,
    sort: ['-timestamp'],
  ),
);
```

### Server Info

```dart
// Informations du serveur
final info = await client.server.ping();
print('Version Directus: ${info['version']}');

// Santé du serveur
final health = await client.server.health();
```

## 🛠️ Utilitaires

### Cache

```dart
// Le client inclut un système de cache
final cacheUtil = CacheUtility();

// Mettre en cache
await cacheUtil.set('key', {'data': 'value'}, duration: Duration(minutes: 5));

// Récupérer du cache
final data = await cacheUtil.get('key');

// Vider le cache
await cacheUtil.clear();
```

### Gestion des erreurs

```dart
try {
  final article = await client.items('articles').readOne('999');
} on DirectusNotFoundException catch (e) {
  print('Article non trouvé: ${e.message}');
} on DirectusAuthException catch (e) {
  print('Erreur d\'authentification: ${e.message}');
} on DirectusValidationException catch (e) {
  print('Validation échouée');
  if (e.fieldErrors != null) {
    print('Erreurs par champ: ${e.fieldErrors}');
  }
} on DirectusException catch (e) {
  print('Erreur Directus: ${e.message}');
  print('Code: ${e.errorCode}');
  print('Status: ${e.statusCode}');
}
```

### Dispose

N'oubliez pas de libérer les ressources :

```dart
// À la fin de l'utilisation
client.dispose();

// Pour WebSocket
wsClient.disconnect();
```

## 📚 Documentation API complète

La documentation complète de l'API est générée avec `dart doc` et disponible dans le dossier `/doc/api/`.

Pour la générer localement :

```bash
dart doc
```

Puis ouvrez `doc/api/index.html` dans votre navigateur.

## 🧪 Tests

Pour exécuter les tests :

```bash
flutter test
```

## 📝 Exemples complets

Des exemples complets sont disponibles dans le dossier `/example` :

- `example_basic.dart` - CRUD basique
- `example_filters.dart` - Filtres avancés
- `example_relations.dart` - Deep queries
- `example_custom_model.dart` - Modèles personnalisés

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🔗 Liens utiles

- [Documentation Directus](https://docs.directus.io/)
- [API Reference Directus](https://docs.directus.io/reference/api/)
- [Pub.dev](https://pub.dev/packages/fcs_directus)
- [GitHub](https://github.com/fracosfr/fcs_directus)

## 💬 Support

Pour toute question ou problème :

- Ouvrir une [issue](https://github.com/fracosfr/fcs_directus/issues)
- Consulter la [documentation Directus](https://docs.directus.io/)

---

Développé avec ❤️ pour la communauté Flutter & Directus

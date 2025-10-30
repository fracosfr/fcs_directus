<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# fcs_directus

Une librairie Dart/Flutter complète pour interagir avec l'API Directus via REST et WebSocket.

[![Pub Version](https://img.shields.io/pub/v/fcs_directus.svg)](https://pub.dev/packages/fcs_directus)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 🚀 Fonctionnalités

- ✅ **API REST complète** - Support de toutes les opérations CRUD
- ✅ **Authentification** - Login, logout, refresh token, static tokens
- ✅ **WebSocket** - Mises à jour en temps réel
- ✅ **Gestion des fichiers** - Upload, download, transformations
- ✅ **Collections personnalisées** - Support pour toutes vos collections Directus
- ✅ **Modèles typés** - Créez vos propres modèles Dart avec builders
- ✅ **Filtres type-safe** - API intuitive avec opérateurs chainables
- ✅ **Relations imbriquées (Deep)** - Chargement de relations M2O, O2M, M2M
- ✅ **Agrégations** - 9 opérations statistiques (count, sum, avg, min, max...)
- ✅ **Fonctions date/temps** - 9 fonctions pour analyse temporelle
- ✅ **Variables dynamiques** - $NOW, $CURRENT_USER, $CURRENT_ROLE...
- ✅ **Gestion d'erreurs complète** - 31 codes d'erreur Directus avec types spécifiques
- ✅ **Documentation complète** - Dartdoc pour toutes les API publiques
- ✅ **Tests unitaires** - 76 tests, code testé et fiable

## 📦 Installation

Ajoutez `fcs_directus` à votre `pubspec.yaml`:

```yaml
dependencies:
  fcs_directus: ^0.0.1
```

Puis exécutez:

```bash
flutter pub get
```

## 🎯 Utilisation rapide

### Configuration et connexion

```dart
import 'package:fcs_directus/fcs_directus.dart';

// Configuration
final config = DirectusConfig(
  baseUrl: 'https://your-directus-instance.com',
  enableLogging: true, // Optionnel: active les logs
);

// Création du client
final client = DirectusClient(config);

// Authentification
await client.auth.login(
  email: 'user@example.com',
  password: 'password',
);
```

### Opérations CRUD

```dart
// Service pour une collection
final articles = client.items('articles');

// Créer
final newArticle = await articles.createOne({
  'title': 'Mon article',
  'content': 'Contenu...',
  'status': 'published',
});

// Lire avec filtres type-safe ✨
final allArticles = await articles.readMany(
  query: QueryParameters(
    limit: 10,
    sort: ['-date_created'],
    // Nouveau: API de filtres intuitive
    filter: Filter.field('status').equals('published'),
  ),
);

final oneArticle = await articles.readOne('article-id');

// Mettre à jour
await articles.updateOne('article-id', {
  'title': 'Titre modifié',
});

// Supprimer
await articles.deleteOne('article-id');
```

### Filtres type-safe ✨

Le système de filtres type-safe permet de construire des requêtes complexes sans connaître les opérateurs Directus :

```dart
// Filtre simple
filter: Filter.field('status').equals('active')

// Filtres combinés
filter: Filter.and([
  Filter.field('status').equals('published'),
  Filter.field('price').greaterThan(100),
  Filter.field('stock').greaterThan(0),
])

// Filtres imbriqués
filter: Filter.or([
  Filter.and([
    Filter.field('category').equals('electronics'),
    Filter.field('price').lessThan(500),
  ]),
  Filter.field('featured').equals(true),
])

// Opérateurs de chaîne
filter: Filter.field('title').contains('laptop')
filter: Filter.field('name').startsWith('Apple')

// Listes
filter: Filter.field('category').inList(['electronics', 'computers'])

// Relations
filter: Filter.relation('category').where(
  Filter.field('name').equals('Premium'),
)
```

Voir le [Guide des Filtres](docs/FILTERS_GUIDE.md) pour plus de détails.

### Relations imbriquées avec Deep ✨

Le système Deep permet de charger des relations imbriquées de manière type-safe et intuitive :

```dart
// Deep simple avec sélection de champs
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery().fields(['id', 'name', 'email']),
  }),
);

// Deep avec limite et tri
final query = QueryParameters(
  deep: Deep({
    'comments': DeepQuery()
        .limit(5)
        .sortDesc('created_at')
        .fields(['id', 'content', 'created_at']),
  }),
);

// Deep avec filtres
final query = QueryParameters(
  deep: Deep({
    'categories': DeepQuery()
        .filter(Filter.field('status').equals('published'))
        .sortAsc('name'),
  }),
);

// Deep imbriqué (relations dans des relations)
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery()
        .fields(['id', 'name', 'avatar'])
        .deep({
          'avatar': DeepQuery().fields(['id', 'filename_disk']),
        }),
  }),
);

// Deep multiple (plusieurs relations)
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery().fields(['name', 'email']),
    'categories': DeepQuery().limit(10).sortAsc('name'),
    'featured_image': DeepQuery().fields(['id', 'filename_disk']),
  }),
);

// Combinaison Filter + Deep
final query = QueryParameters(
  filter: Filter.field('status').equals('published'),
  deep: Deep({
    'author': DeepQuery()
        .fields(['id', 'name', 'avatar'])
        .deep({
          'avatar': DeepQuery().fields(['id', 'filename_disk']),
        }),
    'comments': DeepQuery()
        .filter(Filter.field('status').equals('approved'))
        .sortDesc('created_at')
        .limit(10),
  }),
  limit: 20,
);

final articles = await client.items('articles').readMany(query);
```

**Méthodes d'extension utilitaires:**
```dart
DeepQuery()
  .allFields()              // Tous les champs (*)
  .sortAsc('name')          // Tri ascendant
  .sortDesc('created_at')   // Tri descendant
  .first(3)                 // 3 premiers items
```

Voir le [Guide Deep](docs/DEEP_GUIDE.md) pour plus d'exemples et de détails.

### Agrégations et statistiques ✨

Effectuez des calculs statistiques puissants avec l'API type-safe d'agrégations.

```dart
// Statistiques simples
final stats = await client.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..countAll()
      ..sum(['price'])
      ..avg(['rating'])
      ..min(['price'])
      ..max(['price']),
  ),
);

// Agrégation avec regroupement
final salesByCategory = await client.items('orders').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count(['*'])
      ..sum(['amount']),
    groupBy: GroupBy.fields(['category']),
    sort: ['-sum.amount'],
  ),
);

// Analyse temporelle avec fonctions de date
final monthlySales = await client.items('orders').readMany(
  query: QueryParameters(
    filter: Filter.field(Func.year('created_at')).equals(2024),
    aggregate: Aggregate()
      ..count(['*'])
      ..sum(['amount']),
    groupBy: GroupBy.fields([
      Func.month('created_at'),
    ]),
  ),
);

// Variables dynamiques
final myTasks = await client.items('tasks').readMany(
  query: QueryParameters(
    filter: Filter.and([
      Filter.field('assigned_to').equals(DynamicVar.currentUser),
      Filter.field('due_date').greaterThan(DynamicVar.now),
    ]),
  ),
);
```

**Agrégations disponibles:**
- `count(['*'])` - Compter les items
- `countDistinct(['field'])` - Valeurs uniques
- `sum(['field'])` - Somme
- `avg(['field'])` - Moyenne
- `min(['field'])` - Minimum
- `max(['field'])` - Maximum

**Fonctions de date:**
- `Func.year('field')` - Extraire l'année
- `Func.month('field')` - Extraire le mois (1-12)
- `Func.day('field')` - Extraire le jour (1-31)
- `Func.hour('field')` - Extraire l'heure (0-23)
- `Func.weekday('field')` - Jour de la semaine (0-6)

**Variables dynamiques:**
- `DynamicVar.now` - Timestamp actuel
- `DynamicVar.currentUser` - ID utilisateur connecté
- `DynamicVar.currentRole` - Rôle de l'utilisateur

Voir le [Guide des Agrégations](docs/AGGREGATIONS_GUIDE.md) pour tous les détails.

### Modèles personnalisés

Créez vos modèles en héritant de `DirectusModel`. La librairie fournit des builders puissants pour simplifier la sérialisation.

#### Approche 1 : Avec les Builders (Recommandé) ✨

```dart
class Article extends DirectusModel {
  final String title;
  final String? content;
  final int viewCount;

  Article._({
    super.id,
    required this.title,
    this.content,
    required this.viewCount,
    super.dateCreated,
    super.dateUpdated,
  });

  // Constructeur public
  factory Article({
    String? id,
    required String title,
    String? content,
    int viewCount = 0,
    DateTime? dateCreated,
    DateTime? dateUpdated,
  }) => Article._(
    id: id,
    title: title,
    content: content,
    viewCount: viewCount,
    dateCreated: dateCreated,
    dateUpdated: dateUpdated,
  );

  // fromJson simplifié avec DirectusModelBuilder
  factory Article.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    return Article._(
      id: builder.id,
      title: builder.getString('title'),
      content: builder.getStringOrNull('content'),
      viewCount: builder.getInt('view_count', defaultValue: 0),
      dateCreated: builder.dateCreated,
      dateUpdated: builder.dateUpdated,
    );
  }

  // toMap simplifié avec DirectusMapBuilder
  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('title', title)
        .addIfNotNull('content', content)
        .add('view_count', viewCount)
        .build();
  }
}

// Utilisation
final article = Article(
  title: 'Mon article',
  content: 'Contenu...',
  viewCount: 42,
);

final saved = await client.items('articles').createOne(
  article.toJson(),
  fromJson: Article.fromJson,
) as Article;
```

**Avantages des Builders:**
- ✅ **DirectusModelBuilder** : Getters type-safe (getString, getInt, getBool, etc.)
- ✅ Gestion automatique des conversions de types
- ✅ Valeurs par défaut intégrées
- ✅ **DirectusMapBuilder** : Construction fluide des Map
- ✅ Méthodes conditionnelles (addIfNotNull, addIf)
- ✅ Gestion automatique des relations (addRelation)
- ✅ Code plus lisible et maintenable

#### Approche 2 : Manuelle (Simple)

```dart
class Article extends DirectusModel {
  final String title;
  final String? content;

  Article({
    super.id,
    required this.title,
    this.content,
    super.dateCreated,
    super.dateUpdated,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: DirectusModel.parseId(json['id']),
      title: json['title'] as String,
      content: json['content'] as String?,
      dateCreated: DirectusModel.parseDate(json['date_created']),
      dateUpdated: DirectusModel.parseDate(json['date_updated']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      if (content != null) 'content': content,
    };
  }
}
```

#### Builders API Reference

**DirectusModelBuilder - Lecture type-safe:**
```dart
final builder = DirectusModelBuilder(json);

// Champs standards Directus (toujours disponibles)
builder.id                    // String?
builder.dateCreated          // DateTime?
builder.dateUpdated          // DateTime?
builder.userCreated          // String?
builder.userUpdated          // String?

// Getters typés avec gestion d'erreurs
builder.getString('field')                    // String (lance si null/absent)
builder.getStringOrNull('field')             // String?
builder.getInt('count', defaultValue: 0)     // int avec valeur par défaut
builder.getDouble('price')                   // double
builder.getBool('active', defaultValue: true) // bool (accepte "true", 1, true)
builder.getDateTime('published_at')          // DateTime?
builder.getList<String>('tags')              // List<String> (vide si null)
builder.getObject('nested')                  // Map<String, dynamic>?
```

**DirectusMapBuilder - Construction fluide:**
```dart
final map = DirectusMapBuilder()
    .add('title', title)                           // Toujours ajouter
    .addIfNotNull('content', content)             // Si non-null
    .addIf(isPublished, 'published_at', now)      // Conditionnelle
    .addAll({'views': 0, 'likes': 0})             // Ajouter plusieurs
    .addRelation('author', author?.id)            // Relations (si non-null)
    .build();
```

**DirectusModelRegistry - Factory management:**
```dart
// Enregistrer un modèle
DirectusModelRegistry.register<Article>(Article.fromJson);

// Créer depuis JSON
final article = DirectusModelRegistry.create<Article>(json);
final articles = DirectusModelRegistry.createList<Article>(jsonList);

// Vérifier l'enregistrement
if (DirectusModelRegistry.isRegistered<Article>()) { ... }
```

### Utilisation avec ItemsService

```dart
final articlesService = client.items('articles');

// Lire avec désérialisation automatique
final article = await articlesService.readOne(
  'article-id',
  fromJson: Article.fromJson,
) as Article;

// Créer/Mettre à jour avec toJson()
final newArticle = Article(title: 'Test', content: 'Content');
await articlesService.createOne(newArticle.toJson());
await articlesService.updateOne('id', newArticle.toJson());

// Avec le Registry (optionnel)
DirectusModelRegistry.register<Article>(Article.fromJson);
final articles = DirectusModelRegistry.createList<Article>(jsonList);
```

### Annotations (préparation génération de code)

La librairie fournit des annotations pour une future implémentation de génération de code automatique :

```dart
@directusModel
class Product extends DirectusModel with DirectusSerializable<Product> {
  final String name;
  
  @DirectusField('price_eur')
  final double price;
  
  @DirectusRelation()
  final String? categoryId;
  
  @DirectusIgnore()
  String get displayPrice => '€${price.toStringAsFixed(2)}';
  
  // ... constructeurs et méthodes
}
```

**Annotations disponibles:**
- `@directusModel` : Marque une classe pour la génération
- `@DirectusField('json_name')` : Map un nom de champ JSON personnalisé
- `@DirectusRelation()` : Indique un champ de relation
- `@DirectusIgnore()` : Exclut un champ de la sérialisation

### Dirty Tracking (Suivi des modifications) ✨

Le système de dirty tracking permet de tracker automatiquement les modifications d'un modèle et d'envoyer **uniquement les champs modifiés** lors des mises à jour (UPDATE). Ce système est **totalement transparent** : les getters retournent toujours les valeurs actuelles, qu'elles soient modifiées ou non.

#### Fonctionnement automatique

Toute modification via les setters est automatiquement trackée :

```dart
// Récupérer un utilisateur depuis Directus
final userData = await client.users.getUser('user-123');
final user = DirectusUser(userData);

// État initial
print(user.isDirty);  // false
print(user.dirtyFields);  // {}

// Modifier des champs
user.firstName.set('Jean');
user.lastName.set('Dupont');
user.appearance.set('dark');

// Les modifications sont automatiquement trackées
print(user.isDirty);  // true
print(user.dirtyFields);  // {first_name, last_name, appearance}

// La lecture est transparente (retourne la valeur modifiée)
print(user.firstName.value);  // 'Jean' ✅
```

#### Envoi des modifications avec toJsonDirty()

La méthode `toJsonDirty()` retourne **uniquement les champs modifiés** :

```dart
// toJson() retourne TOUT (y compris les relations complètes)
final fullJson = user.toJson();
print(fullJson.keys.length);  // 15+ champs

// toJsonDirty() retourne UNIQUEMENT les modifications
final dirtyJson = user.toJsonDirty();
print(dirtyJson);
// {first_name: "Jean", last_name: "Dupont", appearance: "dark"}

// Envoyer à Directus (optimisé, bande passante réduite)
await client.users.updateUser(user.id!, user.toJsonDirty());
```

#### Gestion automatique des relations

Le système extrait automatiquement les IDs des relations :

```dart
// Après récupération, le rôle est un objet complet
final user = DirectusUser(await client.users.getUser('user-123'));
print(user.role.value);  // DirectusRole{id: 'role-admin-123', name: 'Administrator', ...}

// Modifier le rôle
user.role.setById('role-editor-456');

// toJsonDirty() extrait automatiquement l'ID
final updates = user.toJsonDirty();
print(updates['role']);  // 'role-editor-456' (juste l'ID, pas l'objet complet) ✅

// Many-to-Many : liste d'objets → liste d'IDs
user.policies.setByIds(['policy-1', 'policy-2']);
final updates2 = user.toJsonDirty();
print(updates2['policies']);  // ['policy-1', 'policy-2'] ✅
```

#### API de gestion du tracking

```dart
// Vérifier si le modèle a été modifié
if (user.isDirty) {
  print('Le modèle a été modifié');
}

// Vérifier un champ spécifique
if (user.isDirtyField('first_name')) {
  print('Le prénom a été modifié');
}

// Obtenir la liste des champs modifiés
final modified = user.dirtyFields;
print('Champs modifiés: $modified');  // {first_name, last_name}

// Obtenir la valeur originale d'un champ
final originalName = user.getOriginalValue('first_name');
print('Ancien: $originalName, Nouveau: ${user.firstName.value}');

// Annuler toutes les modifications (rollback)
user.revert();
print(user.firstName.value);  // Restauré à la valeur originale
print(user.isDirty);  // false

// Marquer comme propre après sauvegarde réussie
await client.users.updateUser(user.id!, user.toJsonDirty());
user.markClean();  // Reset le tracking
print(user.isDirty);  // false
```

#### Workflow complet

```dart
// 1. Récupérer un objet existant
final user = DirectusUser(await client.users.getUser('user-123'));
print(user.isDirty);  // false

// 2. Modifier plusieurs champs
user.firstName.set('Jean');
user.status.set('invited');
user.role.setById('role-editor-123');
print(user.isDirty);  // true
print(user.dirtyFields);  // {first_name, status, role}

// 3. Vérifier les modifications avant sauvegarde
if (user.isDirty) {
  print('Modifications à envoyer:');
  for (final field in user.dirtyFields) {
    print('- $field: ${user.getOriginalValue(field)} → ${user.get(field)}');
  }
}

// 4. Envoyer UNIQUEMENT les modifications
await client.users.updateUser(
  user.id!,
  user.toJsonDirty(),  // {"first_name": "Jean", "status": "invited", "role": "role-editor-123"}
);

// 5. Marquer comme propre après succès
user.markClean();
print(user.isDirty);  // false

// 6. Nouvelles modifications trackées à partir de l'état sauvegardé
user.appearance.set('light');
print(user.dirtyFields);  // {appearance}
```

#### Différences entre les méthodes de sérialisation

```dart
final user = DirectusUser(userData);
user.firstName.set('Modified');

// toJson() - TOUT (pour CREATE ou export complet)
final full = user.toJson();
// {id, email, first_name, last_name, role, date_created, date_updated, ...}

// toMap() - Champs personnalisés uniquement (sans champs système)
final custom = user.toMap();
// {email, first_name, last_name, role, ...} (sans id, date_created, etc.)

// toJsonDirty() - UNIQUEMENT les modifications (pour UPDATE)
final dirty = user.toJsonDirty();
// {first_name: "Modified"}
```

#### Avantages

✅ **Totalement transparent** : Getters retournent toujours les valeurs actuelles  
✅ **Automatique** : Aucun code manuel pour tracker les modifications  
✅ **Optimisé** : Réduit la bande passante (envoie seulement les changements)  
✅ **Relations intelligentes** : Conversion automatique objets → IDs  
✅ **Gestion d'état** : revert(), markClean(), isDirty pour contrôle complet  
✅ **Debuggable** : dirtyFields, getOriginalValue() pour inspection  

Voir [example/dirty_tracking_example.dart](example/dirty_tracking_example.dart) pour des exemples complets.

---

### WebSocket (Temps réel)

```dart
// Création du client WebSocket
final wsClient = DirectusWebSocketClient(
  config,
  accessToken: client.auth.accessToken,
);

await wsClient.connect();

// Abonnement aux événements
final subscriptionId = await wsClient.subscribe(
  collection: 'articles',
  onMessage: (message) {
    print('Nouvel événement: ${message.type}');
    print('Données: ${message.data}');
  },
);

// Se désabonner
await wsClient.unsubscribe(subscriptionId);

// Fermer la connexion
await wsClient.disconnect();
```

### Gestion des fichiers

```dart
// Upload depuis un fichier local
final file = await client.files.uploadFile(
  filePath: '/path/to/image.jpg',
  title: 'Mon image',
  folder: 'folder-id',
);

// Upload depuis des bytes
final fileFromBytes = await client.files.uploadFileFromBytes(
  bytes: imageBytes,
  filename: 'image.jpg',
  title: 'Mon image',
);

// Importer depuis une URL
final importedFile = await client.files.importFile(
  url: 'https://example.com/image.jpg',
  title: 'Image importée',
);

// Obtenir l'URL d'un fichier
final url = client.files.getFileUrl('file-id');

// Obtenir l'URL d'un thumbnail
final thumbnailUrl = client.files.getThumbnailUrl(
  'file-id',
  width: 200,
  height: 200,
  fit: 'cover',
);
```

### Gestion des utilisateurs

```dart
// Utilisateur connecté
final me = await client.users.me();
print('Connecté en tant que: ${me['email']}');

// Mettre à jour son profil
await client.users.updateMe({
  'first_name': 'John',
  'last_name': 'Doe',
});

// Liste des utilisateurs
final users = await client.users.getUsers();

// Inviter des utilisateurs
await client.users.inviteUsers(
  emails: ['newuser@example.com'],
  roleId: 'role-id',
);
```

## 🔧 Fonctionnalités avancées

### Paramètres de requête

```dart
final response = await client.items('articles').readMany(
  query: QueryParameters(
    // Filtrage
    filter: {
      '_and': [
        {'status': {'_eq': 'published'}},
        {'author': {'_eq': 'user-id'}},
      ]
    },
    
    // Champs à retourner
    fields: ['id', 'title', 'author.first_name'],
    
    // Tri
    sort: ['-date_created', 'title'],
    
    // Pagination
    limit: 20,
    offset: 0,
    // ou
    page: 1,
    
    // Recherche full-text
    search: 'mot-clé',
    
    // Relations profondes
    deep: {
      'author': {
        '_filter': {'status': {'_eq': 'active'}}
      }
    },
  ),
);
```

### Gestion des erreurs ✨

La librairie implémente **tous les 31 codes d'erreur officiels de Directus** avec des exceptions typées pour chaque catégorie d'erreur.

```dart
try {
  await client.items('articles').readOne('invalid-id');
} on DirectusNotFoundException catch (e) {
  // Code: ROUTE_NOT_FOUND
  print('Article non trouvé: ${e.message}');
} on DirectusAuthException catch (e) {
  // Codes: INVALID_CREDENTIALS, TOKEN_EXPIRED, INVALID_OTP, USER_SUSPENDED
  if (e.errorCode == DirectusErrorCode.tokenExpired.code) {
    // Rafraîchir le token
    await client.auth.refresh();
  }
} on DirectusValidationException catch (e) {
  // Codes: INVALID_PAYLOAD, INVALID_QUERY, VALUE_TOO_LONG, etc.
  print('Erreur de validation: ${e.message}');
  if (e.fieldErrors != null) {
    e.fieldErrors!.forEach((field, errors) {
      print('  $field: ${errors.join(", ")}');
    });
  }
} on DirectusPermissionException catch (e) {
  // Code: FORBIDDEN
  print('Accès refusé: ${e.message}');
} on DirectusRateLimitException catch (e) {
  // Codes: REQUESTS_EXCEEDED, EMAIL_LIMIT_EXCEEDED, LIMIT_EXCEEDED
  print('Trop de requêtes, réessayez plus tard');
} on DirectusNetworkException catch (e) {
  print('Erreur réseau: ${e.message}');
} on DirectusException catch (e) {
  // Toutes les autres erreurs
  print('Erreur Directus [${e.errorCode}]: ${e.message}');
}
```

**Types d'exceptions disponibles:**

| Exception | Description | Codes d'erreur |
|-----------|-------------|----------------|
| `DirectusAuthException` | Erreurs d'authentification | INVALID_CREDENTIALS, TOKEN_EXPIRED, INVALID_OTP, etc. |
| `DirectusValidationException` | Erreurs de validation | INVALID_PAYLOAD, VALUE_TOO_LONG, NOT_NULL_VIOLATION, etc. |
| `DirectusPermissionException` | Erreurs de permission | FORBIDDEN |
| `DirectusNotFoundException` | Ressource introuvable | ROUTE_NOT_FOUND |
| `DirectusServerException` | Erreurs serveur | INTERNAL_SERVER_ERROR, SERVICE_UNAVAILABLE, etc. |
| `DirectusFileException` | Erreurs de fichiers | CONTENT_TOO_LARGE, UNSUPPORTED_MEDIA_TYPE, etc. |
| `DirectusRateLimitException` | Limite de taux dépassée | REQUESTS_EXCEEDED, EMAIL_LIMIT_EXCEEDED, etc. |
| `DirectusDatabaseException` | Erreurs de base de données | INVALID_FOREIGN_KEY, RECORD_NOT_UNIQUE |
| `DirectusMethodNotAllowedException` | Méthode HTTP non autorisée | METHOD_NOT_ALLOWED |
| `DirectusRangeException` | Plage invalide | RANGE_NOT_SATISFIABLE |
| `DirectusConfigException` | Erreurs de configuration | INVALID_IP, INVALID_PROVIDER, etc. |
| `DirectusNetworkException` | Erreurs réseau | Timeout, pas de connexion, etc. |

**Accès aux extensions:**

Les erreurs Directus peuvent contenir des informations supplémentaires dans le champ `extensions`:

```dart
on DirectusDatabaseException catch (e) {
  print('Collection: ${e.collection}');
  print('Champ: ${e.field}');
  print('Code: ${e.errorCode}');
}

on DirectusMethodNotAllowedException catch (e) {
  print('Méthodes autorisées: ${e.allowedMethods?.join(", ")}');
}
```

**Enum des codes d'erreur:**

Utilisez l'enum `DirectusErrorCode` pour comparer les codes d'erreur:

```dart
if (e.errorCode == DirectusErrorCode.tokenExpired.code) {
  // Token expiré
} else if (e.errorCode == DirectusErrorCode.recordNotUnique.code) {
  // Doublon dans la base de données
}
```

Voir le [Guide complet des codes d'erreur](docs/ERROR_CODES.md) pour tous les détails.

### Refresh token automatique

```dart
// Le refresh se fait automatiquement, mais vous pouvez le faire manuellement
try {
  await client.auth.refresh();
} catch (e) {
  // Token expiré, reconnexion nécessaire
  await client.auth.login(email: email, password: password);
}
```

## 📚 Exemples

Consultez le dossier [example/](example/) pour des exemples complets:

- [basic_usage.dart](example/basic_usage.dart) - Utilisation basique
- [custom_model.dart](example/custom_model.dart) - Modèles personnalisés
- [websocket_example.dart](example/websocket_example.dart) - WebSocket en temps réel

## 🧪 Tests

Pour exécuter les tests:

```bash
flutter test
```

## 📖 Documentation

### Documentation API

La documentation complète de l'API est disponible via Dartdoc:

```bash
dart doc
```

### Guides complets

- 📘 [**Guide Architecture**](docs/ARCHITECTURE.md) - Structure et design patterns de la librairie
- 📗 [**Guide des Modèles**](docs/MODELS_GUIDE.md) - Utilisation détaillée des Builders (DirectusModelBuilder, DirectusMapBuilder)
- 📙 [**Guide DirectusModel**](docs/DIRECTUS_MODEL.md) - Classe de base, helpers et bonnes pratiques
- 🔄 [**Guide de Migration**](docs/MIGRATION_BUILDERS.md) - Migrer vers les Builders (v0.1.0 → v0.2.0)
- 🤝 [**Guide Contribution**](docs/CONTRIBUTING.md) - Comment contribuer au projet
- 📚 [**API Directus**](https://docs.directus.io/reference/api/) - Documentation officielle Directus

## 🤝 Contribution

Les contributions sont les bienvenues! N'hésitez pas à:

1. Fork le projet
2. Créer une branche (`git checkout -b feature/amazing-feature`)
3. Commit vos changements (`git commit -m 'Add amazing feature'`)
4. Push vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🔗 Liens utiles

- [Documentation Directus](https://docs.directus.io/)
- [API Reference Directus](https://docs.directus.io/reference/api/)
- [Package sur pub.dev](https://pub.dev/packages/fcs_directus)

## ✨ Auteur

Créé par [fracosfr](https://github.com/fracosfr)

## 🙏 Remerciements

- L'équipe [Directus](https://directus.io/) pour leur excellente plateforme
- La communauté Flutter/Dart


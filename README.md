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
- ✅ **Modèles typés** - Créez vos propres modèles Dart
- ✅ **Filtres et requêtes** - Filtrage, tri, pagination, recherche
- ✅ **Gestion d'erreurs** - Exceptions typées et gestion robuste
- ✅ **Documentation complète** - Dartdoc pour toutes les API publiques
- ✅ **Tests unitaires** - Code testé et fiable

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

// Lire
final allArticles = await articles.readMany(
  query: QueryParameters(
    limit: 10,
    sort: ['-date_created'],
    filter: {'status': {'_eq': 'published'}},
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

### Gestion des erreurs

```dart
try {
  await client.items('articles').readOne('invalid-id');
} on DirectusNotFoundException catch (e) {
  print('Article non trouvé: ${e.message}');
} on DirectusAuthException catch (e) {
  print('Erreur d\'authentification: ${e.message}');
} on DirectusValidationException catch (e) {
  print('Erreur de validation: ${e.fieldErrors}');
} on DirectusNetworkException catch (e) {
  print('Erreur réseau: ${e.message}');
} on DirectusException catch (e) {
  print('Erreur Directus: ${e.message} [${e.statusCode}]');
}
```

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


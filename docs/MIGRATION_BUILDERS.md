# Guide de migration vers les Builders

Ce guide vous aide à migrer vos modèles existants vers la nouvelle approche avec Builders.

## Pourquoi migrer ?

Les Builders offrent :
- ✅ **50% moins de code** dans vos modèles
- ✅ **Type-safety renforcée** avec conversions automatiques
- ✅ **Zéro code JSON** dans vos classes métier
- ✅ **API fluide** pour la construction de Maps
- ✅ **Gestion automatique** des valeurs par défaut et null-safety

## Migration étape par étape

### Étape 1 : Installer la nouvelle version

```yaml
# pubspec.yaml
dependencies:
  fcs_directus: ^0.2.0
```

```bash
flutter pub get
```

### Étape 2 : Migrer fromJson()

#### Avant (v0.1.0)

```dart
class Article extends DirectusModel {
  final String title;
  final String? content;
  final int views;
  final bool published;

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: DirectusModel.parseId(json['id']),
      title: json['title'] as String,
      content: json['content'] as String?,
      views: json['views'] as int? ?? 0,
      published: json['published'] as bool? ?? false,
      dateCreated: DirectusModel.parseDate(json['date_created']),
      dateUpdated: DirectusModel.parseDate(json['date_updated']),
    );
  }
}
```

#### Après (v0.2.0)

```dart
class Article extends DirectusModel {
  final String title;
  final String? content;
  final int views;
  final bool published;

  Article._({
    super.id,
    required this.title,
    this.content,
    required this.views,
    required this.published,
    super.dateCreated,
    super.dateUpdated,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    return Article._(
      id: builder.id,
      title: builder.getString('title'),
      content: builder.getStringOrNull('content'),
      views: builder.getInt('views', defaultValue: 0),
      published: builder.getBool('published', defaultValue: false),
      dateCreated: builder.dateCreated,
      dateUpdated: builder.dateUpdated,
    );
  }
}
```

**Changements :**
1. Constructeur principal devient privé (`Article._`)
2. Utilisation de `DirectusModelBuilder` au lieu de casts manuels
3. Getters typés : `getString`, `getInt`, `getBool`
4. Valeurs par défaut intégrées dans les getters

### Étape 3 : Migrer toMap()

#### Avant (v0.1.0)

```dart
@override
Map<String, dynamic> toMap() {
  final map = <String, dynamic>{
    'title': title,
    'views': views,
    'published': published,
  };
  if (content != null) {
    map['content'] = content;
  }
  return map;
}
```

#### Après (v0.2.0)

```dart
@override
Map<String, dynamic> toMap() {
  return DirectusMapBuilder()
      .add('title', title)
      .addIfNotNull('content', content)
      .add('views', views)
      .add('published', published)
      .build();
}
```

**Changements :**
1. Utilisation de `DirectusMapBuilder`
2. Méthode `addIfNotNull()` remplace les `if (x != null)`
3. Chaînage fluide des appels
4. Plus lisible et maintenable

### Étape 4 : Ajouter un factory public (optionnel)

Pour pouvoir créer des instances depuis le code (pas seulement depuis JSON) :

```dart
factory Article({
  String? id,
  required String title,
  String? content,
  int views = 0,
  bool published = false,
  DateTime? dateCreated,
  DateTime? dateUpdated,
}) => Article._(
  id: id,
  title: title,
  content: content,
  views: views,
  published: published,
  dateCreated: dateCreated,
  dateUpdated: dateUpdated,
);
```

## Exemples de migration complets

### Modèle simple

#### Avant

```dart
class User extends DirectusModel {
  final String email;
  final String firstName;
  final String lastName;

  User({
    super.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    super.dateCreated,
    super.dateUpdated,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: DirectusModel.parseId(json['id']),
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      dateCreated: DirectusModel.parseDate(json['date_created']),
      dateUpdated: DirectusModel.parseDate(json['date_updated']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}
```

#### Après

```dart
class User extends DirectusModel {
  final String email;
  final String firstName;
  final String lastName;

  User._({
    super.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    super.dateCreated,
    super.dateUpdated,
  });

  factory User({
    String? id,
    required String email,
    required String firstName,
    required String lastName,
    DateTime? dateCreated,
    DateTime? dateUpdated,
  }) => User._(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    dateCreated: dateCreated,
    dateUpdated: dateUpdated,
  );

  factory User.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    return User._(
      id: builder.id,
      email: builder.getString('email'),
      firstName: builder.getString('first_name'),
      lastName: builder.getString('last_name'),
      dateCreated: builder.dateCreated,
      dateUpdated: builder.dateUpdated,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('email', email)
        .add('first_name', firstName)
        .add('last_name', lastName)
        .build();
  }
}
```

### Modèle avec relations

#### Avant

```dart
class Article extends DirectusModel {
  final String title;
  final User? author;

  Article({
    super.id,
    required this.title,
    this.author,
    super.dateCreated,
    super.dateUpdated,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    User? author;
    final authorData = json['author'];
    if (authorData != null && authorData is Map<String, dynamic>) {
      author = User.fromJson(authorData);
    }

    return Article(
      id: DirectusModel.parseId(json['id']),
      title: json['title'] as String,
      author: author,
      dateCreated: DirectusModel.parseDate(json['date_created']),
      dateUpdated: DirectusModel.parseDate(json['date_updated']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'title': title};
    if (author != null) {
      map['author'] = author!.id;
    }
    return map;
  }
}
```

#### Après

```dart
class Article extends DirectusModel {
  final String title;
  final User? author;

  Article._({
    super.id,
    required this.title,
    this.author,
    super.dateCreated,
    super.dateUpdated,
  });

  factory Article({
    String? id,
    required String title,
    User? author,
    DateTime? dateCreated,
    DateTime? dateUpdated,
  }) => Article._(
    id: id,
    title: title,
    author: author,
    dateCreated: dateCreated,
    dateUpdated: dateUpdated,
  );

  factory Article.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    
    User? author;
    final authorJson = builder.getObjectOrNull('author');
    if (authorJson != null) {
      author = User.fromJson(authorJson);
    }

    return Article._(
      id: builder.id,
      title: builder.getString('title'),
      author: author,
      dateCreated: builder.dateCreated,
      dateUpdated: builder.dateUpdated,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('title', title)
        .addRelation('author', author?.id)
        .build();
  }
}
```

### Modèle avec types complexes

#### Avant

```dart
class Product extends DirectusModel {
  final String name;
  final double price;
  final int stock;
  final bool active;
  final List<String> tags;
  final DateTime? publishedAt;

  Product({
    super.id,
    required this.name,
    required this.price,
    required this.stock,
    this.active = true,
    this.tags = const [],
    this.publishedAt,
    super.dateCreated,
    super.dateUpdated,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final tagsList = json['tags'] as List<dynamic>?;
    final tags = tagsList?.map((e) => e.toString()).toList() ?? [];

    DateTime? publishedAt;
    if (json['published_at'] != null) {
      publishedAt = DateTime.tryParse(json['published_at'].toString());
    }

    return Product(
      id: DirectusModel.parseId(json['id']),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
      tags: tags,
      publishedAt: publishedAt,
      dateCreated: DirectusModel.parseDate(json['date_created']),
      dateUpdated: DirectusModel.parseDate(json['date_updated']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'price': price,
      'stock': stock,
      'active': active,
    };
    if (tags.isNotEmpty) {
      map['tags'] = tags;
    }
    if (publishedAt != null) {
      map['published_at'] = publishedAt!.toIso8601String();
    }
    return map;
  }
}
```

#### Après

```dart
class Product extends DirectusModel {
  final String name;
  final double price;
  final int stock;
  final bool active;
  final List<String> tags;
  final DateTime? publishedAt;

  Product._({
    super.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.active,
    required this.tags,
    this.publishedAt,
    super.dateCreated,
    super.dateUpdated,
  });

  factory Product({
    String? id,
    required String name,
    required double price,
    int stock = 0,
    bool active = true,
    List<String> tags = const [],
    DateTime? publishedAt,
    DateTime? dateCreated,
    DateTime? dateUpdated,
  }) => Product._(
    id: id,
    name: name,
    price: price,
    stock: stock,
    active: active,
    tags: tags,
    publishedAt: publishedAt,
    dateCreated: dateCreated,
    dateUpdated: dateUpdated,
  );

  factory Product.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    return Product._(
      id: builder.id,
      name: builder.getString('name'),
      price: builder.getDouble('price'),
      stock: builder.getInt('stock', defaultValue: 0),
      active: builder.getBool('active', defaultValue: true),
      tags: builder.getList<String>('tags'),
      publishedAt: builder.getDateTimeOrNull('published_at'),
      dateCreated: builder.dateCreated,
      dateUpdated: builder.dateUpdated,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('name', name)
        .add('price', price)
        .add('stock', stock)
        .add('active', active)
        .addIf(tags.isNotEmpty, 'tags', tags)
        .addIfNotNull('published_at', publishedAt?.toIso8601String())
        .build();
  }
}
```

## Cas particuliers

### Conversions personnalisées

#### Avant

```dart
factory Product.fromJson(Map<String, dynamic> json) {
  // Conversion manuelle string -> double
  double price = 0.0;
  final priceValue = json['price'];
  if (priceValue is num) {
    price = priceValue.toDouble();
  } else if (priceValue is String) {
    price = double.tryParse(priceValue) ?? 0.0;
  }

  return Product(
    price: price,
    // ...
  );
}
```

#### Après

```dart
factory Product.fromJson(Map<String, dynamic> json) {
  final builder = DirectusModelBuilder(json);
  return Product._(
    // Conversion automatique !
    price: builder.getDouble('price', defaultValue: 0.0),
    // ...
  );
}
```

Le builder gère automatiquement :
- `"19.99"` → `19.99`
- `19` → `19.0`
- `null` → `0.0` (si defaultValue fourni)

### Enums

#### Avant

```dart
enum ArticleStatus { draft, published, archived }

factory Article.fromJson(Map<String, dynamic> json) {
  final statusStr = json['status'] as String? ?? 'draft';
  final status = ArticleStatus.values.firstWhere(
    (e) => e.name == statusStr,
    orElse: () => ArticleStatus.draft,
  );

  return Article(
    status: status,
    // ...
  );
}
```

#### Après

```dart
enum ArticleStatus { draft, published, archived }

factory Article.fromJson(Map<String, dynamic> json) {
  final builder = DirectusModelBuilder(json);
  final statusStr = builder.getString('status', defaultValue: 'draft');
  final status = ArticleStatus.values.firstWhere(
    (e) => e.name == statusStr,
    orElse: () => ArticleStatus.draft,
  );

  return Article._(
    status: status,
    // ...
  );
}
```

### Many-to-many relations

#### Avant

```dart
factory Article.fromJson(Map<String, dynamic> json) {
  final categoriesData = json['categories'] as List<dynamic>? ?? [];
  final categoryIds = <String>[];
  
  for (final item in categoriesData) {
    if (item is Map<String, dynamic>) {
      final catData = item['categories_id'];
      if (catData is Map<String, dynamic> && catData['id'] != null) {
        categoryIds.add(catData['id'].toString());
      }
    }
  }

  return Article(
    categoryIds: categoryIds,
    // ...
  );
}
```

#### Après

```dart
factory Article.fromJson(Map<String, dynamic> json) {
  final builder = DirectusModelBuilder(json);
  
  final categories = builder.getList<Map<String, dynamic>>('categories');
  final categoryIds = categories
      .map((c) => c['categories_id']?['id'] as String?)
      .whereType<String>()
      .toList();

  return Article._(
    categoryIds: categoryIds,
    // ...
  );
}
```

## Checklist de migration

Pour chaque modèle :

- [ ] Rendre le constructeur principal privé (`_`)
- [ ] Ajouter un factory public pour créer depuis le code
- [ ] Dans `fromJson()` :
  - [ ] Créer un `DirectusModelBuilder`
  - [ ] Utiliser `builder.id` au lieu de `parseId()`
  - [ ] Utiliser `builder.dateCreated/dateUpdated` au lieu de `parseDate()`
  - [ ] Remplacer les casts par `getString`, `getInt`, etc.
  - [ ] Utiliser les variants `OrNull` pour champs optionnels
  - [ ] Ajouter `defaultValue` pour les valeurs par défaut
  - [ ] Utiliser `getObjectOrNull` pour les relations
- [ ] Dans `toMap()` :
  - [ ] Créer un `DirectusMapBuilder()`
  - [ ] Utiliser `add()` pour champs obligatoires
  - [ ] Utiliser `addIfNotNull()` pour champs optionnels
  - [ ] Utiliser `addIf()` pour conditions
  - [ ] Utiliser `addRelation()` pour les relations
  - [ ] Appeler `.build()` à la fin
- [ ] Tester la migration :
  - [ ] fromJson → toMap round-trip
  - [ ] Création depuis code avec factory public
  - [ ] Null-safety
  - [ ] Valeurs par défaut

## Tester la migration

```dart
void testArticleMigration() {
  // Test 1: fromJson
  final json = {
    'id': '123',
    'title': 'Test Article',
    'content': 'Content here',
    'views': 42,
    'published': true,
    'date_created': '2024-01-15T10:30:00Z',
    'date_updated': '2024-01-15T11:00:00Z',
  };

  final article = Article.fromJson(json);
  assert(article.id == '123');
  assert(article.title == 'Test Article');
  assert(article.views == 42);
  assert(article.published == true);

  // Test 2: toMap
  final map = article.toMap();
  assert(map['title'] == 'Test Article');
  assert(map['views'] == 42);

  // Test 3: Round-trip
  final article2 = Article.fromJson(article.toJson());
  assert(article2.id == article.id);
  assert(article2.title == article.title);

  // Test 4: Factory public
  final article3 = Article(
    title: 'New Article',
    views: 0,
    published: false,
  );
  assert(article3.title == 'New Article');
  assert(article3.views == 0);

  print('✅ Migration réussie !');
}
```

## Support

Pour toute question ou problème lors de la migration :
1. Consultez `docs/MODELS_GUIDE.md` pour des exemples détaillés
2. Regardez `example/advanced_builders_example.dart` pour des cas d'usage complexes
3. Vérifiez `test/models/directus_builder_test.dart` pour voir tous les cas de test

## Rétrocompatibilité

La v0.2.0 est **rétrocompatible**. Vos anciens modèles continueront de fonctionner. La migration est **optionnelle** mais fortement recommandée pour :
- Réduire le boilerplate
- Améliorer la maintenabilité
- Profiter des conversions automatiques
- Préparer la génération de code future

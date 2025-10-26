# Guide des Modèles Directus

Ce guide explique en détail comment créer et utiliser des modèles Directus avec la librairie `fcs_directus`.

## Table des matières

- [Introduction](#introduction)
- [DirectusModel - Classe de base](#directusmodel---classe-de-base)
- [Builders - Approche recommandée](#builders---approche-recommandée)
- [Exemples avancés](#exemples-avancés)
- [Registry Pattern](#registry-pattern)
- [Annotations](#annotations)
- [Bonnes pratiques](#bonnes-pratiques)

---

## Introduction

La librairie `fcs_directus` propose plusieurs approches pour créer vos modèles :

1. **Avec Builders** ✨ (Recommandé) - Code propre, type-safe, zéro boilerplate JSON
2. **Manuelle** - Contrôle total, plus verbeux

Tous les modèles héritent de `DirectusModel` qui gère automatiquement :
- `id` (String?)
- `dateCreated` (DateTime?)
- `dateUpdated` (DateTime?)
- Sérialisation JSON de base
- Égalité basée sur l'ID

---

## DirectusModel - Classe de base

### Héritage

```dart
abstract class DirectusModel {
  final String? id;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;

  DirectusModel({
    this.id,
    this.dateCreated,
    this.dateUpdated,
  });

  // Méthodes abstraites
  Map<String, dynamic> toMap(); // À implémenter

  // Méthodes concrètes
  Map<String, dynamic> toJson(); // Combine toMap() + champs de base
  
  // Helpers statiques
  static String? parseId(dynamic value);
  static DateTime? parseDate(dynamic value);
}
```

### Méthodes fournies

**toJson()** - Génère le JSON complet
```dart
final article = Article(title: 'Test');
final json = article.toJson();
// { 'id': '...', 'date_created': '...', 'title': 'Test' }
```

**parseId()** - Parse l'ID depuis différents types
```dart
DirectusModel.parseId(123)        // '123'
DirectusModel.parseId('abc')      // 'abc'
DirectusModel.parseId(null)       // null
```

**parseDate()** - Parse une date ISO
```dart
DirectusModel.parseDate('2024-01-15T10:30:00Z') // DateTime
DirectusModel.parseDate(null)                    // null
```

---

## Builders - Approche recommandée

### DirectusModelBuilder

Parse le JSON avec des getters type-safe et gestion automatique des conversions.

#### Champs standards Directus

```dart
factory Article.fromJson(Map<String, dynamic> json) {
  final builder = DirectusModelBuilder(json);
  
  return Article(
    id: builder.id,                    // String? depuis 'id'
    dateCreated: builder.dateCreated,  // DateTime? depuis 'date_created'
    dateUpdated: builder.dateUpdated,  // DateTime? depuis 'date_updated'
    userCreated: builder.userCreated,  // String? depuis 'user_created'
    userUpdated: builder.userUpdated,  // String? depuis 'user_updated'
  );
}
```

#### Getters typés

**getString / getStringOrNull**
```dart
builder.getString('title')                    // String (exception si null/absent)
builder.getStringOrNull('content')           // String? (null si absent)
builder.getString('status', defaultValue: 'draft') // String avec défaut
```

**getInt / getIntOrNull**
```dart
builder.getInt('views')                      // int (exception si null)
builder.getIntOrNull('likes')                // int? (null si absent)
builder.getInt('count', defaultValue: 0)     // int avec défaut

// Conversion automatique depuis String
json = {'views': '42'};
builder.getInt('views') // 42 (int)
```

**getDouble / getDoubleOrNull**
```dart
builder.getDouble('price')                   // double
builder.getDoubleOrNull('discount')          // double?
builder.getDouble('rate', defaultValue: 0.0) // double avec défaut

// Conversion automatique
json = {'price': '19.99'};
builder.getDouble('price') // 19.99 (double)
```

**getBool / getBoolOrNull**
```dart
builder.getBool('active')                    // bool
builder.getBoolOrNull('featured')            // bool?
builder.getBool('published', defaultValue: false) // bool avec défaut

// Conversion automatique
json = {'active': 'true'};   builder.getBool('active') // true
json = {'active': 1};        builder.getBool('active') // true
json = {'active': 'false'};  builder.getBool('active') // false
json = {'active': 0};        builder.getBool('active') // false
```

**getDateTime / getDateTimeOrNull**
```dart
builder.getDateTime('published_at')          // DateTime?
builder.getDateTimeOrNull('archived_at')     // DateTime?

// Parse ISO 8601
json = {'published_at': '2024-01-15T10:30:00Z'};
builder.getDateTime('published_at') // DateTime(2024, 1, 15, 10, 30)
```

**getList**
```dart
builder.getList<String>('tags')              // List<String> (vide si null)
builder.getList<int>('scores')               // List<int>
builder.getList<Map<String, dynamic>>('items') // List<Map>

// Toujours non-null
json = {'tags': null};
builder.getList<String>('tags') // [] (liste vide)
```

**getObject / getObjectOrNull**
```dart
builder.getObject('metadata')                // Map<String, dynamic>?
builder.getObjectOrNull('settings')          // Map<String, dynamic>?

// Pour créer des sous-modèles
final authorJson = builder.getObject('author');
if (authorJson != null) {
  final author = User.fromJson(authorJson);
}
```

#### Exemple complet

```dart
@directusModel
class Product extends DirectusModel {
  final String name;
  final String? description;
  final double price;
  final int stock;
  final bool active;
  final List<String> tags;
  final DateTime? publishedAt;
  final User? author;

  Product._({
    super.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.active,
    required this.tags,
    this.publishedAt,
    this.author,
    super.dateCreated,
    super.dateUpdated,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    
    // Parse author si présent
    User? author;
    final authorJson = builder.getObjectOrNull('author');
    if (authorJson != null) {
      author = User.fromJson(authorJson);
    }
    
    return Product._(
      id: builder.id,
      name: builder.getString('name'),
      description: builder.getStringOrNull('description'),
      price: builder.getDouble('price'),
      stock: builder.getInt('stock', defaultValue: 0),
      active: builder.getBool('active', defaultValue: true),
      tags: builder.getList<String>('tags'),
      publishedAt: builder.getDateTimeOrNull('published_at'),
      author: author,
      dateCreated: builder.dateCreated,
      dateUpdated: builder.dateUpdated,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('name', name)
        .addIfNotNull('description', description)
        .add('price', price)
        .add('stock', stock)
        .add('active', active)
        .add('tags', tags)
        .addIfNotNull('published_at', publishedAt?.toIso8601String())
        .addRelation('author', author?.id)
        .build();
  }
}
```

### DirectusMapBuilder

Construit des Maps avec une API fluide qui élimine le boilerplate.

#### Méthodes disponibles

**add** - Toujours ajouter
```dart
DirectusMapBuilder()
    .add('title', 'Mon titre')
    .add('views', 42)
    .build();
// { 'title': 'Mon titre', 'views': 42 }
```

**addIfNotNull** - Ajouter seulement si non-null
```dart
String? content = null;
DirectusMapBuilder()
    .add('title', 'Test')
    .addIfNotNull('content', content)
    .build();
// { 'title': 'Test' } (content omis)

content = 'Hello';
DirectusMapBuilder()
    .add('title', 'Test')
    .addIfNotNull('content', content)
    .build();
// { 'title': 'Test', 'content': 'Hello' }
```

**addIf** - Ajouter conditionnellement
```dart
bool isPublished = true;
DirectusMapBuilder()
    .add('title', 'Test')
    .addIf(isPublished, 'published_at', DateTime.now().toIso8601String())
    .build();
// { 'title': 'Test', 'published_at': '2024-01-15T...' }
```

**addAll** - Ajouter plusieurs champs
```dart
DirectusMapBuilder()
    .add('title', 'Test')
    .addAll({
      'views': 0,
      'likes': 0,
      'comments': 0,
    })
    .build();
// { 'title': 'Test', 'views': 0, 'likes': 0, 'comments': 0 }
```

**addRelation** - Ajouter une relation (si non-null)
```dart
User? author = User(id: 'user-1', name: 'John');
DirectusMapBuilder()
    .add('title', 'Test')
    .addRelation('author', author?.id)
    .build();
// { 'title': 'Test', 'author': 'user-1' }

author = null;
DirectusMapBuilder()
    .add('title', 'Test')
    .addRelation('author', author?.id)
    .build();
// { 'title': 'Test' } (author omis)
```

#### Avant / Après

**Avant (manuel) :**
```dart
Map<String, dynamic> toMap() {
  final map = <String, dynamic>{
    'title': title,
    'price': price,
  };
  if (description != null) {
    map['description'] = description;
  }
  if (tags.isNotEmpty) {
    map['tags'] = tags;
  }
  if (author != null) {
    map['author'] = author!.id;
  }
  return map;
}
```

**Après (builder) :**
```dart
Map<String, dynamic> toMap() {
  return DirectusMapBuilder()
      .add('title', title)
      .add('price', price)
      .addIfNotNull('description', description)
      .addIf(tags.isNotEmpty, 'tags', tags)
      .addRelation('author', author?.id)
      .build();
}
```

---

## Exemples avancés

### Relations many-to-one

```dart
class Article extends DirectusModel {
  final String title;
  final User? author; // Relation

  factory Article.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    
    User? author;
    final authorData = builder.getObjectOrNull('author');
    if (authorData != null) {
      author = User.fromJson(authorData);
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

### Relations many-to-many

```dart
class Article extends DirectusModel {
  final String title;
  final List<String> categoryIds; // IDs des catégories

  factory Article.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    
    // Les relations M2M sont souvent sous forme de junction
    final categories = builder.getList<Map<String, dynamic>>('categories');
    final categoryIds = categories
        .map((c) => c['categories_id']?['id'] as String?)
        .whereType<String>()
        .toList();
    
    return Article._(
      id: builder.id,
      title: builder.getString('title'),
      categoryIds: categoryIds,
      dateCreated: builder.dateCreated,
      dateUpdated: builder.dateUpdated,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('title', title)
        .add('categories', categoryIds.map((id) => {
          'categories_id': {'id': id}
        }).toList())
        .build();
  }
}
```

### Champs calculés

```dart
class Product extends DirectusModel {
  final String name;
  final double price;
  final double taxRate;

  // Champ calculé (non sérialisé)
  double get priceWithTax => price * (1 + taxRate);
  
  // Statut calculé
  String get status {
    if (stock == 0) return 'out_of_stock';
    if (stock < 10) return 'low_stock';
    return 'in_stock';
  }

  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('name', name)
        .add('price', price)
        .add('tax_rate', taxRate)
        // priceWithTax et status ne sont PAS sérialisés
        .build();
  }
}
```

### Validation

```dart
class User extends DirectusModel {
  final String email;
  final String name;

  User._({
    super.id,
    required this.email,
    required this.name,
    super.dateCreated,
    super.dateUpdated,
  }) {
    _validate();
  }

  void _validate() {
    if (!email.contains('@')) {
      throw ArgumentError('Invalid email format');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    return User._(
      id: builder.id,
      email: builder.getString('email'),
      name: builder.getString('name'),
      dateCreated: builder.dateCreated,
      dateUpdated: builder.dateUpdated,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('email', email)
        .add('name', name)
        .build();
  }
}
```

---

## Registry Pattern

Le `DirectusModelRegistry` permet d'enregistrer des factories et de créer des instances sans passer explicitement le constructeur.

### Enregistrement

```dart
void main() {
  // Enregistrer les modèles au démarrage
  DirectusModelRegistry.register<Article>(Article.fromJson);
  DirectusModelRegistry.register<User>(User.fromJson);
  DirectusModelRegistry.register<Product>(Product.fromJson);
  
  runApp(MyApp());
}
```

### Création depuis JSON

```dart
// Créer une instance
final json = {'id': '1', 'title': 'Test'};
final article = DirectusModelRegistry.create<Article>(json);

// Créer une liste
final jsonList = [
  {'id': '1', 'title': 'Article 1'},
  {'id': '2', 'title': 'Article 2'},
];
final articles = DirectusModelRegistry.createList<Article>(jsonList);
```

### Utilisation avec ItemsService

```dart
// Enregistrer une fois
DirectusModelRegistry.register<Article>(Article.fromJson);

// Utiliser partout
final itemsService = client.items('articles');

final articles = await itemsService.readMany(
  fromJson: (json) => DirectusModelRegistry.create<Article>(json),
);
```

### Vérification

```dart
if (DirectusModelRegistry.isRegistered<Article>()) {
  print('Article est enregistré');
}

// Désenregistrer
DirectusModelRegistry.unregister<Article>();

// Tout effacer
DirectusModelRegistry.clear();
```

---

## Annotations

Les annotations préparent la future génération de code automatique.

### @directusModel

Marque une classe pour la génération :

```dart
@directusModel
class Product extends DirectusModel {
  // ...
}
```

### @DirectusField

Map un nom de champ JSON personnalisé :

```dart
class Product extends DirectusModel {
  @DirectusField('price_eur')
  final double price;
  
  // Dans fromJson
  factory Product.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    return Product._(
      price: builder.getDouble('price_eur'), // Utiliser le nom JSON
    );
  }
  
  // Dans toMap
  @override
  Map<String, dynamic> toMap() {
    return DirectusMapBuilder()
        .add('price_eur', price) // Utiliser le nom JSON
        .build();
  }
}
```

### @DirectusRelation

Indique un champ de relation :

```dart
class Article extends DirectusModel {
  @DirectusRelation()
  final String? authorId;
  
  @DirectusRelation()
  final User? author; // Objet complet si chargé avec deep
}
```

### @DirectusIgnore

Exclut un champ de la sérialisation :

```dart
class Product extends DirectusModel {
  final double price;
  final double taxRate;
  
  @DirectusIgnore()
  double get priceWithTax => price * (1 + taxRate);
  
  // priceWithTax ne sera jamais sérialisé dans toMap()
}
```

---

## Bonnes pratiques

### 1. Utilisez les Builders

✅ **Recommandé :**
```dart
factory Article.fromJson(Map<String, dynamic> json) {
  final builder = DirectusModelBuilder(json);
  return Article._(
    id: builder.id,
    title: builder.getString('title'),
    content: builder.getStringOrNull('content'),
  );
}
```

❌ **Éviter :**
```dart
factory Article.fromJson(Map<String, dynamic> json) {
  return Article(
    id: json['id'] as String?,
    title: json['title'] as String,
    content: json['content'] as String?,
  );
}
```

### 2. Constructeur privé + Factory public

✅ **Recommandé :**
```dart
class Article extends DirectusModel {
  final String title;
  
  // Constructeur privé utilisé par fromJson
  Article._({
    super.id,
    required this.title,
    super.dateCreated,
    super.dateUpdated,
  });
  
  // Factory public pour créer depuis le code
  factory Article({
    String? id,
    required String title,
    DateTime? dateCreated,
    DateTime? dateUpdated,
  }) => Article._(
    id: id,
    title: title,
    dateCreated: dateCreated,
    dateUpdated: dateUpdated,
  );
  
  // Factory depuis JSON
  factory Article.fromJson(Map<String, dynamic> json) {
    final builder = DirectusModelBuilder(json);
    return Article._(
      id: builder.id,
      title: builder.getString('title'),
      dateCreated: builder.dateCreated,
      dateUpdated: builder.dateUpdated,
    );
  }
}
```

### 3. Utilisez addIfNotNull pour les champs optionnels

✅ **Recommandé :**
```dart
Map<String, dynamic> toMap() {
  return DirectusMapBuilder()
      .add('title', title)
      .addIfNotNull('content', content)
      .addIfNotNull('description', description)
      .build();
}
```

❌ **Éviter :**
```dart
Map<String, dynamic> toMap() {
  final map = {'title': title};
  if (content != null) map['content'] = content;
  if (description != null) map['description'] = description;
  return map;
}
```

### 4. Valeurs par défaut dans fromJson

✅ **Recommandé :**
```dart
factory Product.fromJson(Map<String, dynamic> json) {
  final builder = DirectusModelBuilder(json);
  return Product._(
    stock: builder.getInt('stock', defaultValue: 0),
    active: builder.getBool('active', defaultValue: true),
    tags: builder.getList<String>('tags'), // Toujours une liste
  );
}
```

### 5. Gestion des relations

✅ **Recommandé :**
```dart
// Parse la relation si présente
User? author;
final authorJson = builder.getObjectOrNull('author');
if (authorJson != null) {
  author = User.fromJson(authorJson);
}

// Sérialise uniquement l'ID
DirectusMapBuilder()
    .addRelation('author', author?.id)
    .build();
```

### 6. Champs calculés avec @DirectusIgnore

✅ **Recommandé :**
```dart
class Product extends DirectusModel {
  final double price;
  final double taxRate;
  
  @DirectusIgnore()
  double get priceWithTax => price * (1 + taxRate);
  
  @DirectusIgnore()
  String get displayPrice => '€${priceWithTax.toStringAsFixed(2)}';
}
```

### 7. Immutabilité

✅ **Recommandé :**
```dart
class Article extends DirectusModel {
  final String title;           // final
  final String? content;        // final
  
  // Pas de setters, créer une copie pour modifier
  Article copyWith({String? title, String? content}) {
    return Article(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      dateCreated: dateCreated,
      dateUpdated: dateUpdated,
    );
  }
}
```

### 8. Documentation

✅ **Recommandé :**
```dart
/// Représente un article dans Directus.
/// 
/// Collection: `articles`
/// 
/// Champs:
/// - `title`: Titre de l'article (requis)
/// - `content`: Contenu au format markdown (optionnel)
/// - `status`: Statut de publication (draft, published, archived)
@directusModel
class Article extends DirectusModel {
  /// Titre de l'article
  final String title;
  
  /// Contenu markdown (peut être null si brouillon)
  final String? content;
  
  /// Statut de publication
  /// 
  /// Valeurs possibles: 'draft', 'published', 'archived'
  final String status;
}
```

---

## Conclusion

Les Builders (`DirectusModelBuilder` et `DirectusMapBuilder`) permettent de créer des modèles propres, type-safe et maintenables sans boilerplate JSON dans vos classes métier.

**Résumé des avantages:**
- ✅ Code plus court et lisible
- ✅ Type-safe avec conversions automatiques
- ✅ Gestion des valeurs par défaut
- ✅ API fluide pour la construction de Maps
- ✅ Séparation complète entre logique métier et sérialisation
- ✅ Préparé pour la génération de code future

Pour plus d'exemples, consultez :
- `example/custom_model.dart` - Exemple simple avec Article
- `example/advanced_builders_example.dart` - Exemple complexe avec relations
- `test/models/directus_builder_test.dart` - Tests exhaustifs

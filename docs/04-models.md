# Models

Guide complet pour créer et utiliser des modèles personnalisés avec DirectusModel.

## 📝 Introduction

Les modèles dans fcs_directus sont des classes Dart qui représentent vos collections Directus. Ils fournissent :

- ✅ Accès type-safe aux données
- ✅ Validation automatique des types
- ✅ Tracking des modifications
- ✅ Méthodes CRUD intégrées (Active Record pattern)
- ✅ Support des relations
- ✅ Sérialisation/Désérialisation JSON automatique

## 🏗️ Créer un modèle basique

### Structure minimale

```dart
import 'package:fcs_directus/fcs_directus.dart';

class Article extends DirectusModel {
  Article(super.data);
  
  // Nom de la collection Directus (REQUIS)
  @override
  String get itemName => 'articles';
}
```

### Ajouter des propriétés

#### Méthode classique (getters/setters)

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  // Propriétés basiques
  String get title => getString('title', defaultValue: '');
  set title(String value) => setString('title', value);
  
  String? get content => getStringOrNull('content');
  set content(String? value) => setStringOrNull('content', value);
  
  String get status => getString('status', defaultValue: 'draft');
  set status(String value) => setString('status', value);
  
  int get viewCount => getInt('view_count', defaultValue: 0);
  set viewCount(int value) => setInt('view_count', value);
  
  bool get featured => getBool('featured', defaultValue: false);
  set featured(bool value) => setBool('featured', value);
  
  DateTime? get publishDate => getDateTime('publish_date');
  set publishDate(DateTime? value) => setDateTime('publish_date', value);
}
```

#### Méthode avec property wrappers (recommandée)

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  // Propriétés avec wrappers
  late final title = stringValue('title');
  late final content = stringValue('content');
  late final status = stringValue('status', defaultValue: 'draft');
  late final viewCount = intValue('view_count');
  late final featured = boolValue('featured');
  late final publishDate = dateTimeValue('publish_date');
}

// Utilisation
final article = Article({});
article.title.set('Mon article');
article.viewCount.increment();
article.featured.set(true);

print(article.title.value);      // "Mon article"
print(article.viewCount.value);  // 1
print(article.featured.value);   // true
```

## 🎨 Types de propriétés supportés

### Types primitifs

```dart
class Product extends DirectusModel {
  Product(super.data);
  
  @override
  String get itemName => 'products';
  
  // String
  late final name = stringValue('name');
  late final description = stringValue('description');
  
  // Int
  late final stock = intValue('stock');
  late final minStock = intValue('min_stock', defaultValue: 10);
  
  // Double
  late final price = doubleValue('price');
  late final discount = doubleValue('discount', defaultValue: 0.0);
  
  // Bool
  late final available = boolValue('available', defaultValue: true);
  late final featured = boolValue('featured');
}
```

### DateTime

```dart
class Event extends DirectusModel {
  Event(super.data);
  
  @override
  String get itemName => 'events';
  
  late final startDate = dateTimeValue('start_date');
  late final endDate = dateTimeValue('end_date');
  
  // Méthode helper
  Duration get duration {
    final start = startDate.value;
    final end = endDate.value;
    if (start == null || end == null) return Duration.zero;
    return end.difference(start);
  }
  
  bool get isUpcoming {
    final start = startDate.value;
    if (start == null) return false;
    return start.isAfter(DateTime.now());
  }
}
```

### Collections (List, Map)

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  // Liste
  late final tags = listValue('tags');
  late final images = listValue('images');
  
  // Map
  late final metadata = mapValue('metadata');
  late final settings = mapValue('settings');
  
  // Méthodes helpers
  void addTag(String tag) {
    final currentTags = tags.value ?? [];
    tags.set([...currentTags, tag]);
  }
  
  void removeTag(String tag) {
    final currentTags = tags.value ?? [];
    tags.set(currentTags.where((t) => t != tag).toList());
  }
}
```

### Enums

```dart
enum ArticleStatus {
  draft,
  published,
  archived;
  
  static ArticleStatus fromString(String value) {
    return ArticleStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ArticleStatus.draft,
    );
  }
}

class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  // Enum property
  ArticleStatus get status {
    final value = getString('status', defaultValue: 'draft');
    return ArticleStatus.fromString(value);
  }
  
  set status(ArticleStatus value) {
    setString('status', value.name);
  }
  
  // Méthodes helpers
  bool get isPublished => status == ArticleStatus.published;
  bool get isDraft => status == ArticleStatus.draft;
  
  void publish() => status = ArticleStatus.published;
  void archive() => status = ArticleStatus.archived;
}
```

## 🔗 Relations

### Many-to-One (M2O)

Un article appartient à un auteur :

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  late final title = stringValue('title');
  
  // Relation M2O: author_id -> users
  User? get author => getModel<User>('author', (data) => User(data));
  
  set author(User? value) {
    if (value == null) {
      remove('author');
    } else {
      setModel('author', value);
    }
  }
  
  // ID de l'auteur
  String? get authorId => getString OrNull('author');
  set authorId(String? value) => setStringOrNull('author', value);
}

class User extends DirectusModel {
  User(super.data);
  
  @override
  String get itemName => 'directus_users';
  
  late final firstName = stringValue('first_name');
  late final lastName = stringValue('last_name');
  late final email = stringValue('email');
  
  String get fullName => '${firstName.value} ${lastName.value}';
}
```

### One-to-Many (O2M)

Un article a plusieurs commentaires :

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  late final title = stringValue('title');
  
  // Relation O2M: articles <- comments
  List<Comment> get comments {
    return getModelList<Comment>('comments', (data) => Comment(data));
  }
  
  set comments(List<Comment> value) {
    setModelList('comments', value);
  }
  
  // Méthodes helpers
  int get commentCount => comments.length;
  
  List<Comment> get approvedComments {
    return comments.where((c) => c.approved.value).toList();
  }
}

class Comment extends DirectusModel {
  Comment(super.data);
  
  @override
  String get itemName => 'comments';
  
  late final content = stringValue('content');
  late final approved = boolValue('approved', defaultValue: false);
  late final createdAt = dateTimeValue('date_created');
  
  // Relation inverse: comment -> article
  String? get articleId => getStringOrNull('article');
  set articleId(String? value) => setStringOrNull('article', value);
}
```

### Many-to-Many (M2M)

Un article a plusieurs tags via une table de jonction :

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  late final title = stringValue('title');
  
  // Relation M2M via articles_tags
  List<Tag> get tags {
    final junctions = getList('tags', defaultValue: []);
    return junctions
        .map((j) => j is Map<String, dynamic> ? j['tags_id'] : j)
        .where((t) => t is Map<String, dynamic>)
        .map((data) => Tag(data as Map<String, dynamic>))
        .toList();
  }
  
  // Méthode helper pour ajouter un tag
  void addTag(String tagId) {
    final currentTags = getList('tags', defaultValue: []);
    currentTags.add({'tags_id': tagId});
    setList('tags', currentTags);
  }
}

class Tag extends DirectusModel {
  Tag(super.data);
  
  @override
  String get itemName => 'tags';
  
  late final name = stringValue('name');
  late final slug = stringValue('slug');
  late final color = stringValue('color');
}
```

## 🔧 Méthodes DirectusModel

### Accès aux données

```dart
// Getters
getString(String key, {String defaultValue = ''})
getStringOrNull(String key)
getInt(String key, {int defaultValue = 0})
getIntOrNull(String key)
getDouble(String key, {double defaultValue = 0.0})
getDoubleOrNull(String key)
getBool(String key, {bool defaultValue = false})
getBoolOrNull(String key)
getDateTime(String key)
getList<T>(String key, {List<T> defaultValue = const []})
getMap(String key, {Map<String, dynamic> defaultValue = const {}})
getModel<T extends DirectusModel>(String key, T Function(Map<String, dynamic>) factory)
getModelList<T extends DirectusModel>(String key, T Function(Map<String, dynamic>) factory)

// Setters
setString(String key, String value)
setStringOrNull(String key, String? value)
setInt(String key, int value)
setIntOrNull(String key, int? value)
setDouble(String key, double value)
setDoubleOrNull(String key, double? value)
setBool(String key, bool value)
setBoolOrNull(String key, bool? value)
setDateTime(String key, DateTime value)
setList(String key, List value)
setMap(String key, Map<String, dynamic> value)
setModel(String key, DirectusModel value)
setModelList(String key, List<DirectusModel> value)

// Utilitaires
has(String key) → bool
remove(String key)
clear()
keys → List<String>
```

### Tracking des modifications

```dart
final article = Article({'title': 'Original'});

// Modifier
article.title.set('Modifié');

// Vérifier si modifié
print(article.isDirty); // true
print(article.dirtyFields); // {'title'}

// Obtenir la valeur originale
print(article.originalValue('title')); // 'Original'

// Obtenir uniquement les modifications
final changes = article.getChanges();
print(changes); // {'title': 'Modifié'}

// Réinitialiser le tracking
article.resetDirty();
print(article.isDirty); // false
```

### Sérialisation

```dart
// Vers JSON
final json = article.toJson();
print(json); // Map<String, dynamic>

// Depuis JSON
final article = Article.fromJson({
  'id': '1',
  'title': 'Mon article',
  'status': 'published',
});

// Copie
final copy = article.copyWith({
  'title': 'Nouveau titre',
});
```

## 🔄 Active Record (CRUD)

### Configuration

Pour utiliser les méthodes Active Record, enregistrez une factory et un service :

```dart
void main() {
  // Initialiser Directus
  final directus = DirectusClient(DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
  ));
  
  await directus.auth.login(email: '...', password: '...');
  
  // Enregistrer la factory
  DirectusModel.registerFactory('articles', (data) => Article(data));
  
  // Enregistrer le service
  Article.registerService(directus.items<Article>('articles'));
}
```

### Créer (Create)

```dart
final article = Article({
  'title': 'Nouvel article',
  'content': 'Contenu...',
  'status': 'draft',
});

// Sauvegarder dans Directus
await article.save();

print('ID: ${article.id}'); // ID généré par Directus
```

### Lire (Read)

```dart
// Charger un article existant
final article = await Article.find('article-id');

print(article.title.value);
print(article.status.value);

// Charger plusieurs articles
final articles = await Article.findMany(
  query: QueryParameters(
    filter: {'status': {'_eq': 'published'}},
    limit: 10,
  ),
);

for (final article in articles) {
  print(article.title.value);
}
```

### Mettre à jour (Update)

```dart
final article = await Article.find('article-id');

// Modifier
article.title.set('Titre modifié');
article.status = 'published';

// Sauvegarder
await article.save();

// Ou sauvegarder uniquement les modifications
if (article.isDirty) {
  await article.save();
}
```

### Supprimer (Delete)

```dart
final article = await Article.find('article-id');

await article.delete();
```

## 🎯 Exemples complets

### Blog Article

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  // Propriétés
  late final title = stringValue('title');
  late final slug = stringValue('slug');
  late final content = stringValue('content');
  late final excerpt = stringValue('excerpt');
  late final status = stringValue('status', defaultValue: 'draft');
  late final viewCount = intValue('view_count');
  late final featured = boolValue('featured');
  late final publishDate = dateTimeValue('publish_date');
  late final tags = listValue('tags');
  
  // Relations
  User? get author => getModel<User>('author', (data) => User(data));
  
  List<Comment> get comments {
    return getModelList<Comment>('comments', (data) => Comment(data));
  }
  
  // Computed properties
  bool get isPublished => status.value == 'published';
  bool get isDraft => status.value == 'draft';
  
  int get commentCount => comments.length;
  
  String get readingTime {
    final words = content.value.split(' ').length;
    final minutes = (words / 200).ceil();
    return '$minutes min read';
  }
  
  // Méthodes
  void publish() {
    status.set('published');
    publishDate.set(DateTime.now());
  }
  
  void archive() {
    status.set('archived');
  }
  
  void incrementViews() {
    viewCount.increment();
  }
}
```

### E-commerce Product

```dart
class Product extends DirectusModel {
  Product(super.data);
  
  @override
  String get itemName => 'products';
  
  // Propriétés
  late final name = stringValue('name');
  late final sku = stringValue('sku');
  late final description = stringValue('description');
  late final price = doubleValue('price');
  late final compareAtPrice = doubleValue('compare_at_price');
  late final stock = intValue('stock');
  late final minStock = intValue('min_stock', defaultValue: 5);
  late final weight = doubleValue('weight');
  late final available = boolValue('available', defaultValue: true);
  late final images = listValue('images');
  
  // Relations
  Category? get category {
    return getModel<Category>('category', (data) => Category(data));
  }
  
  // Computed properties
  double? get discount {
    final compare = compareAtPrice.value;
    final current = price.value;
    if (compare == null || compare <= current) return null;
    return ((compare - current) / compare * 100);
  }
  
  String? get discountLabel {
    final d = discount;
    if (d == null) return null;
    return '-${d.toStringAsFixed(0)}%';
  }
  
  bool get inStock => (stock.value ?? 0) > 0;
  bool get lowStock => (stock.value ?? 0) <= minStock.value;
  bool get outOfStock => (stock.value ?? 0) == 0;
  
  // Méthodes
  void decreaseStock(int quantity) {
    final current = stock.value ?? 0;
    stock.set((current - quantity).clamp(0, double.infinity).toInt());
  }
  
  void increaseStock(int quantity) {
    final current = stock.value ?? 0;
    stock.set(current + quantity);
  }
  
  void markAsUnavailable() {
    available.set(false);
  }
}
```

## 💡 Bonnes pratiques

### 1. Utiliser les property wrappers

✅ **Recommandé** :
```dart
late final name = stringValue('name');
```

❌ **À éviter** :
```dart
String get name => getString('name');
set name(String value) => setString('name', value);
```

### 2. Créer des méthodes helpers

```dart
class Article extends DirectusModel {
  // ...
  
  void publish() {
    status.set('published');
    publishDate.set(DateTime.now());
  }
  
  bool isOlderThan(Duration duration) {
    final date = dateCreated;
    if (date == null) return false;
    return DateTime.now().difference(date) > duration;
  }
}
```

### 3. Valider les données

```dart
class User extends DirectusModel {
  // ...
  
  late final email = stringValue('email');
  
  bool get isEmailValid {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.value);
  }
  
  void setEmail(String email) {
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      throw ArgumentError('Email invalide');
    }
    this.email.set(email);
  }
}
```

### 4. Enregistrer les factories au démarrage

```dart
void initModels(DirectusClient directus) {
  // Factories
  DirectusModel.registerFactory('articles', (data) => Article(data));
  DirectusModel.registerFactory('users', (data) => User(data));
  DirectusModel.registerFactory('comments', (data) => Comment(data));
  DirectusModel.registerFactory('products', (data) => Product(data));
  
  // Services (si vous utilisez Active Record)
  Article.registerService(directus.items<Article>('articles'));
  Product.registerService(directus.items<Product>('products'));
}
```

## 🔗 Prochaines étapes

- [**Queries**](05-queries.md) - Système de requêtes et filtres
- [**Relationships**](06-relationships.md) - Deep queries et relations
- [**Core Concepts**](02-core-concepts.md) - Concepts fondamentaux

## 📚 Référence API

- [DirectusModel](api-reference/models/directus-model.md)
- [Property Wrappers](api-reference/models/property-wrappers.md)
- [ItemsService](api-reference/services/items-service.md)

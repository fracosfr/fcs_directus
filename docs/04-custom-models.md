# Modèles personnalisés

Ce guide explique comment créer des modèles Dart pour représenter vos collections Directus.

## Pourquoi des modèles personnalisés ?

Les modèles personnalisés offrent plusieurs avantages :

- ✅ **Type-safety** : Détection des erreurs à la compilation
- ✅ **Autocomplétion** : IDE suggère les propriétés disponibles
- ✅ **Documentation** : Propriétés documentées dans le code
- ✅ **Logique métier** : Getters calculés, validations
- ✅ **Dirty tracking** : Suivi automatique des modifications

## Créer un modèle basique

### Étendre DirectusModel

```dart
class Article extends DirectusModel {
  // Constructeur requis
  Article(super.data);
  
  // Nom de la collection Directus
  @override
  String get itemName => 'articles';
  
  // Propriétés...
}
```

### Constructeur vide

Pour créer de nouveaux items :

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  // Factory pour créer un article vide
  factory Article.empty() => Article({});
  
  @override
  String get itemName => 'articles';
}

// Utilisation
final newArticle = Article.empty();
```

## Property Wrappers (recommandé)

La librairie fournit des property wrappers pour un accès simplifié et type-safe :

### Types primitifs

```dart
class Product extends DirectusModel {
  Product(super.data);
  
  @override
  String get itemName => 'products';
  
  // String
  late final name = stringValue('name');
  late final description = stringValue('description');
  late final sku = stringValue('sku');
  
  // Nombres
  late final price = doubleValue('price');
  late final stock = intValue('stock');
  late final weight = doubleValue('weight');
  
  // Booléen
  late final active = boolValue('active');
  late final featured = boolValue('featured');
  
  // DateTime
  late final createdAt = dateTimeValue('date_created');
  late final updatedAt = dateTimeValue('date_updated');
  
  // JSON (Map ou List)
  late final metadata = jsonValue('metadata');
  late final specifications = jsonValue('specifications');
}
```

### Utilisation des propriétés

```dart
final product = Product({
  'name': 'Laptop',
  'price': 999.99,
  'stock': 10,
  'active': true,
});

// Lecture
print(product.name.value);      // 'Laptop'
print(product.price.value);     // 999.99
print(product.stock.value);     // 10
print(product.active.value);    // true

// Écriture
product.name.set('MacBook Pro');
product.price.set(1299.99);
product.stock.set(5);
product.active.set(false);

// Vérification null
if (product.description.isNull) {
  product.description.set('Default description');
}
```

### Helpers pour IntProperty

```dart
late final stock = intValue('stock');

// Incrémenter / Décrémenter
product.stock.increment();      // +1
product.stock.increment(5);     // +5
product.stock.decrement();      // -1
product.stock.decrement(3);     // -3
```

### Helpers pour BoolProperty

```dart
late final active = boolValue('active');

// Toggle
product.active.toggle();        // Inverse la valeur

// Raccourcis
product.active.setTrue();
product.active.setFalse();
```

### Helpers pour DoubleProperty

```dart
late final price = doubleValue('price');

// Formatage
print(price.toFixed(2));        // "999.99"

// Arrondi
print(price.round());           // 1000
print(price.ceil());            // 1000
print(price.floor());           // 999
```

## Enums type-safe

Convertissez automatiquement les strings Directus en enums Dart :

```dart
enum ProductStatus { draft, active, discontinued, archived }

class Product extends DirectusModel {
  Product(super.data);
  
  @override
  String get itemName => 'products';
  
  late final status = enumValue<ProductStatus>(
    'status',             // Nom du champ
    ProductStatus.draft,  // Valeur par défaut
    ProductStatus.values, // Toutes les valeurs possibles
  );
}

// Utilisation
final product = Product({'status': 'active'});

// Lecture - retourne un enum !
print(product.status.value);       // ProductStatus.active
print(product.status.asString);    // "active"

// Écriture
product.status.set(ProductStatus.discontinued);

// Comparaisons
if (product.status.is_(ProductStatus.active)) {
  print('Produit disponible');
}

if (product.status.isOneOf([ProductStatus.draft, ProductStatus.discontinued])) {
  print('Produit non visible');
}

// Gestion des valeurs invalides
final broken = Product({'status': 'invalid_value'});
print(broken.status.value);        // ProductStatus.draft (valeur par défaut)
```

## Relations

### Many-to-One (M2O)

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  late final title = stringValue('title');
  
  // Relation vers l'auteur
  late final author = modelValue<DirectusUser>('author');
}

// Utilisation
final article = Article(data);

// Accès au modèle lié (si chargé)
final authorModel = article.author.model;
if (authorModel != null) {
  print('Auteur: ${authorModel.firstName.value}');
}

// Vérifier si la relation est chargée
if (article.author.isLoaded) {
  // Données complètes disponibles
}

// Obtenir l'ID seulement
final authorId = article.author.id;

// Définir par ID
article.author.setById('user-uuid');

// Définir avec un modèle
article.author.set(newAuthorModel);

// Supprimer la relation
article.author.clear();
```

### One-to-Many (O2M)

```dart
class Category extends DirectusModel {
  Category(super.data);
  
  @override
  String get itemName => 'categories';
  
  late final name = stringValue('name');
  
  // Liste de produits dans cette catégorie
  late final products = modelListValue<Product>('products');
}

// Utilisation
final category = Category(data);

// Accès à la liste
final productsList = category.products.models;
for (final product in productsList) {
  print(product.name.value);
}

// Nombre d'items
print('${category.products.length} produits');

// Itérer
for (final product in category.products) {
  print(product.name.value);
}

// Vérifier si vide
if (category.products.isEmpty) {
  print('Aucun produit');
}
```

### Many-to-Many (M2M)

Les relations M2M dans Directus utilisent une table de jonction :

```dart
// Structure Directus :
// products --M2M--> products_tags --M2M--> tags

class Product extends DirectusModel {
  Product(super.data);
  
  @override
  String get itemName => 'products';
  
  // Relation M2M via table de jonction
  // 'tags' = nom du champ dans Directus
  // 'tags_id' = champ dans la table de jonction pointant vers tags
  late final tags = modelListValueM2M<Tag>('tags', 'tags_id');
}

// Utilisation
final product = Product(data);

// Accès aux tags
for (final tag in product.tags) {
  print(tag.name.value);
}

// Ajouter un tag
product.tags.add(newTag);

// Supprimer un tag
product.tags.remove(existingTag);

// Remplacer tous les tags
product.tags.set([tag1, tag2, tag3]);

// IDs des items liés
final tagIds = product.tags.ids;
```

## Dirty Tracking

Le système suit automatiquement les modifications :

```dart
final article = Article(await client.items('articles').readOne('uuid'));

// État initial
print(article.isDirty);           // false
print(article.dirtyFields);       // {}

// Modifier des champs
article.title.set('Nouveau titre');
article.status.set('published');

// État après modifications
print(article.isDirty);           // true
print(article.dirtyFields);       // {'title', 'status'}
print(article.isDirtyField('title'));  // true
print(article.isDirtyField('content')); // false

// Obtenir uniquement les modifications
final changes = article.toJsonDirty();
// {'title': 'Nouveau titre', 'status': 'published'}

// Obtenir tout le JSON
final full = article.toJson();
// {id, title, content, status, ...}

// Marquer comme propre (après sauvegarde)
article.markClean();
print(article.isDirty);           // false

// Annuler les modifications
article.title.set('Test');
article.revert();
print(article.title.value);       // Valeur originale
```

## Enregistrement des factories

Pour utiliser les modèles typés avec `itemsOf<T>()` :

```dart
// Au démarrage de l'application
void main() {
  // Enregistrer les factories
  DirectusModel.registerFactory<Article>(Article.new);
  DirectusModel.registerFactory<Product>(Product.new);
  DirectusModel.registerFactory<Category>(Category.new);
  DirectusModel.registerFactory<Tag>(Tag.new);
  
  runApp(MyApp());
}

// Utilisation
final articles = await client.itemsOf<Article>().readMany();
// articles.data est de type List<Article> !
```

## Getters/Setters classiques

Alternative aux property wrappers pour plus de contrôle :

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  // Lecture
  String get title => getString('title');
  String get content => getString('content');
  int get viewCount => getInt('view_count');
  double get rating => getDouble('rating');
  bool get published => getBool('published');
  DateTime? get createdAt => getDateTime('date_created');
  
  // Lecture avec valeur par défaut
  String get status => getString('status', defaultValue: 'draft');
  int get views => getInt('views', defaultValue: 0);
  
  // Écriture
  set title(String value) => setString('title', value);
  set content(String value) => setString('content', value);
  set viewCount(int value) => setInt('view_count', value);
  set rating(double value) => setDouble('rating', value);
  set published(bool value) => setBool('published', value);
}
```

### Méthodes disponibles

| Type | Getter | Setter |
|------|--------|--------|
| String | `getString(key, {defaultValue})` | `setString(key, value)` |
| int | `getInt(key, {defaultValue})` | `setInt(key, value)` |
| double | `getDouble(key, {defaultValue})` | `setDouble(key, value)` |
| bool | `getBool(key, {defaultValue})` | `setBool(key, value)` |
| DateTime | `getDateTime(key)` | `setDateTime(key, value)` |
| List | `getList<T>(key)` | `setList(key, value)` |
| Map | `getMap(key)` | `setMap(key, value)` |

## Propriétés calculées

Ajoutez de la logique métier à vos modèles :

```dart
class Product extends DirectusModel {
  Product(super.data);
  
  @override
  String get itemName => 'products';
  
  late final price = doubleValue('price');
  late final discount = doubleValue('discount');
  late final stock = intValue('stock');
  late final status = enumValue<ProductStatus>('status', ...);
  
  // Propriétés calculées
  double get finalPrice => price.value * (1 - (discount.value ?? 0) / 100);
  bool get inStock => stock.value > 0;
  bool get isOnSale => (discount.value ?? 0) > 0;
  bool get isAvailable => status.is_(ProductStatus.active) && inStock;
  
  // Méthodes utilitaires
  void applyDiscount(double percent) {
    discount.set(percent);
  }
  
  bool canOrder(int quantity) {
    return stock.value >= quantity;
  }
}
```

## Modèle complet (exemple)

```dart
enum ArticleStatus { draft, review, published, archived }

class Article extends DirectusModel {
  Article(super.data);
  
  factory Article.empty() => Article({});
  
  @override
  String get itemName => 'articles';
  
  // === Propriétés basiques ===
  late final title = stringValue('title');
  late final slug = stringValue('slug');
  late final content = stringValue('content');
  late final excerpt = stringValue('excerpt');
  late final viewCount = intValue('view_count');
  late final featured = boolValue('featured');
  late final publishedAt = dateTimeValue('published_at');
  late final createdAt = dateTimeValue('date_created');
  late final updatedAt = dateTimeValue('date_updated');
  
  // === Enum ===
  late final status = enumValue<ArticleStatus>(
    'status',
    ArticleStatus.draft,
    ArticleStatus.values,
  );
  
  // === Relations ===
  late final author = modelValue<DirectusUser>('author');
  late final category = modelValue<Category>('category');
  late final tags = modelListValueM2M<Tag>('tags', 'tags_id');
  late final featuredImage = modelValue<DirectusFile>('featured_image');
  
  // === Propriétés calculées ===
  bool get isPublished => status.is_(ArticleStatus.published);
  bool get canPublish => title.value.isNotEmpty && content.value.isNotEmpty;
  String get authorName => author.model?.fullName ?? 'Unknown';
  
  // === Méthodes ===
  void publish() {
    if (canPublish) {
      status.set(ArticleStatus.published);
      publishedAt.set(DateTime.now());
    }
  }
  
  void archive() {
    status.set(ArticleStatus.archived);
  }
  
  void incrementViews() {
    viewCount.increment();
  }
}
```

## Bonnes pratiques

### 1. Un fichier par modèle

```
lib/
  models/
    article.dart
    category.dart
    product.dart
    tag.dart
```

### 2. Enregistrer les factories au démarrage

```dart
void setupDirectus() {
  DirectusModel.registerFactory<Article>(Article.new);
  DirectusModel.registerFactory<Category>(Category.new);
  // etc.
}
```

### 3. Utiliser les property wrappers

Plus concis et avec helpers intégrés.

### 4. Documenter les modèles

```dart
/// Représente un article du blog.
///
/// Les articles passent par un workflow de publication :
/// draft → review → published → archived
class Article extends DirectusModel {
  /// Titre de l'article, affiché en page.
  late final title = stringValue('title');
  
  /// Contenu en Markdown.
  late final content = stringValue('content');
  // ...
}
```

### 5. Utiliser toJsonDirty() pour les updates

```dart
// Envoie uniquement les champs modifiés
await client.itemsOf<Article>().updateOne(
  article.id!,
  article.toJsonDirty(),
);
```

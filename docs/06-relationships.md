# Relationships & Deep Queries

Guide complet des relations et requêtes profondes (deep queries) dans fcs_directus.

## 📖 Introduction

Les **deep queries** permettent de charger des relations imbriquées en une seule requête, évitant ainsi le problème N+1 et optimisant les performances.

## 🎯 Types de relations

### Many-to-One (M2O)

Une entité appartient à une autre (ex: un article a un auteur).

```
articles
  ├── id
  ├── title
  └── author (FK → users.id)

users
  ├── id
  └── name
```

### One-to-Many (O2M)

Une entité a plusieurs autres entités (ex: un article a plusieurs commentaires).

```
articles
  ├── id
  └── title

comments
  ├── id
  ├── content
  └── article (FK → articles.id)
```

### Many-to-Many (M2M)

Plusieurs entités reliées via une table de jonction (ex: articles ↔ tags).

```
articles          articles_tags         tags
  ├── id   ←───    ├── id           ───→  ├── id
  └── title        ├── articles_id        └── name
                   └── tags_id
```

## 🔧 Deep Queries

### Syntaxe de base

```dart
import 'package:fcs_directus/fcs_directus.dart';

final result = await directus.items('articles').readMany(
  query: QueryParameters(
    deep: Deep({
      'author': DeepQuery(),
      'comments': DeepQuery(),
    }),
  ),
);
```

### DeepQuery avec options

```dart
Deep({
  'author': DeepQuery()
    ..fields(['id', 'name', 'email'])
    ..filter({'status': {'_eq': 'active'}}),
    
  'comments': DeepQuery()
    ..limit(10)
    ..sort(['-date_created'])
    ..filter({'approved': {'_eq': true}}),
})
```

## 📝 Many-to-One (M2O)

### Charger une relation M2O

```dart
// Article → Author (M2O)
final articles = await directus.items('articles').readMany(
  query: QueryParameters(
    deep: Deep({
      'author': DeepQuery().fields(['id', 'name', 'avatar']),
    }),
  ),
);

// Accès aux données
for (final article in articles.data ?? []) {
  print('Article: ${article['title']}');
  print('Auteur: ${article['author']['name']}');
}
```

### Dans un modèle

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  late final title = stringValue('title');
  
  // Relation M2O
  User? get author => getModel<User>('author', (data) => User(data));
}

// Utilisation
final article = articles.data?.first;
print('Auteur: ${article.author?.name.value}');
```

## 📚 One-to-Many (O2M)

### Charger une relation O2M

```dart
// Article → Comments (O2M)
final articles = await directus.items('articles').readMany(
  query: QueryParameters(
    deep: Deep({
      'comments': DeepQuery()
        ..limit(5)
        ..sort(['-date_created'])
        ..filter({'approved': {'_eq': true}}),
    }),
  ),
);
```

### Avec modèle

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  late final title = stringValue('title');
  
  // Relation O2M
  List<Comment> get comments {
    return getModelList<Comment>('comments', (data) => Comment(data));
  }
  
  int get commentCount => comments.length;
}

class Comment extends DirectusModel {
  Comment(super.data);
  
  @override
  String get itemName => 'comments';
  
  late final content = stringValue('content');
  late final approved = boolValue('approved');
  late final dateCreated = dateTimeValue('date_created');
}
```

## 🔗 Many-to-Many (M2M)

### Charger une relation M2M

```dart
// Articles ↔ Tags (M2M via articles_tags)
final articles = await directus.items('articles').readMany(
  query: QueryParameters(
    deep: Deep({
      'tags': DeepQuery()
        ..fields(['tags_id.*']), // * = tous les champs du tag
    }),
  ),
);
```

### Structure des données M2M

```dart
{
  'id': '1',
  'title': 'Mon article',
  'tags': [
    {
      'id': '1',
      'articles_id': '1',
      'tags_id': {
        'id': '10',
        'name': 'Flutter',
        'slug': 'flutter',
      }
    },
    {
      'id': '2',
      'articles_id': '1',
      'tags_id': {
        'id': '11',
        'name': 'Dart',
        'slug': 'dart',
      }
    }
  ]
}
```

### Dans un modèle

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  // Relation M2M
  List<Tag> get tags {
    final junctions = getList('tags', defaultValue: []);
    return junctions
        .map((j) => j['tags_id'])
        .where((t) => t is Map<String, dynamic>)
        .map((data) => Tag(data as Map<String, dynamic>))
        .toList();
  }
  
  List<String> get tagNames => tags.map((t) => t.name.value).toList();
}

class Tag extends DirectusModel {
  Tag(super.data);
  
  @override
  String get itemName => 'tags';
  
  late final name = stringValue('name');
  late final slug = stringValue('slug');
}
```

## 🏗️ Relations imbriquées

### Plusieurs niveaux

```dart
// Article → Author → Company
final articles = await directus.items('articles').readMany(
  query: QueryParameters(
    deep: Deep({
      'author': DeepQuery()
        ..fields(['id', 'name'])
        ..deep({
          'company': DeepQuery().fields(['id', 'name', 'logo']),
        }),
    }),
  ),
);

// Accès
final article = articles.data?.first;
print('Article: ${article['title']}');
print('Auteur: ${article['author']['name']}');
print('Entreprise: ${article['author']['company']['name']}');
```

### Hiérarchie complexe

```dart
// Post avec auteur, commentaires (avec auteurs), et tags
final posts = await directus.items('posts').readMany(
  query: QueryParameters(
    deep: Deep({
      // Auteur du post
      'author': DeepQuery().fields(['id', 'name', 'avatar']),
      
      // Commentaires du post
      'comments': DeepQuery()
        ..limit(10)
        ..sort(['-date_created'])
        ..fields(['id', 'content', 'date_created'])
        ..deep({
          // Auteur de chaque commentaire
          'author': DeepQuery().fields(['id', 'name']),
        }),
      
      // Tags du post (M2M)
      'tags': DeepQuery().fields(['tags_id.*']),
    }),
  ),
);
```

## 🎨 Filtrer les relations

### Filtrer une relation O2M

```dart
// Articles avec seulement les commentaires approuvés
final articles = await directus.items('articles').readMany(
  query: QueryParameters(
    deep: Deep({
      'comments': DeepQuery()
        ..filter({'approved': {'_eq': true}})
        ..sort(['-date_created'])
        ..limit(5),
    }),
  ),
);
```

### Filtrer sur l'existence d'une relation

```dart
// Articles qui ont au moins un commentaire approuvé
final articles = await directus.items('articles').readMany(
  query: QueryParameters(
    filter: Filter.some('comments').field('approved').equals(true),
  ),
);

// Articles sans commentaire spam
final articles = await directus.items('articles').readMany(
  query: QueryParameters(
    filter: Filter.none('comments').field('spam').equals(true),
  ),
);
```

## 📊 Limiter la profondeur

### DeepMaxDepth

Pour limiter la profondeur des relations :

```dart
// Maximum 2 niveaux de profondeur
final result = await directus.items('articles').readMany(
  query: QueryParameters(
    deep: DeepMaxDepth(2),
  ),
);
```

### Utilisation

```dart
// Charge toutes les relations jusqu'à 3 niveaux
// Article → Author → Company → Address
DeepMaxDepth(3)

// Équivalent à:
Deep({
  '*': DeepQuery().deep({
    '*': DeepQuery().deep({
      '*': DeepQuery(),
    }),
  }),
})
```

## 🚀 Exemples complets

### Blog avec auteur et commentaires

```dart
class BlogService {
  final DirectusClient directus;
  
  BlogService(this.directus);
  
  Future<List<Article>> getPublishedArticles() async {
    final result = await directus.items('articles').readMany(
      query: QueryParameters(
        filter: Filter.and([
          Filter.field('status').equals('published'),
          Filter.field('publish_date').lessThanOrEqual(
            DateTime.now().toIso8601String(),
          ),
        ]),
        sort: ['-publish_date'],
        limit: 10,
        deep: Deep({
          'author': DeepQuery().fields([
            'id',
            'first_name',
            'last_name',
            'avatar',
          ]),
          'comments': DeepQuery()
            ..filter({'approved': {'_eq': true}})
            ..sort(['-date_created'])
            ..limit(5)
            ..fields(['id', 'content', 'date_created'])
            ..deep({
              'author': DeepQuery().fields(['id', 'first_name']),
            }),
        }),
      ),
    );
    
    return result.data
        ?.map((data) => Article(data))
        .toList() ?? [];
  }
}
```

### E-commerce avec relations

```dart
class ProductService {
  final DirectusClient directus;
  
  ProductService(this.directus);
  
  Future<Product?> getProductDetails(String productId) async {
    final result = await directus.items('products').readOne(
      id: productId,
      query: QueryParameters(
        deep: Deep({
          // Catégorie du produit
          'category': DeepQuery().fields(['id', 'name', 'slug']),
          
          // Variantes du produit
          'variants': DeepQuery()
            ..filter({'available': {'_eq': true}})
            ..fields(['id', 'name', 'price', 'stock']),
          
          // Images du produit
          'images': DeepQuery()
            ..sort(['sort'])
            ..fields(['directus_files_id.*']),
          
          // Avis clients
          'reviews': DeepQuery()
            ..filter({'published': {'_eq': true}})
            ..sort(['-date_created'])
            ..limit(10)
            ..fields(['id', 'rating', 'comment', 'date_created'])
            ..deep({
              'user': DeepQuery().fields(['id', 'first_name']),
            }),
        }),
      ),
    );
    
    return result.data != null ? Product(result.data!) : null;
  }
}
```

### Hiérarchie de catégories

```dart
// Catégories avec sous-catégories
final categories = await directus.items('categories').readMany(
  query: QueryParameters(
    filter: {'parent': {'_null': true}}, // Seulement les catégories racines
    deep: Deep({
      'children': DeepQuery()
        ..sort(['sort', 'name'])
        ..deep({
          'children': DeepQuery() // Sous-sous-catégories
            ..sort(['sort', 'name']),
        }),
    }),
  ),
);
```

## 💡 Bonnes pratiques

### 1. Limiter les champs chargés

✅ **Bon** :
```dart
Deep({
  'author': DeepQuery().fields(['id', 'name', 'avatar']),
})
```

❌ **À éviter** :
```dart
Deep({
  'author': DeepQuery(), // Charge tous les champs
})
```

### 2. Paginer les relations O2M

```dart
Deep({
  'comments': DeepQuery()
    ..limit(10)
    ..offset(0),
})
```

### 3. Filtrer les relations inutiles

```dart
// Seulement les commentaires approuvés
Deep({
  'comments': DeepQuery()
    ..filter({'approved': {'_eq': true}}),
})
```

### 4. Éviter les deep queries trop profondes

❌ **À éviter** (peut être très lent) :
```dart
DeepMaxDepth(10) // Trop profond!
```

✅ **Bon** :
```dart
// Charger uniquement ce qui est nécessaire
Deep({
  'author': DeepQuery().fields(['id', 'name']),
  'comments': DeepQuery().limit(5),
})
```

### 5. Utiliser des modèles typés

```dart
class Article extends DirectusModel {
  // Définir les relations dans le modèle
  User? get author => getModel<User>('author', (data) => User(data));
  List<Comment> get comments => getModelList<Comment>('comments', (data) => Comment(data));
}
```

## ⚠️ Points d'attention

- Les deep queries peuvent impacter les performances si mal utilisées
- Toujours limiter les champs et le nombre d'items dans les relations O2M
- Préférer plusieurs requêtes simples à une deep query très complexe
- Attention à la structure des données M2M (table de jonction)

## 🔗 Prochaines étapes

- [**Aggregations**](07-aggregations.md) - Fonctions d'agrégation
- [**Queries**](05-queries.md) - Système de requêtes et filtres
- [**Models**](04-models.md) - Créer des modèles personnalisés

## 📚 Référence API

- [DirectusDeep](api-reference/models/directus-deep.md)
- [DeepQuery](api-reference/models/directus-deep.md#deepquery)
- [ItemsService](api-reference/services/items-service.md)

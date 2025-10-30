# Queries

Guide complet du système de requêtes et filtres type-safe de fcs_directus.

## 📝 QueryParameters

`QueryParameters` est la classe unifiée pour construire toutes vos requêtes Directus.

### Structure de base

```dart
final query = QueryParameters(
  filter: {...},        // Filtres
  sort: [...],          // Tri
  limit: 20,            // Pagination: nombre d'items
  offset: 0,            // Pagination: décalage
  page: 1,              // Pagination alternative
  fields: [...],        // Sélection de champs
  deep: {...},          // Relations (deep queries)
  search: '...',        // Recherche full-text
  aggregate: {...},     // Agrégations
  groupBy: [...],       // Groupement
  meta: '*',            // Métadonnées (count, etc.)
);

final result = await directus.items('articles').readMany(query: query);
```

## 🔍 Filtres

### Filter type-safe

fcs_directus fournit une API type-safe pour les filtres :

```dart
import 'package:fcs_directus/fcs_directus.dart';

// Filtre simple
final filter = Filter.field('status').equals('published');

// Utilisation
final result = await directus.items('articles').readMany(
  query: QueryParameters(filter: filter),
);
```

### Opérateurs de comparaison

```dart
// Égal (=)
Filter.field('status').equals('published')
Filter.field('price').equals(99.99)

// Différent (≠)
Filter.field('status').notEquals('draft')

// Inférieur (<)
Filter.field('price').lessThan(100)

// Inférieur ou égal (≤)
Filter.field('price').lessThanOrEqual(100)

// Supérieur (>)
Filter.field('stock').greaterThan(0)

// Supérieur ou égal (≥)
Filter.field('price').greaterThanOrEqual(50)

// Entre (BETWEEN)
Filter.field('price').between(50, 100)
```

### Opérateurs de chaîne

```dart
// Contient
Filter.field('title').contains('Flutter')

// Ne contient pas
Filter.field('title').notContains('spam')

// Commence par
Filter.field('email').startsWith('admin')

// Finit par
Filter.field('email').endsWith('@example.com')

// Insensible à la casse
Filter.field('name').containsInsensitive('john')
Filter.field('name').startsWithInsensitive('j')
Filter.field('name').endsWithInsensitive('son')
```

### Opérateurs NULL

```dart
// Est NULL
Filter.field('deleted_at').isNull()

// N'est pas NULL
Filter.field('published_at').isNotNull()

// Est vide (NULL ou chaîne vide ou tableau vide)
Filter.field('description').isEmpty()

// N'est pas vide
Filter.field('description').isNotEmpty()
```

### Opérateurs de liste

```dart
// Dans la liste (IN)
Filter.field('status').inList(['published', 'featured'])

// Pas dans la liste (NOT IN)
Filter.field('status').notInList(['draft', 'archived'])
```

### Opérateurs logiques

#### AND (ET)

Tous les filtres doivent être vrais :

```dart
Filter.and([
  Filter.field('status').equals('published'),
  Filter.field('stock').greaterThan(0),
  Filter.field('price').lessThan(100),
])
```

#### OR (OU)

Au moins un filtre doit être vrai :

```dart
Filter.or([
  Filter.field('featured').equals(true),
  Filter.field('category').equals('hot-deals'),
])
```

#### Combinaisons complexes

```dart
// (status = 'published' AND stock > 0) OR featured = true
Filter.or([
  Filter.and([
    Filter.field('status').equals('published'),
    Filter.field('stock').greaterThan(0),
  ]),
  Filter.field('featured').equals(true),
])
```

### Filtres sur relations

```dart
// Filtre simple sur relation M2O
Filter.field('author.name').equals('John Doe')

// Filtre sur relation avec opérateur _some (O2M)
Filter.some('comments').field('approved').equals(true)

// Filtre sur relation avec opérateur _none (O2M)
Filter.none('comments').field('spam').equals(true)
```

### Mode Map (legacy)

Vous pouvez aussi utiliser des Maps directement :

```dart
final query = QueryParameters(
  filter: {
    'status': {'_eq': 'published'},
    'price': {'_lt': 100},
  },
);
```

## 📊 Tri (Sort)

```dart
// Tri croissant
QueryParameters(sort: ['title'])

// Tri décroissant (préfixe -)
QueryParameters(sort: ['-date_created'])

// Tri multiple
QueryParameters(sort: ['status', '-date_created', 'title'])

// Tri sur relation
QueryParameters(sort: ['author.name'])
```

## 📄 Pagination

### Limite et offset

```dart
// 10 premiers items
QueryParameters(limit: 10)

// Items 11-20
QueryParameters(limit: 10, offset: 10)

// Page 3 (items 21-30)
QueryParameters(limit: 10, offset: 20)
```

### Pagination par page

```dart
// Page 1 (items 1-20)
QueryParameters(limit: 20, page: 1)

// Page 2 (items 21-40)
QueryParameters(limit: 20, page: 2)
```

### Exemple de pagination complète

```dart
class PaginatedList {
  Future<void> loadPage(int page) async {
    final result = await directus.items('articles').readMany(
      query: QueryParameters(
        limit: 20,
        page: page,
        meta: '*', // Inclure le count total
      ),
    );
    
    final items = result.data ?? [];
    final total = result.meta?.totalCount ?? 0;
    final totalPages = (total / 20).ceil();
    
    print('Page $page/$totalPages');
    print('${items.length} items sur $total au total');
  }
}
```

## 🎯 Sélection de champs (Fields)

```dart
// Sélectionner des champs spécifiques
QueryParameters(fields: ['id', 'title', 'status'])

// Inclure des champs de relations
QueryParameters(fields: ['id', 'title', 'author.name', 'author.email'])

// Tous les champs (*)
QueryParameters(fields: ['*'])

// Tous les champs + champs de relation
QueryParameters(fields: ['*', 'author.name'])
```

### Optimisation des performances

✅ **Bon** (charge uniquement ce qui est nécessaire) :
```dart
QueryParameters(fields: ['id', 'title'])
```

❌ **À éviter** (charge tous les champs inutilement) :
```dart
QueryParameters() // Charge tout par défaut
```

## 🔎 Recherche full-text

```dart
// Recherche dans tous les champs indexés
QueryParameters(search: 'flutter dart')

// Combiné avec des filtres
QueryParameters(
  search: 'tutorial',
  filter: Filter.field('status').equals('published'),
)
```

## 📈 Métadonnées

```dart
// Inclure le count total
QueryParameters(meta: '*')

// Le résultat inclut meta
final result = await directus.items('articles').readMany(
  query: QueryParameters(meta: '*'),
);

print('Total: ${result.meta?.totalCount}');
print('Filter count: ${result.meta?.filterCount}');
```

## 🎨 Exemples complets

### E-commerce : Produits disponibles

```dart
final products = await directus.items('products').readMany(
  query: QueryParameters(
    filter: Filter.and([
      Filter.field('status').equals('published'),
      Filter.field('stock').greaterThan(0),
      Filter.field('price').between(10, 1000),
    ]),
    sort: ['-featured', 'price'],
    limit: 20,
    fields: ['id', 'name', 'price', 'stock', 'images'],
  ),
);
```

### Blog : Articles récents publiés

```dart
final articles = await directus.items('articles').readMany(
  query: QueryParameters(
    filter: Filter.and([
      Filter.field('status').equals('published'),
      Filter.field('publish_date').lessThanOrEqual(DateTime.now().toIso8601String()),
    ]),
    sort: ['-publish_date'],
    limit: 10,
    fields: ['id', 'title', 'excerpt', 'author.name', 'publish_date'],
  ),
);
```

### Recherche avec filtres multiples

```dart
final results = await directus.items('articles').readMany(
  query: QueryParameters(
    search: searchQuery,
    filter: Filter.and([
      Filter.field('status').equals('published'),
      Filter.or([
        Filter.field('category').equals(selectedCategory),
        Filter.field('featured').equals(true),
      ]),
    ]),
    sort: ['-relevance', '-date_created'],
    limit: 50,
    offset: page * 50,
    meta: '*',
  ),
);
```

### Produits en promotion

```dart
final deals = await directus.items('products').readMany(
  query: QueryParameters(
    filter: Filter.and([
      Filter.field('compare_at_price').isNotNull(),
      Filter.field('price').lessThan(Filter.field('compare_at_price')),
      Filter.field('stock').greaterThan(0),
    ]),
    sort: ['-discount_percentage'],
    limit: 20,
  ),
);
```

### Articles avec commentaires approuvés

```dart
final articles = await directus.items('articles').readMany(
  query: QueryParameters(
    filter: Filter.and([
      Filter.field('status').equals('published'),
      Filter.some('comments').field('approved').equals(true),
    ]),
    fields: ['id', 'title', 'comments.content', 'comments.author'],
  ),
);
```

## 💡 Bonnes pratiques

### 1. Utiliser l'API type-safe

✅ **Recommandé** :
```dart
Filter.field('price').greaterThan(100)
```

❌ **À éviter** :
```dart
{'price': {'_gt': 100}}
```

### 2. Limiter les champs retournés

```dart
// ✅ Bon
QueryParameters(fields: ['id', 'title'])

// ❌ Charge tout inutilement
QueryParameters()
```

### 3. Paginer les grandes collections

```dart
// ✅ Pagination
QueryParameters(limit: 20, page: currentPage)

// ❌ Charge tout (peut être très lent)
await directus.items('articles').readMany()
```

### 4. Combiner filter avec sort

```dart
QueryParameters(
  filter: Filter.field('status').equals('published'),
  sort: ['-date_created'],
  limit: 10,
)
```

### 5. Utiliser meta pour les totaux

```dart
final result = await directus.items('articles').readMany(
  query: QueryParameters(
    limit: 20,
    meta: '*',
  ),
);

final totalPages = ((result.meta?.totalCount ?? 0) / 20).ceil();
```

## 🔗 Prochaines étapes

- [**Relationships**](06-relationships.md) - Deep queries et relations
- [**Aggregations**](07-aggregations.md) - Fonctions d'agrégation
- [**Models**](04-models.md) - Créer des modèles personnalisés

## 📚 Référence API

- [DirectusFilter](api-reference/models/directus-filter.md)
- [QueryParameters](api-reference/models/query-parameters.md)
- [ItemsService](api-reference/services/items-service.md)

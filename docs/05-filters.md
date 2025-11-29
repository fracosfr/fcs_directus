# Filtres type-safe

Ce guide explique comment utiliser le système de filtres pour construire des requêtes complexes sans manipuler de JSON.

## Introduction

Le système de filtres traduit automatiquement des appels de méthodes en JSON compatible avec l'API Directus :

```dart
// Code Dart
Filter.field('status').equals('published')

// JSON généré
{"status": {"_eq": "published"}}
```

## Filtres de champs

### Création d'un filtre

```dart
// Méthode statique
final filter = Filter.field('nom_du_champ');

// Puis appliquer un opérateur
final filter = Filter.field('status').equals('published');
```

### Opérateurs de comparaison

```dart
// Égal
Filter.field('status').equals('published')

// Différent
Filter.field('status').notEquals('draft')

// Inférieur
Filter.field('price').lessThan(100)

// Inférieur ou égal
Filter.field('price').lessThanOrEqual(100)

// Supérieur
Filter.field('price').greaterThan(50)

// Supérieur ou égal
Filter.field('stock').greaterThanOrEqual(10)
```

### Opérateurs de collection

```dart
// Dans une liste
Filter.field('category').inList(['electronics', 'computers', 'accessories'])

// Pas dans une liste
Filter.field('status').notInList(['archived', 'deleted'])

// Entre deux valeurs (inclusif)
Filter.field('price').between(100, 500)

// Pas entre deux valeurs
Filter.field('date').notBetween('2024-01-01', '2024-06-30')
```

### Opérateurs de texte

```dart
// Contient
Filter.field('title').contains('flutter')

// Ne contient pas
Filter.field('description').notContains('deprecated')

// Commence par
Filter.field('sku').startsWith('PRD-')

// Se termine par
Filter.field('email').endsWith('@company.com')

// Version insensible à la casse
Filter.field('title').containsInsensitive('FLUTTER')
Filter.field('name').startsWithInsensitive('john')
Filter.field('domain').endsWithInsensitive('.COM')
```

### Opérateurs NULL et vide

```dart
// Est NULL
Filter.field('deleted_at').isNull()

// N'est pas NULL
Filter.field('published_at').isNotNull()

// Est vide (string vide ou array vide)
Filter.field('description').isEmpty()

// N'est pas vide
Filter.field('tags').isNotEmpty()
```

### Expressions régulières

```dart
// Correspond à une regex
Filter.field('email').regex(r'^[a-z]+@company\.com$')
```

## Combinaison de filtres

### AND (et logique)

Tous les filtres doivent être vrais :

```dart
final filter = Filter.and([
  Filter.field('status').equals('published'),
  Filter.field('price').greaterThan(0),
  Filter.field('stock').greaterThan(0),
]);

// Équivalent JSON :
// {
//   "_and": [
//     {"status": {"_eq": "published"}},
//     {"price": {"_gt": 0}},
//     {"stock": {"_gt": 0}}
//   ]
// }
```

### OR (ou logique)

Au moins un filtre doit être vrai :

```dart
final filter = Filter.or([
  Filter.field('featured').equals(true),
  Filter.field('discount').greaterThan(0),
  Filter.field('bestseller').equals(true),
]);
```

### Combinaisons imbriquées

```dart
final filter = Filter.and([
  // Doit être publié
  Filter.field('status').equals('published'),
  
  // ET (populaire OU en promo)
  Filter.or([
    Filter.field('view_count').greaterThan(1000),
    Filter.field('discount').greaterThan(20),
  ]),
  
  // ET en stock
  Filter.field('stock').greaterThan(0),
]);
```

## Filtres sur relations

### Notation pointée

Filtrez sur les champs de relations en utilisant la notation pointée :

```dart
// Filtre sur le rôle de l'auteur
Filter.field('author.role.name').equals('admin')

// Filtre sur la catégorie parente
Filter.field('category.parent.slug').equals('electronics')

// Filtre sur l'avatar de l'utilisateur
Filter.field('author.avatar.type').contains('image')
```

### Filtres relationnels (some/none)

Pour les relations O2M et M2M :

```dart
// Au moins un tag correspond
final filter = Filter.some('tags', 
  Filter.field('name').equals('featured')
);

// Aucun commentaire ne correspond
final filter = Filter.none('comments',
  Filter.field('spam').equals(true)
);
```

### Relation avec filtre complexe

```dart
// Produits avec au moins un avis positif
final filter = Filter.relation('reviews').some(
  Filter.and([
    Filter.field('rating').greaterThanOrEqual(4),
    Filter.field('verified').equals(true),
  ]),
);
```

## Filtres géographiques

Pour les champs de type géométrie :

```dart
// Intersecte une géométrie
Filter.field('location').intersects(geoJsonGeometry)

// N'intersecte pas
Filter.field('zone').notIntersects(geoJsonGeometry)

// Dans une bounding box
Filter.field('position').intersectsBBox({
  'type': 'Polygon',
  'coordinates': [[[minLng, minLat], [maxLng, minLat], ...]]
})
```

## Utilisation avec QueryParameters

### Requête simple

```dart
final response = await client.items('products').readMany(
  query: QueryParameters(
    filter: Filter.field('status').equals('active'),
  ),
);
```

### Requête complexe

```dart
final response = await client.items('products').readMany(
  query: QueryParameters(
    filter: Filter.and([
      Filter.field('status').equals('active'),
      Filter.field('price').between(50, 500),
      Filter.or([
        Filter.field('category').equals('electronics'),
        Filter.field('featured').equals(true),
      ]),
    ]),
    fields: ['id', 'name', 'price', 'category.name'],
    sort: ['-price'],
    limit: 20,
  ),
);
```

## Filtres dynamiques

### Construire des filtres conditionnellement

```dart
List<Filter> buildFilters({
  String? category,
  double? minPrice,
  double? maxPrice,
  bool? onlyInStock,
}) {
  final filters = <Filter>[];
  
  // Toujours actif
  filters.add(Filter.field('status').equals('active'));
  
  // Conditionnels
  if (category != null) {
    filters.add(Filter.field('category').equals(category));
  }
  
  if (minPrice != null) {
    filters.add(Filter.field('price').greaterThanOrEqual(minPrice));
  }
  
  if (maxPrice != null) {
    filters.add(Filter.field('price').lessThanOrEqual(maxPrice));
  }
  
  if (onlyInStock == true) {
    filters.add(Filter.field('stock').greaterThan(0));
  }
  
  return filters;
}

// Utilisation
final filters = buildFilters(
  category: 'electronics',
  minPrice: 100,
  onlyInStock: true,
);

final response = await client.items('products').readMany(
  query: QueryParameters(
    filter: filters.length == 1 ? filters.first : Filter.and(filters),
  ),
);
```

### Classe de recherche

```dart
class ProductSearch {
  String? keyword;
  String? category;
  double? minPrice;
  double? maxPrice;
  bool onlyInStock = false;
  bool onlyFeatured = false;
  
  Filter? toFilter() {
    final filters = <Filter>[];
    
    if (keyword != null && keyword!.isNotEmpty) {
      filters.add(Filter.field('name').containsInsensitive(keyword!));
    }
    
    if (category != null) {
      filters.add(Filter.field('category').equals(category!));
    }
    
    if (minPrice != null) {
      filters.add(Filter.field('price').greaterThanOrEqual(minPrice!));
    }
    
    if (maxPrice != null) {
      filters.add(Filter.field('price').lessThanOrEqual(maxPrice!));
    }
    
    if (onlyInStock) {
      filters.add(Filter.field('stock').greaterThan(0));
    }
    
    if (onlyFeatured) {
      filters.add(Filter.field('featured').equals(true));
    }
    
    if (filters.isEmpty) return null;
    if (filters.length == 1) return filters.first;
    return Filter.and(filters);
  }
}
```

## Mise à jour et suppression avec filtres

### Mise à jour par filtre

```dart
// Mettre à jour tous les produits d'une catégorie
await client.items('products').updateMany(
  filter: Filter.field('category').equals('old-category'),
  data: {'category': 'new-category'},
);
```

### Suppression par filtre

```dart
// Supprimer les articles archivés anciens
await client.items('articles').deleteMany(
  filter: Filter.and([
    Filter.field('status').equals('archived'),
    Filter.field('date_updated').lessThan('2023-01-01'),
  ]),
);
```

## Tableau des opérateurs

| Opérateur | Méthode | Description |
|-----------|---------|-------------|
| `_eq` | `equals(value)` | Égal à |
| `_neq` | `notEquals(value)` | Différent de |
| `_lt` | `lessThan(value)` | Inférieur à |
| `_lte` | `lessThanOrEqual(value)` | Inférieur ou égal à |
| `_gt` | `greaterThan(value)` | Supérieur à |
| `_gte` | `greaterThanOrEqual(value)` | Supérieur ou égal à |
| `_in` | `inList(values)` | Dans la liste |
| `_nin` | `notInList(values)` | Pas dans la liste |
| `_between` | `between(min, max)` | Entre deux valeurs |
| `_nbetween` | `notBetween(min, max)` | Pas entre deux valeurs |
| `_contains` | `contains(text)` | Contient (sensible) |
| `_ncontains` | `notContains(text)` | Ne contient pas |
| `_starts_with` | `startsWith(text)` | Commence par |
| `_nstarts_with` | `notStartsWith(text)` | Ne commence pas par |
| `_ends_with` | `endsWith(text)` | Se termine par |
| `_nends_with` | `notEndsWith(text)` | Ne se termine pas par |
| `_icontains` | `containsInsensitive(text)` | Contient (insensible) |
| `_istarts_with` | `startsWithInsensitive(text)` | Commence par (insensible) |
| `_iends_with` | `endsWithInsensitive(text)` | Se termine par (insensible) |
| `_null` | `isNull()` | Est NULL |
| `_nnull` | `isNotNull()` | N'est pas NULL |
| `_empty` | `isEmpty()` | Est vide |
| `_nempty` | `isNotEmpty()` | N'est pas vide |
| `_regex` | `regex(pattern)` | Correspond à la regex |
| `_intersects` | `intersects(geo)` | Intersecte (géo) |
| `_nintersects` | `notIntersects(geo)` | N'intersecte pas |
| `_intersects_bbox` | `intersectsBBox(geo)` | Dans bounding box |
| `_nintersects_bbox` | `notIntersectsBBox(geo)` | Pas dans bounding box |

## Bonnes pratiques

### 1. Préférer les filtres aux boucles client

```dart
// ❌ Éviter : charge tout puis filtre côté client
final all = await client.items('products').readMany();
final filtered = all.data.where((p) => p['price'] > 100);

// ✅ Préférer : filtre côté serveur
final filtered = await client.items('products').readMany(
  query: QueryParameters(
    filter: Filter.field('price').greaterThan(100),
  ),
);
```

### 2. Utiliser des helpers pour les filtres récurrents

```dart
class ProductFilters {
  static Filter active() => Filter.field('status').equals('active');
  static Filter inStock() => Filter.field('stock').greaterThan(0);
  static Filter featured() => Filter.field('featured').equals(true);
  static Filter inCategory(String cat) => Filter.field('category').equals(cat);
  
  static Filter available() => Filter.and([active(), inStock()]);
}

// Utilisation
final filter = Filter.and([
  ProductFilters.available(),
  ProductFilters.featured(),
]);
```

### 3. Documenter les filtres complexes

```dart
/// Filtre les produits éligibles à la livraison gratuite :
/// - Actifs et en stock
/// - Prix supérieur à 50€ OU abonnement premium
/// - Poids inférieur à 30kg
Filter freeShippingEligible() => Filter.and([
  ProductFilters.available(),
  Filter.or([
    Filter.field('price').greaterThanOrEqual(50),
    Filter.field('seller.premium').equals(true),
  ]),
  Filter.field('weight').lessThan(30),
]);
```

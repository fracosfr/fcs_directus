# Guide des Filtres - Filter API

## 🎯 Vue d'ensemble

Le système de filtres type-safe permet de construire des requêtes Directus complexes sans avoir à connaître les opérateurs internes (`_eq`, `_neq`, `_and`, etc.).

## ✨ Avantages

- ✅ **Type-safe** : Erreurs détectées à la compilation
- ✅ **Autocomplétion** : L'IDE suggère les méthodes disponibles
- ✅ **Lisible** : Code plus clair et maintenable
- ✅ **Intuitif** : Pas besoin de connaître la syntaxe Directus
- ✅ **Flexible** : Support des filtres simples et complexes imbriqués

## 📦 Import

```dart
import 'package:fcs_directus/fcs_directus.dart';
```

## 🔧 Utilisation de base

### Filtre simple

```dart
// Avant (Map manuel)
filter: {'status': {'_eq': 'published'}}

// Après (Filter API)
filter: Filter.field('status').equals('published')
```

### Dans une requête

```dart
final response = await client.items('articles').readMany(
  query: QueryParameters(
    filter: Filter.field('status').equals('published'),
    limit: 10,
  ),
);
```

## 📚 Opérateurs disponibles

### Comparaison

```dart
// Égalité
Filter.field('status').equals('active')
Filter.field('price').equals(99.99)

// Différence
Filter.field('status').notEquals('archived')

// Comparaisons numériques
Filter.field('price').lessThan(100)
Filter.field('price').lessThanOrEqual(100)
Filter.field('price').greaterThan(50)
Filter.field('price').greaterThanOrEqual(50)

// Entre deux valeurs
Filter.field('price').between(50, 200)
Filter.field('price').notBetween(10, 20)
```

### Chaînes de caractères

```dart
// Contient (sensible à la casse)
Filter.field('title').contains('laptop')
Filter.field('title').notContains('refurbished')

// Contient (insensible à la casse)
Filter.field('title').containsInsensitive('LAPTOP')
Filter.field('title').notContainsInsensitive('REFURBISHED')

// Commence par (sensible à la casse)
Filter.field('name').startsWith('Apple')
Filter.field('name').notStartsWith('Generic')

// Commence par (insensible à la casse)
Filter.field('name').startsWithInsensitive('apple')
Filter.field('name').notStartsWithInsensitive('generic')

// Se termine par (sensible à la casse)
Filter.field('email').endsWith('@example.com')
Filter.field('email').notEndsWith('@spam.com')

// Se termine par (insensible à la casse)
Filter.field('email').endsWithInsensitive('@EXAMPLE.COM')
Filter.field('email').notEndsWithInsensitive('@SPAM.COM')

// Expression régulière
Filter.field('email').regex(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
```

### Géographie (champs geometry)

```dart
// Intersecte avec une géométrie
Filter.field('location').intersects({
  'type': 'Point',
  'coordinates': [125.6, 10.1],
})

Filter.field('location').notIntersects(geometry)

// Intersecte avec une boîte englobante (bounding box)
Filter.field('location').intersectsBBox({
  'type': 'Polygon',
  'coordinates': [[
    [-180, -90],
    [-180, 90],
    [180, 90],
    [180, -90],
    [-180, -90],
  ]],
})

Filter.field('location').notIntersectsBBox(bbox)
```

### Relations One-to-Many

```dart
// Au moins un élément correspond
Filter.some('articles').where(
  Filter.field('status').equals('published'),
)

// Aucun élément ne correspond
Filter.none('violations').where(
  Filter.field('severity').equals('critical'),
)
```

### Listes

```dart
// Dans la liste
Filter.field('category').inList(['electronics', 'computers'])

// Pas dans la liste
Filter.field('status').notInList(['archived', 'deleted'])
```

### Valeurs NULL

```dart
// Est null
Filter.field('deleted_at').isNull()

// N'est pas null
Filter.field('description').isNotNull()

// Est vide (null ou chaîne vide)
Filter.field('notes').isEmpty()

// N'est pas vide
Filter.field('content').isNotEmpty()
```

## � Tableau récapitulatif des opérateurs

| Catégorie | Méthode | Opérateur Directus | Description |
|-----------|---------|-------------------|-------------|
| **Comparaison** | | | |
| | `equals(value)` | `_eq` | Égal à |
| | `notEquals(value)` | `_neq` | Différent de |
| | `lessThan(value)` | `_lt` | Inférieur à |
| | `lessThanOrEqual(value)` | `_lte` | Inférieur ou égal à |
| | `greaterThan(value)` | `_gt` | Supérieur à |
| | `greaterThanOrEqual(value)` | `_gte` | Supérieur ou égal à |
| **Collection** | | | |
| | `inList(values)` | `_in` | Dans la liste |
| | `notInList(values)` | `_nin` | Pas dans la liste |
| | `between(min, max)` | `_between` | Entre deux valeurs |
| | `notBetween(min, max)` | `_nbetween` | Pas entre deux valeurs |
| **Chaîne** | | | |
| | `contains(text)` | `_contains` | Contient (sensible) |
| | `notContains(text)` | `_ncontains` | Ne contient pas (sensible) |
| | `containsInsensitive(text)` | `_icontains` | Contient (insensible) |
| | `notContainsInsensitive(text)` | `_nicontains` | Ne contient pas (insensible) |
| | `startsWith(text)` | `_starts_with` | Commence par (sensible) |
| | `notStartsWith(text)` | `_nstarts_with` | Ne commence pas par (sensible) |
| | `startsWithInsensitive(text)` | `_istarts_with` | Commence par (insensible) |
| | `notStartsWithInsensitive(text)` | `_nistarts_with` | Ne commence pas par (insensible) |
| | `endsWith(text)` | `_ends_with` | Se termine par (sensible) |
| | `notEndsWith(text)` | `_nends_with` | Ne se termine pas par (sensible) |
| | `endsWithInsensitive(text)` | `_iends_with` | Se termine par (insensible) |
| | `notEndsWithInsensitive(text)` | `_niends_with` | Ne se termine pas par (insensible) |
| **Null/Empty** | | | |
| | `isNull()` | `_null` | Est null |
| | `isNotNull()` | `_nnull` | N'est pas null |
| | `isEmpty()` | `_empty` | Est vide (null ou "") |
| | `isNotEmpty()` | `_nempty` | N'est pas vide |
| **Géographie** | | | |
| | `intersects(geometry)` | `_intersects` | Intersecte une géométrie |
| | `notIntersects(geometry)` | `_nintersects` | N'intersecte pas une géométrie |
| | `intersectsBBox(bbox)` | `_intersects_bbox` | Intersecte une boîte englobante |
| | `notIntersectsBBox(bbox)` | `_nintersects_bbox` | N'intersecte pas une boîte englobante |
| **Validation** | | | |
| | `regex(pattern)` | `_regex` | Correspond à une regex |
| | `submitted()` | `_submitted` | Champ soumis (formulaire) |
| **Relations O2M** | | | |
| | `Filter.some(relation).where(...)` | `_some` | Au moins un élément correspond |
| | `Filter.none(relation).where(...)` | `_none` | Aucun élément ne correspond |
| **Logique** | | | |
| | `Filter.and([...])` | `_and` | Tous les filtres doivent être vrais |
| | `Filter.or([...])` | `_or` | Au moins un filtre doit être vrai |

## �🔗 Combinaisons de filtres

### AND (tous les critères doivent être vrais)

```dart
// Produits actifs ET en stock ET > 100€
Filter.and([
  Filter.field('status').equals('active'),
  Filter.field('stock').greaterThan(0),
  Filter.field('price').greaterThan(100),
])
```

**Équivalent Map :**
```dart
{
  '_and': [
    {'status': {'_eq': 'active'}},
    {'stock': {'_gt': 0}},
    {'price': {'_gt': 100}}
  ]
}
```

### OR (au moins un critère doit être vrai)

```dart
// Produits en promo OU en vedette
Filter.or([
  Filter.field('on_sale').equals(true),
  Filter.field('featured').equals(true),
])
```

**Équivalent Map :**
```dart
{
  '_or': [
    {'on_sale': {'_eq': true}},
    {'featured': {'_eq': true}}
  ]
}
```

## 🎯 Filtres imbriqués

Vous pouvez imbriquer `AND` et `OR` pour créer des conditions complexes :

```dart
// (Catégorie electronics ET prix < 500) OU en vedette
Filter.or([
  Filter.and([
    Filter.field('category').equals('electronics'),
    Filter.field('price').lessThan(500),
  ]),
  Filter.field('featured').equals(true),
])
```

**Équivalent Map :**
```dart
{
  '_or': [
    {
      '_and': [
        {'category': {'_eq': 'electronics'}},
        {'price': {'_lt': 500}}
      ]
    },
    {'featured': {'_eq': true}}
  ]
}
```

## 🔗 Filtres sur les relations

Pour filtrer sur des champs de relations (objets nested) :

```dart
// Produits dont la catégorie est "Premium"
Filter.relation('category').where(
  Filter.field('name').equals('Premium'),
)
```

**Équivalent Map :**
```dart
{
  'category': {
    'name': {'_eq': 'Premium'}
  }
}
```

### Relations avec conditions multiples

```dart
Filter.relation('category').where(
  Filter.and([
    Filter.field('active').equals(true),
    Filter.field('type').equals('main'),
  ]),
)
```

## 📋 Exemples complets

### E-commerce : Recherche de produits

```dart
final products = await client.items('products').readMany(
  query: QueryParameters(
    filter: Filter.and([
      // Produits disponibles
      Filter.field('status').equals('active'),
      Filter.field('stock').greaterThan(0),
      
      // Fourchette de prix
      Filter.field('price').between(20, 500),
      
      // Catégories acceptées
      Filter.or([
        Filter.field('category').equals('electronics'),
        Filter.field('category').equals('computers'),
      ]),
      
      // Doit avoir une image
      Filter.field('image').isNotNull(),
    ]),
    sort: ['price'],
    limit: 20,
  ),
);
```

### Blog : Articles récents et publiés

```dart
final articles = await client.items('articles').readMany(
  query: QueryParameters(
    filter: Filter.and([
      // Statut publié
      Filter.field('status').equals('published'),
      
      // Date de publication récente (dans les 30 derniers jours)
      Filter.field('published_at').greaterThan(
        DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
      ),
      
      // Pas d'articles brouillon ou archivés
      Filter.field('status').notInList(['draft', 'archived']),
    ]),
    sort: ['-published_at'],
    limit: 10,
  ),
);
```

### Recherche avec texte

```dart
final searchTerm = 'laptop';

final results = await client.items('products').readMany(
  query: QueryParameters(
    filter: Filter.or([
      // Cherche dans le nom
      Filter.field('name').contains(searchTerm),
      
      // Ou dans la description
      Filter.field('description').contains(searchTerm),
      
      // Ou dans les tags
      Filter.field('tags').contains(searchTerm),
    ]),
    limit: 50,
  ),
);
```

## 🔄 Migration depuis Map

### Simple

```dart
// Avant
filter: {'status': {'_eq': 'active'}}

// Après
filter: Filter.field('status').equals('active')
```

### Complexe

```dart
// Avant
filter: {
  '_and': [
    {'status': {'_eq': 'active'}},
    {'price': {'_gte': 100}},
    {
      '_or': [
        {'category': {'_eq': 'electronics'}},
        {'featured': {'_eq': true}}
      ]
    }
  ]
}

// Après
filter: Filter.and([
  Filter.field('status').equals('active'),
  Filter.field('price').greaterThanOrEqual(100),
  Filter.or([
    Filter.field('category').equals('electronics'),
    Filter.field('featured').equals(true),
  ]),
])
```

## 🆕 Compatibilité ascendante

Le système accepte toujours les Maps pour compatibilité :

```dart
// Toujours supporté
query: QueryParameters(
  filter: {
    'status': {'_eq': 'active'}
  }
)

// Nouveau système recommandé
query: QueryParameters(
  filter: Filter.field('status').equals('active')
)
```

## 📖 Référence complète des opérateurs

| Méthode | Opérateur Directus | Description |
|---------|-------------------|-------------|
| `equals(value)` | `_eq` | Égal à |
| `notEquals(value)` | `_neq` | Différent de |
| `lessThan(value)` | `_lt` | Inférieur à |
| `lessThanOrEqual(value)` | `_lte` | Inférieur ou égal |
| `greaterThan(value)` | `_gt` | Supérieur à |
| `greaterThanOrEqual(value)` | `_gte` | Supérieur ou égal |
| `inList(values)` | `_in` | Dans la liste |
| `notInList(values)` | `_nin` | Pas dans la liste |
| `between(min, max)` | `_between` | Entre deux valeurs |
| `notBetween(min, max)` | `_nbetween` | Pas entre |
| `contains(text)` | `_contains` | Contient |
| `notContains(text)` | `_ncontains` | Ne contient pas |
| `startsWith(text)` | `_starts_with` | Commence par |
| `notStartsWith(text)` | `_nstarts_with` | Ne commence pas |
| `endsWith(text)` | `_ends_with` | Se termine par |
| `notEndsWith(text)` | `_nends_with` | Ne termine pas |
| `isNull()` | `_null` | Est NULL |
| `isNotNull()` | `_nnull` | N'est pas NULL |
| `isEmpty()` | `_empty` | Est vide |
| `isNotEmpty()` | `_nempty` | N'est pas vide |

## 💡 Bonnes pratiques

1. **Utilisez Filter pour les nouveaux projets** : Plus maintenable et type-safe
2. **Combinez AND/OR judicieusement** : Pensez à la logique booléenne
3. **Testez vos filtres** : Vérifiez que les résultats sont corrects
4. **Utilisez des variables** : Pour des filtres réutilisables

```dart
// Réutilisable
final activeFilter = Filter.field('status').equals('active');
final inStockFilter = Filter.field('stock').greaterThan(0);

final filter = Filter.and([activeFilter, inStockFilter]);
```

## 🎓 Exemples avancés

Voir `example/filter_example.dart` pour des exemples complets et commentés.

---

**Documentation Directus :** https://docs.directus.io/reference/filter-rules.html

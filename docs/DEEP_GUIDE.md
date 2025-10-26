# Guide du Système Deep

Le système Deep de `fcs_directus` fournit une manière intuitive et type-safe de construire des requêtes pour charger des relations imbriquées dans Directus, sans avoir à écrire manuellement des structures Map complexes.

## Table des matières
- [Introduction](#introduction)
- [Utilisation de base](#utilisation-de-base)
- [Référence des classes](#référence-des-classes)
- [Exemples avancés](#exemples-avancés)
- [Combinaison avec Filter](#combinaison-avec-filter)
- [Bonnes pratiques](#bonnes-pratiques)
- [Migration depuis Map](#migration-depuis-map)

## Introduction

Dans Directus, le paramètre `deep` permet de charger des relations imbriquées dans une seule requête. Sans le système Deep, vous devriez écrire des structures Map complexes :

```dart
// ❌ Ancienne méthode - complexe et sujette aux erreurs
final query = QueryParameters(
  deep: {
    'author': {
      '_fields': ['id', 'name', 'email'],
      '_limit': 1,
    },
    'comments': {
      '_fields': ['id', 'content'],
      '_filter': {
        'status': {'_eq': 'approved'}
      },
      '_sort': ['-created_at'],
      '_limit': 10,
    },
  },
);
```

Avec le système Deep, c'est beaucoup plus simple et type-safe :

```dart
// ✅ Nouvelle méthode - intuitive et type-safe
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery()
        .fields(['id', 'name', 'email'])
        .first(1),
    'comments': DeepQuery()
        .fields(['id', 'content'])
        .filter(Filter.field('status').equals('approved'))
        .sortDesc('created_at')
        .limit(10),
  }),
);
```

## Utilisation de base

### 1. Deep simple avec sélection de champs

```dart
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery().fields(['id', 'name', 'email']),
  }),
);

final articles = await client.items.readMany('articles', query);
```

### 2. Deep avec limite et tri

```dart
final query = QueryParameters(
  deep: Deep({
    'comments': DeepQuery()
        .limit(5)
        .sortDesc('created_at')
        .fields(['id', 'content', 'created_at']),
  }),
);
```

### 3. Deep avec filtres

```dart
final query = QueryParameters(
  deep: Deep({
    'categories': DeepQuery()
        .filter(Filter.field('status').equals('published'))
        .sortAsc('name'),
  }),
);
```

### 4. Deep imbriqué (relations dans des relations)

```dart
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery()
        .fields(['id', 'name', 'avatar'])
        .deep({
          'avatar': DeepQuery().fields(['id', 'filename_disk', 'title']),
        }),
  }),
);
```

### 5. Deep multiple (plusieurs relations)

```dart
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery().fields(['name', 'email']),
    'categories': DeepQuery().limit(10).sortAsc('name'),
    'featured_image': DeepQuery().fields(['id', 'filename_disk']),
  }),
);
```

## Référence des classes

### `Deep`

Classe abstraite de base pour les configurations de requête deep.

#### Constructeurs

```dart
// Configuration par champs
Deep(Map<String, DeepQuery> fields)

// Profondeur maximale simple
Deep.maxDepth(int depth)
```

#### Méthodes

| Méthode | Description |
|---------|-------------|
| `toJson()` | Convertit la configuration en Map pour Directus |

### `DeepQuery`

Configuration pour un champ de relation spécifique.

#### Méthodes principales

| Méthode | Paramètres | Description |
|---------|------------|-------------|
| `fields(List<String>)` | Liste de champs | Spécifie les champs à retourner |
| `filter(dynamic)` | Filter ou Map | Ajoute un filtre sur la relation |
| `limit(int)` | Nombre max | Limite le nombre d'items |
| `sort(dynamic)` | String ou List | Trie les résultats |
| `deep(Map<String, DeepQuery>)` | Relations | Ajoute des relations imbriquées |

#### Méthodes d'extension utilitaires

| Méthode | Description | Équivalent |
|---------|-------------|------------|
| `allFields()` | Tous les champs | `fields(['*'])` |
| `sortAsc(String)` | Tri ascendant | `sort('field')` |
| `sortDesc(String)` | Tri descendant | `sort('-field')` |
| `first(int)` | N premiers items | `limit(n)` |

## Exemples avancés

### Blog avec commentaires filtrés

```dart
final query = QueryParameters(
  deep: Deep({
    'comments': DeepQuery()
        .filter(
          Filter.and([
            Filter.field('status').equals('approved'),
            Filter.field('spam').equals(false),
          ]),
        )
        .sortDesc('created_at')
        .limit(10)
        .fields(['id', 'content', 'created_at', 'user'])
        .deep({
          'user': DeepQuery().fields(['id', 'name', 'avatar']),
        }),
  }),
);

final posts = await client.items.readMany('posts', query);
```

### E-commerce avec relations complexes

```dart
final query = QueryParameters(
  deep: Deep({
    'items': DeepQuery()
        .fields(['id', 'quantity', 'price', 'product'])
        .deep({
          'product': DeepQuery()
              .fields(['id', 'name', 'image', 'category'])
              .deep({
                'image': DeepQuery().fields(['id', 'filename_disk']),
                'category': DeepQuery().fields(['id', 'name']),
              }),
        }),
    'customer': DeepQuery()
        .fields(['id', 'first_name', 'last_name', 'email', 'avatar'])
        .deep({
          'avatar': DeepQuery().fields(['id', 'filename_disk']),
        }),
    'shipping_address': DeepQuery().allFields(),
  }),
);

final orders = await client.items.readMany('orders', query);
```

### Many-to-Many avec filtre sur table de jonction

```dart
final query = QueryParameters(
  deep: Deep({
    'movie_actors': DeepQuery()
        .filter(Filter.field('role').equals('lead'))
        .deep({
          'actors': DeepQuery()
              .fields(['id', 'name', 'photo'])
              .deep({
                'photo': DeepQuery().fields(['id', 'filename_disk']),
              }),
        }),
  }),
);

final movies = await client.items.readMany('movies', query);
```

### Deep avec profondeur maximale (approche simple)

Pour des cas où vous voulez charger toutes les relations jusqu'à une certaine profondeur :

```dart
final query = QueryParameters(
  deep: Deep.maxDepth(3), // Charge jusqu'à 3 niveaux de profondeur
);

final items = await client.items.readMany('items', query);
```

## Combinaison avec Filter

Le système Deep s'intègre parfaitement avec le système Filter :

```dart
final query = QueryParameters(
  // Filtre sur l'entité principale
  filter: Filter.and([
    Filter.field('status').equals('published'),
    Filter.field('featured').equals(true),
  ]),
  // Deep pour les relations
  deep: Deep({
    'author': DeepQuery()
        .fields(['id', 'name', 'bio', 'avatar'])
        .deep({
          'avatar': DeepQuery().fields(['id', 'filename_disk']),
        }),
    'categories': DeepQuery()
        .filter(Filter.field('featured').equals(true))
        .sortAsc('name'),
  }),
  // Autres paramètres
  limit: 10,
  sort: ['-published_at'],
);

final articles = await client.items.readMany('articles', query);
```

## Bonnes pratiques

### 1. Spécifiez les champs explicitement

❌ **À éviter** : Charger tous les champs
```dart
DeepQuery() // Charge tous les champs par défaut
```

✅ **Recommandé** : Spécifier les champs nécessaires
```dart
DeepQuery().fields(['id', 'name', 'email'])
```

### 2. Limitez la profondeur des relations

❌ **À éviter** : Relations trop profondes
```dart
Deep({
  'a': DeepQuery().deep({
    'b': DeepQuery().deep({
      'c': DeepQuery().deep({
        'd': DeepQuery() // Trop profond !
      })
    })
  })
})
```

✅ **Recommandé** : Maximum 2-3 niveaux
```dart
Deep({
  'author': DeepQuery().deep({
    'avatar': DeepQuery() // 2 niveaux, OK
  })
})
```

### 3. Utilisez les méthodes d'extension

❌ **Moins lisible**
```dart
DeepQuery()
  .fields(['*'])
  .sort(['-created_at'])
  .limit(1)
```

✅ **Plus lisible**
```dart
DeepQuery()
  .allFields()
  .sortDesc('created_at')
  .first(1)
```

### 4. Filtrez les relations pour les performances

```dart
// ✅ Limite les commentaires aux plus récents
DeepQuery()
  .filter(Filter.field('created_at').greaterThan(lastWeek))
  .limit(10)
```

### 5. Combinez les méthodes de manière fluide

```dart
// ✅ Chaînage de méthodes clair et lisible
DeepQuery()
  .fields(['id', 'title', 'content'])
  .filter(Filter.field('status').equals('published'))
  .sortDesc('created_at')
  .limit(5)
  .deep({
    'author': DeepQuery().fields(['name', 'email']),
  })
```

## Migration depuis Map

Si vous avez du code existant utilisant des Map, voici comment migrer :

### Avant (Map)

```dart
final query = QueryParameters(
  deep: {
    'author': {
      '_fields': ['id', 'name', 'email'],
      '_limit': 1,
    },
    'comments': {
      '_fields': ['id', 'content'],
      '_filter': {
        'status': {'_eq': 'approved'}
      },
      '_sort': ['-created_at'],
      '_limit': 10,
    },
  },
);
```

### Après (Deep)

```dart
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery()
        .fields(['id', 'name', 'email'])
        .first(1),
    'comments': DeepQuery()
        .fields(['id', 'content'])
        .filter(Filter.field('status').equals('approved'))
        .sortDesc('created_at')
        .limit(10),
  }),
);
```

### Avantages de la migration

1. **Type-safety** : Erreurs détectées à la compilation
2. **Autocomplétion** : L'IDE suggère les méthodes disponibles
3. **Lisibilité** : Code plus clair et intentionnel
4. **Maintenabilité** : Plus facile à comprendre et modifier
5. **Documentation** : Les méthodes sont documentées dans l'IDE

### Compatibilité

Le système Deep est **100% compatible** avec l'ancienne méthode Map :

```dart
// ✅ Vous pouvez toujours utiliser des Map si nécessaire
final query = QueryParameters(
  deep: {
    'author': {
      '_fields': ['id', 'name'],
    },
  },
);
```

Les deux approches fonctionnent et peuvent même être mélangées dans le même projet pendant la migration.

## Performance

### Considérations

1. **Nombre de relations** : Plus vous chargez de relations, plus la requête sera lente
2. **Profondeur** : Limitez à 2-3 niveaux maximum
3. **Filtres** : Filtrez les relations pour réduire les données
4. **Champs** : Ne chargez que les champs nécessaires

### Exemple optimisé

```dart
// ✅ Optimisé pour les performances
final query = QueryParameters(
  fields: ['id', 'title', 'published_at'], // Seulement les champs nécessaires
  deep: Deep({
    'author': DeepQuery()
        .fields(['id', 'name']) // Minimum de champs
        .first(1), // Limite à 1 auteur
    'comments': DeepQuery()
        .fields(['id', 'content'])
        .filter(Filter.field('created_at').greaterThan(lastMonth)) // Filtre temporel
        .limit(5), // Limite le nombre
  }),
  limit: 20, // Pagination
);
```

## Conclusion

Le système Deep de `fcs_directus` rend le chargement de relations imbriquées **simple**, **type-safe** et **maintenable**. Il s'intègre parfaitement avec le système Filter pour créer des requêtes complexes de manière intuitive.

Pour plus d'exemples, consultez :
- `example/deep_example.dart` - 11 exemples d'utilisation
- `test/directus_deep_test.dart` - 27 tests unitaires
- `docs/FILTERS_GUIDE.md` - Guide du système Filter

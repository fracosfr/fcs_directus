# Deep Queries (Relations)

Ce guide explique comment charger les données relationnelles avec les Deep Queries.

## Introduction

Les Deep Queries permettent de charger les relations imbriquées en une seule requête. Sans deep queries, vous n'obtenez que les IDs des relations :

```dart
// Sans deep query
{'id': 1, 'title': 'Article', 'author': 'user-uuid'}

// Avec deep query sur author
{
  'id': 1, 
  'title': 'Article', 
  'author': {
    'id': 'user-uuid',
    'first_name': 'John',
    'last_name': 'Doe',
    'email': 'john@example.com'
  }
}
```

## Syntaxe de base

### Créer un Deep Query

```dart
final query = QueryParameters(
  deep: Deep({
    'relation_name': DeepQuery(),
  }),
);
```

### DeepQuery vide

Un `DeepQuery()` sans configuration charge tous les champs de la relation :

```dart
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery(),  // Charge tous les champs de author
  }),
);
```

## Configuration des DeepQuery

### Sélectionner des champs

```dart
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery().fields(['id', 'first_name', 'last_name', 'email']),
  }),
);
```

### Filtrer les relations

```dart
final query = QueryParameters(
  deep: Deep({
    'comments': DeepQuery()
      .filter(Filter.and([
        Filter.field('approved').equals(true),
        Filter.field('spam').equals(false),
      ])),
  }),
);
```

### Limiter le nombre de résultats

```dart
final query = QueryParameters(
  deep: Deep({
    'comments': DeepQuery().limit(10),  // Max 10 commentaires
  }),
);
```

### Pagination

```dart
final query = QueryParameters(
  deep: Deep({
    'comments': DeepQuery()
      .limit(10)
      .offset(20),  // Sauter les 20 premiers
  }),
);

// Ou avec page
final query = QueryParameters(
  deep: Deep({
    'comments': DeepQuery()
      .limit(10)
      .page(3),  // Page 3
  }),
);
```

### Trier les relations

```dart
final query = QueryParameters(
  deep: Deep({
    // Tri ascendant
    'comments': DeepQuery().sortAsc('date_created'),
    
    // Tri descendant
    'products': DeepQuery().sortDesc('price'),
    
    // Tri multiple
    'items': DeepQuery().sort(['category', '-price']),
  }),
);
```

### Recherche dans les relations

```dart
final query = QueryParameters(
  deep: Deep({
    'products': DeepQuery().search('laptop'),
  }),
);
```

## Combinaison de configurations

Chaînez les méthodes pour des configurations complexes :

```dart
final query = QueryParameters(
  deep: Deep({
    'comments': DeepQuery()
      .fields(['id', 'content', 'author.first_name', 'date_created'])
      .filter(Filter.field('approved').equals(true))
      .limit(5)
      .sortDesc('date_created'),
  }),
);
```

## Relations multiples

Chargez plusieurs relations simultanément :

```dart
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery()
      .fields(['id', 'first_name', 'last_name', 'avatar']),
    'category': DeepQuery()
      .fields(['id', 'name', 'slug']),
    'tags': DeepQuery()
      .fields(['id', 'name']),
    'comments': DeepQuery()
      .filter(Filter.field('approved').equals(true))
      .limit(10),
  }),
);
```

## Relations imbriquées

Chargez des relations de relations :

```dart
final query = QueryParameters(
  deep: Deep({
    'author': DeepQuery()
      .fields(['id', 'first_name', 'last_name'])
      .deep({
        // Relation de author
        'company': DeepQuery()
          .fields(['name', 'website', 'logo']),
        'avatar': DeepQuery()
          .fields(['id', 'filename_download']),
      }),
  }),
);

// Résultat
{
  'id': 1,
  'title': 'Mon article',
  'author': {
    'id': 'user-uuid',
    'first_name': 'John',
    'last_name': 'Doe',
    'company': {
      'name': 'Acme Inc',
      'website': 'https://acme.com',
      'logo': '...'
    },
    'avatar': {
      'id': 'file-uuid',
      'filename_download': 'avatar.jpg'
    }
  }
}
```

## Relations M2M (Many-to-Many)

Les relations M2M dans Directus passent par une table de jonction :

```
articles ---> articles_tags ---> tags
```

### Charger la relation M2M

```dart
final query = QueryParameters(
  deep: Deep({
    // 'tags' est le champ dans articles
    // La table de jonction est articles_tags
    'tags': DeepQuery()
      .fields(['id', 'name', 'color']),
  }),
);
```

### Avec le champ de jonction explicite

```dart
final query = QueryParameters(
  // Sélectionner les champs de la jonction
  fields: ['id', 'title', 'tags.tags_id.id', 'tags.tags_id.name'],
  
  deep: Deep({
    'tags': DeepQuery()
      .deep({
        'tags_id': DeepQuery()  // Champ vers la table tags
          .fields(['id', 'name', 'color']),
      }),
  }),
);
```

## Exemples complets

### Blog avec relations

```dart
final articles = await client.items('articles').readMany(
  query: QueryParameters(
    fields: ['id', 'title', 'slug', 'excerpt', 'date_published'],
    filter: Filter.field('status').equals('published'),
    deep: Deep({
      'author': DeepQuery()
        .fields(['id', 'first_name', 'last_name'])
        .deep({
          'avatar': DeepQuery().fields(['id']),
        }),
      'category': DeepQuery()
        .fields(['id', 'name', 'slug']),
      'featured_image': DeepQuery()
        .fields(['id', 'width', 'height']),
      'tags': DeepQuery()
        .fields(['id', 'name'])
        .limit(5),
    }),
    sort: ['-date_published'],
    limit: 10,
  ),
);
```

### E-commerce avec produits

```dart
final products = await client.items('products').readMany(
  query: QueryParameters(
    filter: Filter.and([
      Filter.field('status').equals('active'),
      Filter.field('stock').greaterThan(0),
    ]),
    deep: Deep({
      'category': DeepQuery()
        .fields(['id', 'name', 'parent.name']),
      'brand': DeepQuery()
        .fields(['id', 'name', 'logo']),
      'images': DeepQuery()
        .fields(['directus_files_id.id', 'directus_files_id.filename_download'])
        .sortAsc('sort')
        .limit(5),
      'reviews': DeepQuery()
        .fields(['id', 'rating', 'comment', 'user.first_name'])
        .filter(Filter.field('approved').equals(true))
        .sortDesc('date_created')
        .limit(3),
      'variants': DeepQuery()
        .fields(['id', 'name', 'sku', 'price', 'stock'])
        .filter(Filter.field('active').equals(true)),
    }),
    limit: 20,
  ),
);
```

### Utilisateur avec toutes ses données

```dart
final user = await client.users.getUser(
  userId,
  query: QueryParameters(
    deep: Deep({
      'role': DeepQuery()
        .fields(['id', 'name', 'admin_access']),
      'avatar': DeepQuery()
        .fields(['id', 'filename_download', 'type']),
      'policies': DeepQuery()
        .fields(['id', 'name', 'permissions']),
    }),
  ),
);
```

## Utilisation avec modèles typés

### Définition du modèle

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  late final title = stringValue('title');
  late final author = modelValue<DirectusUser>('author');
  late final category = modelValue<Category>('category');
  late final tags = modelListValueM2M<Tag>('tags', 'tags_id');
}
```

### Charger avec Deep

```dart
final articles = await client.itemsOf<Article>().readMany(
  query: QueryParameters(
    deep: Deep({
      'author': DeepQuery().fields(['id', 'first_name', 'last_name']),
      'category': DeepQuery().fields(['id', 'name']),
      'tags': DeepQuery().fields(['id', 'name']),
    }),
  ),
);

for (final article in articles.data) {
  print('Titre: ${article.title.value}');
  
  // Auteur chargé
  if (article.author.isLoaded) {
    print('Auteur: ${article.author.model?.fullName}');
  }
  
  // Catégorie
  print('Catégorie: ${article.category.model?.name.value}');
  
  // Tags
  for (final tag in article.tags) {
    print('Tag: ${tag.name.value}');
  }
}
```

## Performance et bonnes pratiques

### 1. Limiter la profondeur

Évitez les deep queries trop profondes (> 3 niveaux) :

```dart
// ❌ Trop profond
deep: Deep({
  'author': DeepQuery().deep({
    'company': DeepQuery().deep({
      'country': DeepQuery().deep({
        'continent': DeepQuery(),  // 4 niveaux !
      }),
    }),
  }),
})

// ✅ Préférer plusieurs requêtes si nécessaire
```

### 2. Sélectionner uniquement les champs nécessaires

```dart
// ❌ Charge tout
deep: Deep({'author': DeepQuery()})

// ✅ Sélectionne uniquement ce qui est utile
deep: Deep({
  'author': DeepQuery().fields(['id', 'first_name', 'avatar.id']),
})
```

### 3. Limiter les relations O2M/M2M

```dart
// ❌ Peut charger des milliers d'items
deep: Deep({'comments': DeepQuery()})

// ✅ Limiter
deep: Deep({
  'comments': DeepQuery().limit(10).sortDesc('date_created'),
})
```

### 4. Filtrer les relations

```dart
// ✅ Ne charge que les données pertinentes
deep: Deep({
  'comments': DeepQuery()
    .filter(Filter.field('approved').equals(true))
    .limit(10),
})
```

### 5. Utiliser en combinaison avec fields

```dart
final query = QueryParameters(
  // Champs de la collection principale
  fields: ['id', 'title', 'status'],
  
  // Configuration des relations
  deep: Deep({
    'author': DeepQuery().fields(['id', 'first_name']),
  }),
);
```

## Différence avec fields

`fields` et `deep` ont des rôles complémentaires :

```dart
// fields : sélectionne les champs à retourner (notation pointée pour relations simples)
fields: ['id', 'title', 'author.first_name']

// deep : configure le chargement des relations (filtres, limite, tri, etc.)
deep: Deep({
  'author': DeepQuery()
    .filter(Filter.field('active').equals(true)),
})

// Combinés
final query = QueryParameters(
  fields: ['id', 'title', 'author.id', 'author.first_name'],
  deep: Deep({
    'comments': DeepQuery()
      .fields(['id', 'content'])
      .filter(Filter.field('approved').equals(true))
      .limit(5),
  }),
);
```

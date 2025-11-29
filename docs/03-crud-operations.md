# Opérations CRUD

Ce guide couvre toutes les opérations de lecture et d'écriture sur les collections Directus.

## Accéder aux items

Le client fournit deux méthodes pour accéder aux items :

```dart
// Méthode générique (retourne Map<String, dynamic>)
final service = client.items('articles');

// Méthode typée (retourne vos modèles personnalisés)
final service = client.itemsOf<Article>();
```

## Création

### Créer un seul item

```dart
final newArticle = await client.items('articles').createOne({
  'title': 'Mon article',
  'content': 'Contenu de l\'article',
  'status': 'draft',
  'author': 'user-uuid',
});

print('ID créé: ${newArticle['id']}');
```

### Créer plusieurs items

```dart
final articles = await client.items('articles').createMany([
  {'title': 'Article 1', 'status': 'draft'},
  {'title': 'Article 2', 'status': 'published'},
  {'title': 'Article 3', 'status': 'draft'},
]);

for (final article in articles) {
  print('Créé: ${article['id']} - ${article['title']}');
}
```

### Options de création

```dart
final article = await client.items('articles').createOne(
  {'title': 'Mon article'},
  query: QueryParameters(
    fields: ['id', 'title', 'date_created'], // Champs retournés
  ),
);
```

## Lecture

### Lire plusieurs items

```dart
// Lecture basique
final response = await client.items('articles').readMany();

print('Total: ${response.meta?.totalCount}');
print('Items: ${response.data.length}');

for (final article in response.data) {
  print('- ${article['title']}');
}
```

### Avec QueryParameters

```dart
final response = await client.items('articles').readMany(
  query: QueryParameters(
    fields: ['id', 'title', 'author.name'],     // Sélection de champs
    filter: Filter.field('status').equals('published'),
    sort: ['-date_created'],                      // Tri décroissant
    limit: 20,                                    // Limite
    offset: 40,                                   // Décalage
    search: 'flutter',                            // Recherche full-text
  ),
);
```

### Lire un seul item

```dart
final article = await client.items('articles').readOne('article-uuid');

print('Titre: ${article['title']}');
print('Contenu: ${article['content']}');
```

### Avec champs spécifiques

```dart
final article = await client.items('articles').readOne(
  'article-uuid',
  query: QueryParameters(
    fields: ['id', 'title', 'author.first_name', 'author.last_name'],
  ),
);
```

### Lire un singleton

Pour les collections configurées comme singleton (ex: settings) :

```dart
final settings = await client.items('settings').readSingleton();

print('Site name: ${settings['site_name']}');
print('Theme: ${settings['theme']}');
```

## Mise à jour

### Mettre à jour un item

```dart
await client.items('articles').updateOne(
  'article-uuid',
  {'title': 'Nouveau titre', 'status': 'published'},
);
```

### Avec retour des données

```dart
final updated = await client.items('articles').updateOne(
  'article-uuid',
  {'title': 'Nouveau titre'},
  query: QueryParameters(fields: ['id', 'title', 'date_updated']),
);

print('Mis à jour: ${updated['date_updated']}');
```

### Mettre à jour plusieurs items

Par clés :

```dart
await client.items('articles').updateMany(
  keys: ['uuid-1', 'uuid-2', 'uuid-3'],
  data: {'status': 'published'},
);
```

Par filtre :

```dart
await client.items('articles').updateMany(
  filter: Filter.field('status').equals('draft'),
  data: {'status': 'review'},
);
```

### Mettre à jour un singleton

```dart
await client.items('settings').updateSingleton({
  'site_name': 'Mon nouveau site',
  'maintenance_mode': false,
});
```

## Suppression

### Supprimer un item

```dart
await client.items('articles').deleteOne('article-uuid');
```

### Supprimer plusieurs items

Par clés :

```dart
await client.items('articles').deleteMany(
  keys: ['uuid-1', 'uuid-2', 'uuid-3'],
);
```

Par filtre :

```dart
await client.items('articles').deleteMany(
  filter: Filter.field('status').equals('archived'),
);
```

## Pagination

### Pagination par offset

```dart
const pageSize = 20;
var offset = 0;

while (true) {
  final response = await client.items('articles').readMany(
    query: QueryParameters(
      limit: pageSize,
      offset: offset,
    ),
  );
  
  if (response.data.isEmpty) break;
  
  for (final article in response.data) {
    print(article['title']);
  }
  
  offset += pageSize;
}
```

### Pagination par page

```dart
const pageSize = 20;
var page = 1;

while (true) {
  final response = await client.items('articles').readMany(
    query: QueryParameters(
      limit: pageSize,
      page: page,
    ),
  );
  
  if (response.data.isEmpty) break;
  
  // Traiter les données
  processArticles(response.data);
  
  page++;
}
```

### Obtenir le total

Pour connaître le nombre total d'items :

```dart
final response = await client.items('articles').readMany(
  query: QueryParameters(
    limit: 1,
    meta: '*', // Demande les métadonnées
  ),
);

final total = response.meta?.totalCount ?? 0;
print('Total: $total articles');
```

## Sélection de champs

### Champs simples

```dart
final query = QueryParameters(
  fields: ['id', 'title', 'status'],
);
```

### Tous les champs

```dart
final query = QueryParameters(
  fields: ['*'],
);
```

### Champs relationnels

```dart
final query = QueryParameters(
  fields: [
    'id',
    'title',
    'author.id',
    'author.first_name',
    'author.last_name',
    'author.avatar.id',
  ],
);
```

### Tous les champs d'une relation

```dart
final query = QueryParameters(
  fields: [
    'id',
    'title',
    'author.*',  // Tous les champs de author
  ],
);
```

## Tri

### Tri simple

```dart
// Ascendant
final query = QueryParameters(sort: ['title']);

// Descendant
final query = QueryParameters(sort: ['-date_created']);
```

### Tri multiple

```dart
final query = QueryParameters(
  sort: ['category', '-date_created', 'title'],
);
```

### Tri sur relation

```dart
final query = QueryParameters(
  sort: ['author.last_name', '-date_created'],
);
```

## Recherche full-text

```dart
final response = await client.items('articles').readMany(
  query: QueryParameters(
    search: 'flutter dart mobile',
  ),
);
```

> **Note** : La recherche full-text fonctionne sur les champs configurés dans Directus.

## Utilisation avec modèles typés

### Définir un modèle

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  late final title = stringValue('title');
  late final content = stringValue('content');
  late final status = stringValue('status');
}

// Enregistrer la factory
DirectusModel.registerFactory<Article>(Article.new);
```

### Opérations typées

```dart
// Lecture
final response = await client.itemsOf<Article>().readMany();

for (final article in response.data) {
  print(article.title.value);  // Type-safe !
  print(article.status.value);
}

// Lecture unique
final article = await client.itemsOf<Article>().readOne('uuid');
print(article.title.value);

// Création
final newArticle = Article.empty()
  ..title.set('Nouveau titre')
  ..content.set('Contenu...')
  ..status.set('draft');

final created = await client.itemsOf<Article>().createOne(newArticle.toJson());

// Mise à jour
article.title.set('Titre modifié');
await client.itemsOf<Article>().updateOne(article.id!, article.toJsonDirty());
```

## Requêtes complexes

### Combinaison complète

```dart
final response = await client.items('products').readMany(
  query: QueryParameters(
    // Sélection de champs avec relations
    fields: [
      'id', 'name', 'price', 'stock',
      'category.id', 'category.name',
      'images.directus_files_id.id',
      'images.directus_files_id.filename_download',
    ],
    
    // Filtres
    filter: Filter.and([
      Filter.field('status').equals('active'),
      Filter.field('price').greaterThan(0),
      Filter.field('stock').greaterThan(0),
    ]),
    
    // Relations profondes
    deep: Deep({
      'category': DeepQuery().fields(['id', 'name', 'slug']),
      'images': DeepQuery().limit(3),
    }),
    
    // Tri
    sort: ['category.name', '-price'],
    
    // Pagination
    limit: 20,
    page: 1,
    
    // Recherche
    search: 'laptop',
  ),
);
```

## Gestion des erreurs

```dart
try {
  final article = await client.items('articles').readOne('invalid-id');
} on DirectusNotFoundException catch (e) {
  print('Article non trouvé');
} on DirectusPermissionException catch (e) {
  print('Accès refusé');
} on DirectusValidationException catch (e) {
  print('Données invalides: ${e.message}');
  if (e.fieldErrors != null) {
    e.fieldErrors!.forEach((field, errors) {
      print('  $field: ${errors.join(", ")}');
    });
  }
} on DirectusException catch (e) {
  print('Erreur: ${e.message}');
}
```

## Bonnes pratiques

### 1. Limiter les champs

Demandez uniquement les champs nécessaires pour réduire la bande passante :

```dart
// ❌ Éviter
await client.items('articles').readMany();

// ✅ Préférer
await client.items('articles').readMany(
  query: QueryParameters(fields: ['id', 'title', 'status']),
);
```

### 2. Paginer les grandes collections

```dart
// ❌ Éviter
await client.items('logs').readMany(); // Potentiellement des milliers

// ✅ Préférer
await client.items('logs').readMany(
  query: QueryParameters(limit: 50, page: 1),
);
```

### 3. Utiliser les modèles typés

Les modèles personnalisés offrent plus de sécurité et une meilleure expérience développeur.

### 4. Gérer les erreurs

Toujours entourer les opérations de try-catch pour une meilleure UX.

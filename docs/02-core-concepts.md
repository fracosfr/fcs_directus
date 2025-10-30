# Core Concepts

Comprendre les concepts fondamentaux de la librairie fcs_directus.

## 🏗️ Architecture

La librairie est organisée en plusieurs couches :

```
fcs_directus/
├── core/              # Configuration et client HTTP
├── services/          # Services pour chaque endpoint Directus
├── models/            # Modèles de base (DirectusModel, Filter, Deep, etc.)
├── exceptions/        # Exceptions personnalisées
├── utils/             # Utilitaires (cache, logging)
└── websocket/         # Support WebSocket temps réel
```

### Composants principaux

1. **DirectusClient** : Point d'entrée principal, gère la configuration et donne accès aux services
2. **Services** : Classes spécialisées pour chaque endpoint de l'API Directus (ItemsService, UsersService, etc.)
3. **DirectusModel** : Classe de base pour créer vos modèles personnalisés
4. **QueryParameters** : Classe pour construire des requêtes complexes
5. **Filters, Deep, Aggregate** : Builders type-safe pour les requêtes avancées

## 🎯 Pattern Active Record

fcs_directus utilise le **pattern Active Record** pour les modèles. Cela signifie que :

- Chaque instance de modèle contient ses données ET les méthodes pour les manipuler
- Les données sont stockées dans un `Map<String, dynamic>` interne
- Les getters/setters fournissent un accès type-safe
- Le modèle peut directement effectuer des opérations CRUD via `save()`, `delete()`, etc.

### Exemple

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  String get title => getString('title');
  set title(String value) => setString('title', value);
}

// Utilisation
final article = Article({'title': 'Mon article'});
article.title = 'Titre modifié';
await article.save(); // Sauvegarde directement dans Directus
```

## 📦 Stockage des données

### Map<String, dynamic> interne

Les modèles DirectusModel stockent leurs données dans un `Map<String, dynamic>` :

```dart
abstract class DirectusModel {
  final Map<String, dynamic> _data;        // État actuel
  final Map<String, dynamic> _originalData; // État initial
  final Set<String> _dirtyFields = {};     // Champs modifiés
  
  // ...
}
```

### Tracking des modifications

Le système track automatiquement les champs modifiés :

```dart
final article = Article({'title': 'Original'});
print(article.isDirty); // false

article.title = 'Modifié';
print(article.isDirty); // true
print(article.dirtyFields); // {'title'}
print(article.originalValue('title')); // 'Original'
```

### Accès aux données brutes

```dart
// Lire les données JSON
final data = article.toJson();
print(data); // {'title': 'Modifié', ...}

// Obtenir uniquement les modifications
final changes = article.getChanges();
print(changes); // {'title': 'Modifié'}

// Réinitialiser les modifications
article.resetDirty();
```

## 🔧 Property Wrappers

Les **property wrappers** simplifient l'accès aux données et évitent le boilerplate :

### Sans property wrappers (classique)

```dart
class Product extends DirectusModel {
  Product(super.data);
  
  @override
  String get itemName => 'products';
  
  String get name => getString('name');
  set name(String value) => setString('name', value);
  
  double get price => getDouble('price');
  set price(double value) => setDouble('price', value);
  
  bool get available => getBool('available');
  set available(bool value) => setBool('available', value);
}
```

### Avec property wrappers (simplifié)

```dart
class Product extends DirectusModel {
  Product(super.data);
  
  @override
  String get itemName => 'products';
  
  late final name = stringValue('name');
  late final price = doubleValue('price');
  late final available = boolValue('available');
  
  // Utilisation:
  // product.name.value         // Lire
  // product.name.set('Laptop') // Écrire
  // product.name.name          // Nom du champ: "name"
}
```

### Types de property wrappers disponibles

| Wrapper | Type Dart | Exemple |
|---------|-----------|---------|
| `stringValue()` | String | `late final name = stringValue('name');` |
| `intValue()` | int | `late final quantity = intValue('quantity');` |
| `doubleValue()` | double | `late final price = doubleValue('price');` |
| `boolValue()` | bool | `late final active = boolValue('active');` |
| `dateTimeValue()` | DateTime | `late final publishDate = dateTimeValue('publish_date');` |
| `listValue()` | List | `late final tags = listValue('tags');` |
| `mapValue()` | Map | `late final metadata = mapValue('metadata');` |

### Avantages des property wrappers

✅ Moins de code boilerplate  
✅ Accès aux métadonnées du champ (nom, type)  
✅ Cohérence avec le système de tracking  
✅ Facilite la validation et les transformations  
✅ Meilleure lisibilité du code  

## 🔄 Cycle de vie d'un modèle

```dart
// 1. Création depuis JSON (ex: depuis API)
final article = Article({
  'id': '1',
  'title': 'Mon article',
  'status': 'published',
});

// 2. Modification
article.title = 'Nouveau titre';
article.status = 'draft';

// 3. Vérification des modifications
print(article.isDirty); // true
print(article.dirtyFields); // {'title', 'status'}

// 4. Sauvegarde (si ItemsService configuré)
await article.save();

// 5. État après sauvegarde
print(article.isDirty); // false (réinitialisé après save)

// 6. Suppression
await article.delete();
```

## 📊 Sérialisation JSON

### Conversion automatique

DirectusModel gère automatiquement la sérialisation/désérialisation :

```dart
// Depuis JSON
final article = Article.fromJson({
  'id': '1',
  'title': 'Article',
  'date_created': '2024-01-01T10:00:00Z',
});

// Vers JSON
final json = article.toJson();
// {
//   'id': '1',
//   'title': 'Article',
//   'date_created': '2024-01-01T10:00:00Z',
// }
```

### Types supportés

- **Primitifs** : String, int, double, bool
- **Dates** : DateTime (converti depuis/vers ISO 8601)
- **Collections** : List, Map
- **Relations** : DirectusModel (nested)
- **Null** : Géré automatiquement

### Conversion de types

```dart
class Product extends DirectusModel {
  // Conversions automatiques
  String get name => getString('name', defaultValue: 'Sans nom');
  int get stock => getInt('stock', defaultValue: 0);
  double get price => getDouble('price', defaultValue: 0.0);
  bool get available => getBool('available', defaultValue: false);
  DateTime? get createdAt => getDateTime('created_at');
  List<String> get tags => getList<String>('tags', defaultValue: []);
  
  // Conversion custom
  ProductStatus get status {
    final value = getString('status');
    return ProductStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ProductStatus.draft,
    );
  }
}
```

## 🔗 Relations

### Définir des relations

```dart
class Article extends DirectusModel {
  Article(super.data);
  
  @override
  String get itemName => 'articles';
  
  // Many-to-One (M2O): un article a un auteur
  User? get author => getModel<User>('author', (data) => User(data));
  
  // One-to-Many (O2M): un article a plusieurs commentaires
  List<Comment> get comments => 
    getModelList<Comment>('comments', (data) => Comment(data));
  
  // Many-to-Many (M2M): un article a plusieurs tags
  List<Tag> get tags => 
    getModelList<Tag>('tags', (data) => Tag(data));
}
```

### Charger des relations

```dart
// Charger avec deep query
final article = await directus.items('articles').readOne(
  id: '1',
  query: QueryParameters(
    deep: Deep({
      'author': DeepQuery().fields(['id', 'name']),
      'comments': DeepQuery().limit(10),
    }),
  ),
);

// Accéder aux relations
print(article.author?.name);
print('${article.comments.length} commentaires');
```

Voir [06-relationships.md](06-relationships.md) pour plus de détails.

## 🎨 Services et ItemsService

### ItemsService générique

`ItemsService<T>` est le service principal pour gérer vos collections :

```dart
// Service non typé (Map)
final articlesService = directus.items('articles');
final result = await articlesService.readMany();
// result.data est List<Map<String, dynamic>>

// Service typé (avec modèle)
final articlesService = directus.items<Article>('articles');
final result = await articlesService.readMany();
// result.data est List<Article>
```

### Enregistrer des factories

Pour utiliser un `ItemsService<T>` typé, enregistrez une factory :

```dart
// Enregistrer la factory
DirectusModel.registerFactory('articles', (data) => Article(data));

// Le service peut maintenant créer des instances Article
final service = directus.items<Article>('articles');
final articles = await service.readMany();
// articles.data contient des instances Article
```

### Services spécialisés

Pour certaines collections système, des services dédiés existent :

```dart
directus.users      // UsersService
directus.files      // FilesService
directus.folders    // FoldersService
directus.roles      // RolesService
directus.permissions // PermissionsService
// etc.
```

Voir [08-services.md](08-services.md) pour la liste complète.

## 🛠️ Configuration et client HTTP

### DirectusConfig

```dart
final config = DirectusConfig(
  baseUrl: 'https://api.example.com',
  timeout: Duration(seconds: 30),
  headers: {'X-Custom': 'value'},
  enableLogging: true,
);

final directus = DirectusClient(config);
```

### DirectusHttpClient

Le client HTTP interne gère :

- ✅ Authentification automatique
- ✅ Refresh tokens
- ✅ Gestion des erreurs
- ✅ Conversion JSON
- ✅ Timeouts
- ✅ Logging

```dart
// Accès bas niveau (rarement nécessaire)
final response = await directus.http.get('/items/articles');
```

## 📝 QueryParameters

Classe unifiée pour construire des requêtes complexes :

```dart
final query = QueryParameters(
  // Filtres
  filter: {'status': {'_eq': 'published'}},
  
  // Tri
  sort: ['-date_created', 'title'],
  
  // Pagination
  limit: 20,
  offset: 0,
  
  // Sélection de champs
  fields: ['id', 'title', 'author.name'],
  
  // Relations (deep)
  deep: Deep({'author': DeepQuery().fields(['id', 'name'])}),
  
  // Recherche full-text
  search: 'mot-clé',
  
  // Agrégations
  aggregate: Aggregate()
    ..count('id')
    ..sum('price'),
  
  // Groupement
  groupBy: ['category'],
  
  // Métadonnées
  meta: '*',
);

final result = await directus.items('articles').readMany(query: query);
```

## 💡 Bonnes pratiques

### 1. Utiliser les modèles typés

✅ **Bon** :
```dart
class Article extends DirectusModel {
  String get title => getString('title');
}
```

❌ **À éviter** :
```dart
final title = data['title'] as String; // Pas de validation, erreurs runtime
```

### 2. Enregistrer les factories

```dart
void initDirectus() {
  DirectusModel.registerFactory('articles', (data) => Article(data));
  DirectusModel.registerFactory('users', (data) => User(data));
  DirectusModel.registerFactory('comments', (data) => Comment(data));
}
```

### 3. Gérer les erreurs

```dart
try {
  final result = await directus.items('articles').readMany();
} on DirectusException catch (e) {
  print('Erreur Directus: ${e.message}');
}
```

### 4. Utiliser le tracking des modifications

```dart
if (article.isDirty) {
  final changes = article.getChanges();
  await article.save(); // Sauvegarde uniquement les modifications
}
```

### 5. Limiter les champs retournés

```dart
// ❌ Charge tous les champs
await directus.items('articles').readMany();

// ✅ Charge uniquement les champs nécessaires
await directus.items('articles').readMany(
  query: QueryParameters(fields: ['id', 'title', 'status']),
);
```

## 🔗 Prochaines étapes

- [**Authentication**](03-authentication.md) - Gestion de l'authentification
- [**Models**](04-models.md) - Créer vos modèles personnalisés
- [**Queries**](05-queries.md) - Maîtriser le système de requêtes
- [**Relationships**](06-relationships.md) - Gérer les relations

## 📚 Référence API

- [DirectusModel](api-reference/models/directus-model.md)
- [Property Wrappers](api-reference/models/property-wrappers.md)
- [ItemsService](api-reference/services/items-service.md)

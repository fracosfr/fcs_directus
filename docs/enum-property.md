# EnumProperty - Wrapper pour Enums

Le wrapper `EnumProperty` permet de convertir automatiquement les valeurs String stockées dans Directus en enums Dart typés, offrant ainsi une meilleure sécurité de type et une API plus claire.

## Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Utilisation basique](#utilisation-basique)
- [Conversion automatique](#conversion-automatique)
- [Gestion des valeurs invalides](#gestion-des-valeurs-invalides)
- [Méthodes utilitaires](#méthodes-utilitaires)
- [Exemples avancés](#exemples-avancés)
- [Best Practices](#best-practices)

## Vue d'ensemble

Directus stocke les valeurs d'enum sous forme de chaînes de caractères (String). Le wrapper `EnumProperty` :

✅ Convertit automatiquement String ↔ Enum  
✅ Gère les valeurs invalides avec fallback  
✅ Est insensible à la casse  
✅ Fournit des méthodes utilitaires (`is_`, `isOneOf`, etc.)  
✅ S'intègre avec le dirty tracking  
✅ Type-safe grâce aux génériques  

## Utilisation basique

### Définir un enum et l'utiliser dans un modèle

```dart
// 1. Définir votre enum
enum ArticleStatus {
  draft,
  review,
  published,
  archived,
}

// 2. Utiliser dans votre modèle DirectusModel
class Article extends DirectusModel {
  Article(super.data);

  @override
  String get itemName => 'articles';

  late final title = stringValue('title');
  
  // 3. Créer le property wrapper
  late final status = enumValue<ArticleStatus>(
    'status',                  // Nom du champ dans Directus
    ArticleStatus.draft,       // Valeur par défaut
    ArticleStatus.values,      // IMPORTANT: Toutes les valeurs de l'enum
  );
}
```

### Lecture et écriture

```dart
final article = Article({'status': 'published'});

// Lecture - retourne l'enum typé
ArticleStatus status = article.status.value;
print(status); // ArticleStatus.published

// Lecture sous forme de String
String statusStr = article.status.asString;
print(statusStr); // "published"

// Écriture avec l'enum
article.status.set(ArticleStatus.draft);

// Écriture depuis un String
article.status.setFromString('review');
```

## Conversion automatique

### Depuis Directus (String → Enum)

Lorsque vous récupérez des données depuis Directus :

```dart
// Données de Directus
{
  "id": "123",
  "title": "Mon article",
  "status": "published"  // ← String
}

// Automatiquement converti en enum
final article = Article(data);
print(article.status.value); // ArticleStatus.published (Enum)
```

### Vers Directus (Enum → String)

Lorsque vous sauvegardez vers Directus :

```dart
final article = Article.empty();
article.status.set(ArticleStatus.published);

final json = article.toJson();
// Résultat: {"status": "published"}  ← Automatiquement converti en String
```

### Insensibilité à la casse

La conversion est insensible à la casse :

```dart
// Toutes ces valeurs sont converties en ArticleStatus.published
Article({'status': 'published'});  // ✓
Article({'status': 'PUBLISHED'});  // ✓
Article({'status': 'Published'});  // ✓
Article({'status': 'PuBlIsHeD'});  // ✓
```

## Gestion des valeurs invalides

### Valeur invalide dans les données

Si la valeur String ne correspond à aucune valeur de l'enum, la valeur par défaut est utilisée :

```dart
enum Status { draft, published, archived }

class Article extends DirectusModel {
  late final status = enumValue<Status>(
    'status',
    Status.draft,  // ← Valeur par défaut utilisée en cas d'erreur
    Status.values,
  );
}

// Valeur invalide dans les données
final article = Article({'status': 'unknown_status'});
print(article.status.value); // Status.draft (fallback)
```

### Valeur absente (null)

Si le champ n'existe pas dans les données :

```dart
final article = Article({}); // Pas de champ 'status'
print(article.status.value); // Status.draft (valeur par défaut)
```

### setFromString avec valeur invalide

```dart
article.status.setFromString('invalid_value');
print(article.status.value); // Status.draft (fallback)
```

## Méthodes utilitaires

### `is_()` - Vérifier une valeur spécifique

```dart
if (article.status.is_(ArticleStatus.published)) {
  print('Article publié !');
}

// Équivalent à:
if (article.status.value == ArticleStatus.published) {
  print('Article publié !');
}
```

### `isOneOf()` - Vérifier plusieurs valeurs

```dart
if (article.status.isOneOf([ArticleStatus.draft, ArticleStatus.review])) {
  print('Article éditable');
}
```

### `allValues` - Toutes les valeurs possibles

```dart
print('Statuts disponibles:');
for (final status in article.status.allValues) {
  print('  - $status');
}

// Output:
// Statuts disponibles:
//   - ArticleStatus.draft
//   - ArticleStatus.review
//   - ArticleStatus.published
//   - ArticleStatus.archived
```

### `reset()` - Retourner à la valeur par défaut

```dart
article.status.set(ArticleStatus.published);
print(article.status.value); // ArticleStatus.published

article.status.reset();
print(article.status.value); // ArticleStatus.draft
```

### `asString` - Obtenir la représentation String

```dart
print(article.status.asString); // "published"
```

## Exemples avancés

### Multiples enums dans un modèle

```dart
enum Priority { low, medium, high, urgent }
enum TaskStatus { todo, inProgress, done, cancelled }

class Task extends DirectusModel {
  Task(super.data);

  @override
  String get itemName => 'tasks';

  late final title = stringValue('title');
  late final status = enumValue<TaskStatus>(
    'status',
    TaskStatus.todo,
    TaskStatus.values,
  );
  late final priority = enumValue<Priority>(
    'priority',
    Priority.medium,
    Priority.values,
  );
}

// Utilisation
final task = Task({
  'title': 'Corriger le bug',
  'status': 'inProgress',
  'priority': 'urgent',
});

if (task.status.is_(TaskStatus.inProgress) && 
    task.priority.is_(Priority.urgent)) {
  print('⚠️ Tâche urgente en cours !');
}
```

### Logique métier avec enums

```dart
class Article extends DirectusModel {
  late final status = enumValue<ArticleStatus>(
    'status',
    ArticleStatus.draft,
    ArticleStatus.values,
  );

  // Getters dérivés basés sur l'enum
  bool get isPublished => status.is_(ArticleStatus.published);
  bool get isDraft => status.is_(ArticleStatus.draft);
  
  bool get canEdit => status.isOneOf([
    ArticleStatus.draft,
    ArticleStatus.review,
  ]);
  
  bool get isVisible => status.isOneOf([
    ArticleStatus.published,
  ]);
}

// Utilisation
if (article.canEdit) {
  // Permettre l'édition
}

if (article.isVisible) {
  // Afficher publiquement
}
```

### Workflow de statut

```dart
class Order extends DirectusModel {
  late final status = enumValue<OrderStatus>(
    'status',
    OrderStatus.pending,
    OrderStatus.values,
  );

  void markAsPaid() {
    if (status.is_(OrderStatus.pending)) {
      status.set(OrderStatus.paid);
    }
  }

  void ship() {
    if (status.is_(OrderStatus.paid)) {
      status.set(OrderStatus.shipped);
    }
  }

  void complete() {
    if (status.is_(OrderStatus.shipped)) {
      status.set(OrderStatus.completed);
    }
  }
}
```

### Dirty tracking avec enums

```dart
final article = Article({'status': 'draft'});
article.markClean(); // Marquer comme propre

// Modifier le statut
article.status.set(ArticleStatus.published);

// Vérifier si modifié
print(article.isDirty); // true
print(article.dirtyFields); // {'status'}

// Voir les modifications
final dirty = article.toJsonDirty();
print(dirty); // {"status": "published"}

// Sauvegarder vers Directus
await client.items('articles').updateOne(article.id!, dirty);

// Marquer comme propre après sauvegarde
article.markClean();
```

### Validation de statut

```dart
class Article extends DirectusModel {
  late final status = enumValue<ArticleStatus>(
    'status',
    ArticleStatus.draft,
    ArticleStatus.values,
  );

  bool canPublish() {
    return status.isOneOf([ArticleStatus.draft, ArticleStatus.review]);
  }

  bool canArchive() {
    return status.is_(ArticleStatus.published);
  }

  void publish() {
    if (!canPublish()) {
      throw StateError('Cannot publish article in status ${status.value}');
    }
    status.set(ArticleStatus.published);
  }
}
```

## Best Practices

### ✅ DO

**1. Toujours passer toutes les valeurs de l'enum**

```dart
// ✅ Bon
late final status = enumValue<Status>(
  'status',
  Status.draft,
  Status.values,  // ← Passez TOUJOURS EnumType.values
);
```

**2. Choisir une valeur par défaut sensée**

```dart
// ✅ Bon - 'draft' est une valeur par défaut logique
late final status = enumValue<ArticleStatus>(
  'status',
  ArticleStatus.draft,  // Par défaut, un article est en brouillon
  ArticleStatus.values,
);
```

**3. Utiliser des noms d'enum cohérents avec Directus**

```dart
// ✅ Bon - Les noms correspondent exactement aux valeurs Directus
enum ArticleStatus {
  draft,      // Directus: "draft"
  published,  // Directus: "published"
  archived,   // Directus: "archived"
}
```

**4. Créer des getters dérivés pour la logique métier**

```dart
// ✅ Bon
class Article extends DirectusModel {
  late final status = enumValue<ArticleStatus>(...);

  bool get isPublished => status.is_(ArticleStatus.published);
  bool get canEdit => status.isOneOf([...]);
}
```

### ❌ DON'T

**1. Ne pas oublier de passer les valeurs de l'enum**

```dart
// ❌ Mauvais - Manque le 3ème paramètre
late final status = enumValue<Status>('status', Status.draft);
```

**2. Ne pas utiliser des noms d'enum qui ne matchent pas Directus**

```dart
// ❌ Mauvais - Les noms ne correspondent pas
enum ArticleStatus {
  DRAFT,         // Directus utilise "draft" (minuscules)
  IN_REVIEW,     // Directus utilise "review"
  PUBLISHED_NOW, // Directus utilise "published"
}

// Note: La conversion est insensible à la casse, mais évitez
// les underscores si Directus n'en utilise pas
```

**3. Ne pas mélanger enum et String**

```dart
// ❌ Mauvais
if (article.status.asString == 'published') { ... }

// ✅ Bon
if (article.status.is_(ArticleStatus.published)) { ... }
```

**4. Ne pas comparer directement avec .value dans les conditions complexes**

```dart
// ❌ Mauvais (verbeux)
if (article.status.value == ArticleStatus.published &&
    article.visibility.value == Visibility.public) { ... }

// ✅ Bon (plus clair)
if (article.status.is_(ArticleStatus.published) &&
    article.visibility.is_(Visibility.public)) { ... }
```

## Cas d'usage courants

### E-commerce - Statut de commande

```dart
enum OrderStatus {
  pending,
  paid,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
}

class Order extends DirectusModel {
  late final status = enumValue<OrderStatus>(
    'status',
    OrderStatus.pending,
    OrderStatus.values,
  );
}
```

### Blog/CMS - Statut de publication

```dart
enum PublicationStatus {
  draft,
  review,
  scheduled,
  published,
  archived,
}
```

### Gestion de projet - Statut de tâche

```dart
enum TaskStatus {
  backlog,
  todo,
  inProgress,
  review,
  done,
  cancelled,
}
```

### Utilisateurs - Statut d'activité

```dart
enum UserStatus {
  active,
  inactive,
  suspended,
  banned,
  deleted,
}
```

## Voir aussi

- [Property Wrappers](./04-models.md#property-wrappers)
- [DirectusModel](./04-models.md)
- [Dirty Tracking](./04-models.md#dirty-tracking)
- [Exemples complets](../example/example_enum_property.dart)

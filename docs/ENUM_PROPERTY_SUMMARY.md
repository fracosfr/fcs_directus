# EnumProperty - Résumé de l'implémentation

## Vue d'ensemble

Ajout d'un nouveau property wrapper `EnumProperty<T>` pour gérer automatiquement la conversion entre les valeurs String stockées dans Directus et les enums Dart typés.

## Fichiers modifiés

### 1. `/lib/src/models/directus_property.dart`

**Ajout de la classe `EnumProperty<T extends Enum>`** :

- ✅ Conversion automatique String ↔ Enum
- ✅ Insensible à la casse
- ✅ Gestion des valeurs invalides avec fallback vers la valeur par défaut
- ✅ Méthodes utilitaires : `is_()`, `isOneOf()`, `allValues`, `reset()`
- ✅ Propriété `asString` pour obtenir la représentation String
- ✅ Méthode `setFromString()` pour définir depuis un String

**Signature** :
```dart
class EnumProperty<T extends Enum> extends DirectusProperty<T> {
  EnumProperty(
    DirectusModel model,
    String name,
    T defaultValue,
    List<T> enumValues,
  );
}
```

### 2. `/lib/src/models/directus_model.dart`

**Ajout de la méthode factory `enumValue<T>()`** :

```dart
EnumProperty<T> enumValue<T extends Enum>(
  String key,
  T defaultValue,
  List<T> values,
)
```

**Utilisation** :
```dart
late final status = enumValue<ArticleStatus>(
  'status',
  ArticleStatus.draft,    // Valeur par défaut
  ArticleStatus.values,   // Toutes les valeurs de l'enum
);
```

### 3. `/test/enum_property_test.dart`

**21 tests unitaires couvrant** :
- ✅ Conversion String → Enum
- ✅ Conversion Enum → String
- ✅ Gestion des valeurs invalides
- ✅ Gestion des valeurs absentes (null)
- ✅ Insensibilité à la casse
- ✅ Méthodes `is_()` et `isOneOf()`
- ✅ Getter `allValues`
- ✅ Méthode `reset()`
- ✅ Méthode `setFromString()`
- ✅ Dirty tracking
- ✅ Sérialisation (toJson/toJsonDirty)
- ✅ Enums avec camelCase
- ✅ Multiples enums dans le même modèle

**Résultat** : ✅ **21/21 tests passent**

### 4. `/example/example_enum_property.dart`

**Exemple complet démontrant** :
- Définition d'enums (ArticleStatus, Visibility, ProductStatus, Priority, TaskStatus)
- Utilisation dans des modèles DirectusModel
- Lecture et écriture de valeurs enum
- Gestion des valeurs invalides
- Méthodes utilitaires
- Enums complexes avec logique métier
- Dirty tracking avec enums

**Structure** :
- 5 exemples détaillés
- 5 enums différents
- 3 modèles d'exemple (Article, Product, Task)

### 5. `/docs/enum-property.md`

**Documentation complète incluant** :
- Vue d'ensemble et avantages
- Utilisation basique
- Conversion automatique (String ↔ Enum)
- Gestion des valeurs invalides
- Méthodes utilitaires avec exemples
- Exemples avancés (workflow, logique métier, validation)
- Best practices (DO/DON'T)
- Cas d'usage courants

## Fonctionnalités clés

### ✅ Conversion automatique

```dart
// Directus → Dart
{'status': 'published'} → ArticleStatus.published

// Dart → Directus  
ArticleStatus.draft → {'status': 'draft'}
```

### ✅ Insensibilité à la casse

```dart
'PUBLISHED' → ArticleStatus.published
'Published' → ArticleStatus.published
'published' → ArticleStatus.published
```

### ✅ Fallback sécurisé

```dart
// Valeur invalide → Utilise la valeur par défaut
'unknown_status' → ArticleStatus.draft (default)
```

### ✅ API intuitive

```dart
// Vérifier la valeur
if (article.status.is_(ArticleStatus.published)) { ... }

// Vérifier plusieurs valeurs
if (article.status.isOneOf([ArticleStatus.draft, ArticleStatus.review])) { ... }

// Obtenir toutes les valeurs possibles
final all = article.status.allValues;

// Reset
article.status.reset();
```

### ✅ Type-safe

```dart
ArticleStatus status = article.status.value; // Type-safe ✓
String statusStr = article.status.asString;   // Type-safe ✓
```

## Utilisation

### Définir un enum et l'utiliser

```dart
enum ArticleStatus {
  draft,
  review,
  published,
  archived,
}

class Article extends DirectusModel {
  Article(super.data);

  @override
  String get itemName => 'articles';

  late final status = enumValue<ArticleStatus>(
    'status',                  // Nom du champ
    ArticleStatus.draft,       // Valeur par défaut
    ArticleStatus.values,      // Toutes les valeurs
  );
}
```

### Lire et écrire

```dart
// Lecture
ArticleStatus status = article.status.value;
String statusStr = article.status.asString;

// Écriture
article.status.set(ArticleStatus.published);
article.status.setFromString('draft');
```

### Utiliser dans la logique métier

```dart
class Article extends DirectusModel {
  late final status = enumValue<ArticleStatus>(...);

  bool get isPublished => status.is_(ArticleStatus.published);
  bool get canEdit => status.isOneOf([
    ArticleStatus.draft,
    ArticleStatus.review,
  ]);
}
```

## Tests

**Commande** :
```bash
flutter test test/enum_property_test.dart
```

**Résultat** :
```
✓ 21/21 tests passed
```

**Couverture** :
- Conversion bidirectionnelle
- Gestion des erreurs
- API complète
- Dirty tracking
- Sérialisation

## Impact

### Avantages

✅ **Type-safety** : Utilisation d'enums au lieu de Strings  
✅ **Lisibilité** : Code plus clair et auto-documenté  
✅ **Sécurité** : Gestion automatique des valeurs invalides  
✅ **Cohérence** : API uniforme avec les autres property wrappers  
✅ **Maintenabilité** : Modification d'enum reflétée partout  
✅ **Productivité** : Moins de code boilerplate  

### Compatibilité

✅ Compatible avec le dirty tracking existant  
✅ Compatible avec `toJson()` et `toJsonDirty()`  
✅ S'intègre parfaitement avec les autres property wrappers  
✅ Aucune breaking change  
✅ Rétrocompatible avec les approches existantes  

## Exemple complet

```dart
enum ArticleStatus { draft, published, archived }

class Article extends DirectusModel {
  Article(super.data);

  @override
  String get itemName => 'articles';

  late final title = stringValue('title');
  late final status = enumValue<ArticleStatus>(
    'status',
    ArticleStatus.draft,
    ArticleStatus.values,
  );

  bool get isPublished => status.is_(ArticleStatus.published);
}

void main() async {
  // Données de Directus
  final article = Article({
    'id': '123',
    'title': 'Mon article',
    'status': 'published',  // String
  });

  // Utilisation type-safe
  if (article.isPublished) {
    print('Article publié: ${article.title.value}');
  }

  // Modification
  article.status.set(ArticleStatus.archived);

  // Sauvegarder vers Directus
  final json = article.toJsonDirty();
  // {"status": "archived"}
}
```

## Conclusion

L'ajout du wrapper `EnumProperty` améliore significativement l'expérience développeur en offrant :

- **Type-safety** pour les enums
- **API simple et intuitive**
- **Gestion robuste des erreurs**
- **Documentation complète**
- **Tests exhaustifs**

Cette fonctionnalité s'intègre parfaitement au système de property wrappers existant et suit les mêmes conventions et patterns.

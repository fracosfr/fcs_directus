# DirectusModel - Guide d'utilisation

## 🎯 Qu'est-ce que DirectusModel ?

`DirectusModel` est une classe abstraite qui facilite la création de modèles Dart pour vos collections Directus. Elle gère automatiquement les champs standards de Directus et fournit des helpers pour la sérialisation JSON.

## ✨ Avantages

- ✅ **Moins de code** - Pas besoin de gérer manuellement `id`, `date_created`, `date_updated`
- ✅ **Type-safe** - Helpers avec gestion des types et nullabilité
- ✅ **Consistency** - Tous vos modèles suivent le même pattern
- ✅ **Equals & HashCode** - Implémentation automatique basée sur l'ID
- ✅ **toString()** - Représentation textuelle cohérente

## 📖 Comment l'utiliser

### 1. Créer un modèle simple

```dart
import 'package:fcs_directus/fcs_directus.dart';

class Product extends DirectusModel {
  final String name;
  final double price;
  final int stock;

  Product({
    super.id,                    // Hérité de DirectusModel
    required this.name,
    required this.price,
    this.stock = 0,
    super.dateCreated,           // Hérité de DirectusModel
    super.dateUpdated,           // Hérité de DirectusModel
  });

  // Convertir JSON → Product
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: DirectusModel.parseId(json['id']),           // Helper pour ID
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
      dateCreated: DirectusModel.parseDate(json['date_created']),  // Helper pour dates
      dateUpdated: DirectusModel.parseDate(json['date_updated']),
    );
  }

  // Convertir Product → Map (uniquement vos champs)
  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stock': stock,
    };
  }

  @override
  String toString() => 'Product(name: $name, price: $price€)';
}
```

### 2. Utilisation avec le service Items

```dart
final productsService = client.items<Product>('products');

// Créer
final newProduct = Product(
  name: 'Laptop',
  price: 999.99,
  stock: 10,
);

final created = await productsService.createOne(
  newProduct.toJson(),  // toJson() combine automatiquement toMap() + champs de base
  fromJson: Product.fromJson,
) as Product;

print(created.id);           // Auto-géré
print(created.dateCreated);  // Auto-géré
print(created.name);         // Votre champ

// Lire
final product = await productsService.readOne(
  '123',
  fromJson: Product.fromJson,
) as Product;

// Mettre à jour
await productsService.updateOne(
  product.id!,
  {'stock': product.stock + 5},
  fromJson: Product.fromJson,
);
```

## 🔧 Champs et méthodes

### Champs hérités

```dart
String? id;           // ID de l'item
DateTime? dateCreated;  // Date de création (date_created)
DateTime? dateUpdated;  // Date de mise à jour (date_updated)
```

### Méthodes à implémenter

```dart
@override
Map<String, dynamic> toMap();  // Retourne uniquement VOS champs
```

### Méthodes fournies

```dart
Map<String, dynamic> toJson();  // Combine toMap() + champs de base
String toString();              // Affichage: "YourModel(id: 123)"
bool operator ==(Object other); // Comparaison par ID et type
int get hashCode;               // HashCode basé sur ID et type
```

### Helpers statiques

```dart
// Parse une date depuis différents formats
DateTime? parseDate(dynamic value);
// null → null
// "2024-01-01" → DateTime(2024, 1, 1)
// DateTime → DateTime
// "invalid" → null

// Parse un ID depuis différents types
String? parseId(dynamic value);
// null → null
// 123 → "123"
// "abc" → "abc"
// true → "true"
```

## 📝 Exemples avancés

### Modèle avec relations

```dart
class Article extends DirectusModel {
  final String title;
  final String? content;
  final String status;
  final User? author;  // Relation

  Article({
    super.id,
    required this.title,
    this.content,
    this.status = 'draft',
    super.dateCreated,
    super.dateUpdated,
    this.author,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: DirectusModel.parseId(json['id']),
      title: json['title'] as String,
      content: json['content'] as String?,
      status: json['status'] as String? ?? 'draft',
      dateCreated: DirectusModel.parseDate(json['date_created']),
      dateUpdated: DirectusModel.parseDate(json['date_updated']),
      author: json['author'] != null
          ? User.fromJson(json['author'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      if (content != null) 'content': content,
      'status': status,
      if (author != null) 'author': author!.id,  // Seulement l'ID pour la relation
    };
  }
}
```

### Modèle avec champs personnalisés Directus

```dart
class Task extends DirectusModel {
  final String title;
  final bool completed;
  final String? userCreated;  // Champ Directus standard supplémentaire
  final String? userUpdated;  // Champ Directus standard supplémentaire

  Task({
    super.id,
    required this.title,
    this.completed = false,
    super.dateCreated,
    super.dateUpdated,
    this.userCreated,
    this.userUpdated,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: DirectusModel.parseId(json['id']),
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
      dateCreated: DirectusModel.parseDate(json['date_created']),
      dateUpdated: DirectusModel.parseDate(json['date_updated']),
      userCreated: DirectusModel.parseId(json['user_created']),
      userUpdated: DirectusModel.parseId(json['user_updated']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'completed': completed,
    };
  }
}
```

## 💡 Bonnes pratiques

### ✅ À faire

- Toujours utiliser les helpers `parseId()` et `parseDate()`
- Implémenter `toString()` pour faciliter le debug
- Gérer les champs optionnels avec des valeurs par défaut
- Utiliser `if` dans `toMap()` pour exclure les champs null

### ❌ À éviter

- Ne pas gérer manuellement les dates ISO dans `fromJson`
- Ne pas oublier d'appeler `super.id`, `super.dateCreated`, etc.
- Ne pas inclure `id` et les dates dans `toMap()` (c'est fait par `toJson()`)

## 🔄 Migration depuis un modèle classique

### Avant (sans DirectusModel)

```dart
class Product {
  final String? id;
  final String name;
  final double price;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;

  Product({
    this.id,
    required this.name,
    required this.price,
    this.dateCreated,
    this.dateUpdated,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString(),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      dateCreated: json['date_created'] != null
          ? DateTime.parse(json['date_created'] as String)
          : null,
      dateUpdated: json['date_updated'] != null
          ? DateTime.parse(json['date_updated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      if (dateCreated != null) 'date_created': dateCreated!.toIso8601String(),
      if (dateUpdated != null) 'date_updated': dateUpdated!.toIso8601String(),
    };
  }
}
```

### Après (avec DirectusModel) ✨

```dart
class Product extends DirectusModel {
  final String name;
  final double price;

  Product({
    super.id,
    required this.name,
    required this.price,
    super.dateCreated,
    super.dateUpdated,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: DirectusModel.parseId(json['id']),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      dateCreated: DirectusModel.parseDate(json['date_created']),
      dateUpdated: DirectusModel.parseDate(json['date_updated']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }
}
```

**Gain: -15 lignes de code, plus maintenable, plus cohérent !**

## 📚 Voir aussi

- [Example: custom_model.dart](../example/custom_model.dart)
- [Example: directus_model_example.dart](../example/directus_model_example.dart)
- [Tests: directus_model_test.dart](../test/models/directus_model_test.dart)

# Aggregations

Guide des fonctions d'agrégation et de groupement dans fcs_directus.

## 📊 Introduction

Les agrégations permettent de calculer des statistiques sur vos données (count, sum, avg, min, max) directement dans Directus, sans charger toutes les données.

## 🔧 Syntaxe de base

```dart
import 'package:fcs_directus/fcs_directus.dart';

final result = await directus.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count('id')
      ..sum('price')
      ..avg('rating'),
  ),
);

print('Total produits: ${result.data?[0]['count']['id']}');
print('Prix total: ${result.data?[0]['sum']['price']}');
print('Note moyenne: ${result.data?[0]['avg']['rating']}');
```

## 📈 Fonctions d'agrégation

### count() - Compter

```dart
// Compter les produits
Aggregate().count('id')

// Compter les produits avec un nom
Aggregate().count('name')

// Compter tous les items (*)
Aggregate().count('*')
```

### sum() - Somme

```dart
// Somme des prix
Aggregate().sum('price')

// Somme des stocks
Aggregate().sum('stock')
```

### avg() - Moyenne

```dart
// Prix moyen
Aggregate().avg('price')

// Note moyenne
Aggregate().avg('rating')
```

### min() - Minimum

```dart
// Prix minimum
Aggregate().min('price')

// Date la plus ancienne
Aggregate().min('date_created')
```

### max() - Maximum

```dart
// Prix maximum
Aggregate().max('price')

// Date la plus récente
Aggregate().max('date_created')
```

### countDistinct() - Compter les valeurs uniques

```dart
// Nombre de catégories différentes
Aggregate().countDistinct('category')

// Nombre d'auteurs différents
Aggregate().countDistinct('author')
```

## 🎯 Agrégations multiples

```dart
final stats = await directus.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count('id', alias: 'total')
      ..sum('price', alias: 'total_value')
      ..avg('price', alias: 'avg_price')
      ..min('price', alias: 'min_price')
      ..max('price', alias: 'max_price')
      ..countDistinct('category', alias: 'categories_count'),
  ),
);

final data = stats.data?.first;
print('Total produits: ${data?['total']}');
print('Valeur totale: ${data?['total_value']}');
print('Prix moyen: ${data?['avg_price']}');
print('Prix min: ${data?['min_price']}');
print('Prix max: ${data?['max_price']}');
print('Nombre de catégories: ${data?['categories_count']}');
```

## 📊 Groupement (GROUP BY)

### Grouper par un champ

```dart
// Statistiques par catégorie
final result = await directus.items('products').readMany(
  query: QueryParameters(
    groupBy: ['category'],
    aggregate: Aggregate()
      ..count('id', alias: 'count')
      ..avg('price', alias: 'avg_price'),
  ),
);

// Résultat:
// [
//   {'category': 'electronics', 'count': 50, 'avg_price': 299.99},
//   {'category': 'books', 'count': 120, 'avg_price': 15.50},
//   {'category': 'clothing', 'count': 80, 'avg_price': 45.00},
// ]
```

### Grouper par plusieurs champs

```dart
// Statistiques par catégorie et statut
final result = await directus.items('products').readMany(
  query: QueryParameters(
    groupBy: ['category', 'status'],
    aggregate: Aggregate()
      ..count('id')
      ..sum('stock'),
  ),
);
```

## 🎨 Agrégations avec filtres

```dart
// Statistiques des produits publiés uniquement
final result = await directus.items('products').readMany(
  query: QueryParameters(
    filter: Filter.field('status').equals('published'),
    aggregate: Aggregate()
      ..count('id')
      ..avg('price')
      ..sum('stock'),
  ),
);
```

## 💡 Exemples pratiques

### Dashboard e-commerce

```dart
class DashboardService {
  final DirectusClient directus;
  
  DashboardService(this.directus);
  
  Future<Map<String, dynamic>> getStats() async {
    final result = await directus.items('products').readMany(
      query: QueryParameters(
        aggregate: Aggregate()
          ..count('id', alias: 'total_products')
          ..sum('stock', alias: 'total_stock')
          ..sum('price', alias: 'inventory_value')
          ..avg('price', alias: 'avg_price')
          ..count('*', where: {'stock': {'_eq': 0}}, alias: 'out_of_stock'),
      ),
    );
    
    return result.data?.first ?? {};
  }
  
  Future<List<Map<String, dynamic>>> getStatsByCategory() async {
    final result = await directus.items('products').readMany(
      query: QueryParameters(
        groupBy: ['category'],
        aggregate: Aggregate()
          ..count('id', alias: 'count')
          ..sum('stock', alias: 'total_stock')
          ..avg('price', alias: 'avg_price'),
        sort: ['-count'],
      ),
    );
    
    return result.data ?? [];
  }
}
```

### Statistiques d'articles de blog

```dart
Future<Map<String, dynamic>> getBlogStats() async {
  final result = await directus.items('articles').readMany(
    query: QueryParameters(
      aggregate: Aggregate()
        ..count('id', alias: 'total_articles')
        ..countDistinct('author', alias: 'total_authors')
        ..avg('view_count', alias: 'avg_views')
        ..max('date_created', alias: 'latest_article'),
      filter: Filter.field('status').equals('published'),
    ),
  );
  
  return result.data?.first ?? {};
}
```

### Analyse des ventes

```dart
Future<List<Map<String, dynamic>>> getSalesAnalysis() async {
  final result = await directus.items('orders').readMany(
    query: QueryParameters(
      groupBy: ['status'],
      aggregate: Aggregate()
        ..count('id', alias: 'order_count')
        ..sum('total_amount', alias: 'total_revenue')
        ..avg('total_amount', alias: 'avg_order_value')
        ..min('total_amount', alias: 'min_order')
        ..max('total_amount', alias: 'max_order'),
      filter: Filter.field('date_created')
        .greaterThanOrEqual('2024-01-01'),
    ),
  );
  
  return result.data ?? [];
}
```

## 🔗 Prochaines étapes

- [**Services**](08-services.md) - Services disponibles
- [**Queries**](05-queries.md) - Système de requêtes et filtres

## 📚 Référence API

- [DirectusAggregate](api-reference/models/directus-aggregate.md)
- [ItemsService](api-reference/services/items-service.md)

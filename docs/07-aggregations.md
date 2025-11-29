# Agrégations

Ce guide explique comment effectuer des calculs statistiques sur vos données Directus.

## Introduction

Les agrégations permettent d'obtenir des statistiques sans charger tous les items :
- Comptage
- Sommes
- Moyennes
- Min/Max
- GroupBy

## Classe Aggregate

### Création

```dart
final aggregate = Aggregate();
```

### Méthodes d'agrégation

Toutes les méthodes retournent l'instance pour permettre le chaînage :

```dart
final aggregate = Aggregate()
  ..count(['*'])
  ..sum(['price', 'quantity'])
  ..avg(['rating'])
  ..min(['price'])
  ..max(['price']);
```

## Fonctions d'agrégation

### Count (Comptage)

```dart
// Compter tous les items
final agg = Aggregate()..count(['*']);

// Compter les valeurs non-null d'un champ
final agg = Aggregate()..count(['category']);
```

### CountDistinct (Comptage distinct)

```dart
// Compter les valeurs uniques
final agg = Aggregate()..countDistinct(['category']);

// Plusieurs champs
final agg = Aggregate()..countDistinct(['category', 'status']);
```

### Sum (Somme)

```dart
final agg = Aggregate()..sum(['price', 'quantity']);
```

### Avg (Moyenne)

```dart
final agg = Aggregate()..avg(['rating', 'price']);
```

### Min (Minimum)

```dart
final agg = Aggregate()..min(['price', 'date_created']);
```

### Max (Maximum)

```dart
final agg = Aggregate()..max(['price', 'view_count']);
```

## Utilisation avec QueryParameters

```dart
final response = await client.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()..count(['*']),
  ),
);

// Accéder au résultat
final count = response.data.first['count']['*'];
print('Total: $count produits');
```

## GroupBy

Groupez les résultats par un ou plusieurs champs :

### GroupBy simple

```dart
final response = await client.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()..count(['*']),
    groupBy: GroupBy.fields(['category']),
  ),
);

// Résultat
for (final group in response.data) {
  print('${group['category']}: ${group['count']['*']} produits');
}
```

### GroupBy multiple

```dart
final response = await client.items('orders').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count(['*'])
      ..sum(['total']),
    groupBy: GroupBy.fields(['status', 'year(date_created)']),
  ),
);
```

### Fonctions de date dans GroupBy

Directus supporte des fonctions pour extraire des parties de dates :

```dart
// Par année
GroupBy.fields(['year(date_created)'])

// Par mois
GroupBy.fields(['month(date_created)'])

// Par jour
GroupBy.fields(['day(date_created)'])

// Par heure
GroupBy.fields(['hour(date_created)'])

// Combinés
GroupBy.fields(['year(date_created)', 'month(date_created)'])
```

## Exemples complets

### Statistiques de produits

```dart
final stats = await client.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count(['*'])
      ..sum(['stock'])
      ..avg(['price'])
      ..min(['price'])
      ..max(['price']),
  ),
);

final data = stats.data.first;
print('Nombre de produits: ${data['count']['*']}');
print('Stock total: ${data['sum']['stock']}');
print('Prix moyen: ${data['avg']['price']}');
print('Prix min: ${data['min']['price']}');
print('Prix max: ${data['max']['price']}');
```

### Ventes par catégorie

```dart
final sales = await client.items('order_items').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count(['*'])
      ..sum(['quantity', 'total']),
    groupBy: GroupBy.fields(['product.category']),
  ),
);

for (final category in sales.data) {
  print('Catégorie: ${category['product']['category']}');
  print('  Ventes: ${category['count']['*']}');
  print('  Quantité: ${category['sum']['quantity']}');
  print('  Total: ${category['sum']['total']}€');
}
```

### Évolution mensuelle

```dart
final monthly = await client.items('orders').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count(['*'])
      ..sum(['total']),
    groupBy: GroupBy.fields([
      'year(date_created)',
      'month(date_created)',
    ]),
    filter: Filter.field('status').equals('completed'),
  ),
);

for (final month in monthly.data) {
  final year = month['date_created_year'];
  final monthNum = month['date_created_month'];
  print('$year-$monthNum: ${month['count']['*']} commandes, ${month['sum']['total']}€');
}
```

### Utilisateurs actifs

```dart
final activeUsers = await client.items('user_sessions').readMany(
  query: QueryParameters(
    aggregate: Aggregate()..countDistinct(['user_id']),
    filter: Filter.field('last_activity').greaterThan(
      DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
    ),
  ),
);

final count = activeUsers.data.first['countDistinct']['user_id'];
print('Utilisateurs actifs (30j): $count');
```

### Top catégories

```dart
final topCategories = await client.items('order_items').readMany(
  query: QueryParameters(
    aggregate: Aggregate()..sum(['total']),
    groupBy: GroupBy.fields(['product.category.name']),
    sort: ['-sum.total'],  // Tri par somme décroissante
    limit: 5,
  ),
);

print('Top 5 catégories:');
for (final cat in topCategories.data) {
  print('- ${cat['product']['category']['name']}: ${cat['sum']['total']}€');
}
```

## Combinaison avec filtres

Les agrégations peuvent être filtrées :

```dart
// Statistiques des produits en stock
final inStockStats = await client.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count(['*'])
      ..avg(['price']),
    filter: Filter.and([
      Filter.field('status').equals('active'),
      Filter.field('stock').greaterThan(0),
    ]),
  ),
);
```

## Accès aux résultats

### Structure des données

```dart
final response = await client.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count(['*'])
      ..sum(['price']),
  ),
);

// response.data contient une liste avec les agrégations
final result = response.data.first;

// Accès aux valeurs
final count = result['count']['*'];        // int ou String selon Directus
final sum = result['sum']['price'];        // double ou String
```

### Avec GroupBy

```dart
final response = await client.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()..count(['*']),
    groupBy: GroupBy.fields(['category']),
  ),
);

// response.data contient une liste par groupe
for (final group in response.data) {
  final category = group['category'];      // Valeur du groupe
  final count = group['count']['*'];       // Agrégation
}
```

## Helper pour parser les résultats

```dart
class AggregateResult {
  final Map<String, dynamic> _data;
  
  AggregateResult(this._data);
  
  int? getCount([String field = '*']) => 
    int.tryParse(_data['count']?[field]?.toString() ?? '');
  
  int? getCountDistinct(String field) =>
    int.tryParse(_data['countDistinct']?[field]?.toString() ?? '');
  
  double? getSum(String field) =>
    double.tryParse(_data['sum']?[field]?.toString() ?? '');
  
  double? getAvg(String field) =>
    double.tryParse(_data['avg']?[field]?.toString() ?? '');
  
  double? getMin(String field) =>
    double.tryParse(_data['min']?[field]?.toString() ?? '');
  
  double? getMax(String field) =>
    double.tryParse(_data['max']?[field]?.toString() ?? '');
}

// Utilisation
final response = await client.items('products').readMany(...);
final result = AggregateResult(response.data.first);

print('Count: ${result.getCount()}');
print('Average price: ${result.getAvg('price')}');
```

## Bonnes pratiques

### 1. Combiner avec des filtres

Agrégez uniquement les données pertinentes :

```dart
// ❌ Agrège tout puis filtre côté client
final all = await client.items('orders').readMany(
  query: QueryParameters(
    aggregate: Aggregate()..sum(['total']),
  ),
);

// ✅ Filtre côté serveur
final completed = await client.items('orders').readMany(
  query: QueryParameters(
    aggregate: Aggregate()..sum(['total']),
    filter: Filter.field('status').equals('completed'),
  ),
);
```

### 2. Utiliser countDistinct pour les métriques uniques

```dart
// Nombre d'utilisateurs uniques
Aggregate()..countDistinct(['user_id'])

// vs Nombre total de lignes
Aggregate()..count(['*'])
```

### 3. Limiter les groupBy

Trop de groupes peuvent surcharger les résultats :

```dart
// ✅ Limiter le nombre de groupes retournés
final query = QueryParameters(
  aggregate: Aggregate()..sum(['total']),
  groupBy: GroupBy.fields(['category']),
  sort: ['-sum.total'],
  limit: 10,  // Top 10 seulement
);
```

### 4. Cacher les résultats

Les agrégations sur de grandes collections peuvent être coûteuses :

```dart
// Cacher les stats pour 5 minutes
final stats = await getCachedStats() ?? await fetchStats();

Future<Map<String, dynamic>> fetchStats() async {
  final response = await client.items('products').readMany(
    query: QueryParameters(
      aggregate: Aggregate()..count(['*'])..avg(['price']),
    ),
  );
  await cacheStats(response.data.first, Duration(minutes: 5));
  return response.data.first;
}
```

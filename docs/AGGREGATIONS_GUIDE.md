# Guide des Agrégations Directus

Ce guide explique comment utiliser les agrégations dans `fcs_directus` pour effectuer des calculs statistiques sur vos collections.

## Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Agrégations disponibles](#agrégations-disponibles)
- [GroupBy](#groupby)
- [Fonctions de date](#fonctions-de-date)
- [Variables dynamiques](#variables-dynamiques)
- [Exemples pratiques](#exemples-pratiques)

## Vue d'ensemble

Les agrégations permettent d'effectuer des calculs statistiques sur des ensembles de données, comme compter le nombre d'éléments, calculer des moyennes, trouver des valeurs minimales/maximales, etc.

### Agrégation simple

```dart
final response = await client.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count(['*'])
      ..avg(['price'])
      ..sum(['stock']),
  ),
);
```

## Agrégations disponibles

### count()
Compte le nombre d'éléments ou de valeurs dans un champ.

```dart
// Compter tous les items
Aggregate()..count(['*'])

// Compter les valeurs de champs spécifiques
Aggregate()..count(['id', 'title'])
```

### countDistinct()
Compte le nombre de valeurs uniques dans un champ.

```dart
// Nombre de catégories uniques
Aggregate()..countDistinct(['category'])

// Nombre de clients uniques ayant commandé
Aggregate()..countDistinct(['customer_id'])
```

### countAll()
Compte tous les éléments (optimisé pour la performance).

```dart
Aggregate()..countAll()
```

### sum()
Calcule la somme des valeurs numériques.

```dart
// Total des ventes
Aggregate()..sum(['amount'])

// Somme de plusieurs champs
Aggregate()..sum(['price', 'tax', 'shipping'])
```

### sumDistinct()
Calcule la somme des valeurs uniques.

```dart
Aggregate()..sumDistinct(['discount_amount'])
```

### avg()
Calcule la moyenne des valeurs numériques.

```dart
// Prix moyen
Aggregate()..avg(['price'])

// Note moyenne
Aggregate()..avg(['rating'])
```

### avgDistinct()
Calcule la moyenne des valeurs uniques.

```dart
Aggregate()..avgDistinct(['rating'])
```

### min()
Trouve la valeur minimale.

```dart
// Prix le plus bas
Aggregate()..min(['price'])
```

### max()
Trouve la valeur maximale.

```dart
// Prix le plus élevé
Aggregate()..max(['price'])
```

### Combinaison d'agrégations

Vous pouvez combiner plusieurs agrégations dans une seule requête :

```dart
final response = await client.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count(['*'])
      ..sum(['price', 'stock'])
      ..avg(['rating'])
      ..min(['price'])
      ..max(['price']),
  ),
);
```

## GroupBy

Le `GroupBy` permet de regrouper les résultats par un ou plusieurs champs avant d'appliquer les agrégations.

### Regroupement simple

```dart
// Nombre de produits par catégorie
final response = await client.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()..count(['*']),
    groupBy: GroupBy.fields(['category']),
  ),
);
```

### Regroupement multiple

```dart
// Ventes par catégorie et par vendeur
final response = await client.items('orders').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count(['*'])
      ..sum(['amount']),
    groupBy: GroupBy.fields(['category', 'seller_id']),
  ),
);
```

### Tri des résultats groupés

```dart
// Top catégories par chiffre d'affaires
final response = await client.items('orders').readMany(
  query: QueryParameters(
    aggregate: Aggregate()..sum(['amount']),
    groupBy: GroupBy.fields(['category']),
    sort: ['-sum.amount'], // Trier par somme décroissante
    limit: 10,
  ),
);
```

## Fonctions de date

La classe `Func` fournit des fonctions pour extraire des parties de dates, utilisables dans les filtres et les regroupements.

### Fonctions disponibles

| Fonction | Description | Exemple |
|----------|-------------|---------|
| `year(field)` | Année (2024) | `Func.year('date_created')` |
| `month(field)` | Mois (1-12) | `Func.month('date_created')` |
| `week(field)` | Semaine (1-53) | `Func.week('date_created')` |
| `day(field)` | Jour du mois (1-31) | `Func.day('date_created')` |
| `weekday(field)` | Jour de la semaine (0-6) | `Func.weekday('date_created')` |
| `hour(field)` | Heure (0-23) | `Func.hour('timestamp')` |
| `minute(field)` | Minute (0-59) | `Func.minute('timestamp')` |
| `second(field)` | Seconde (0-59) | `Func.second('timestamp')` |
| `count(field)` | Compte les éléments d'un array/JSON | `Func.count('tags')` |

### Filtrage par date

```dart
// Articles publiés en 2024
Filter.field(Func.year('published_at')).equals(2024)

// Événements en décembre
Filter.field(Func.month('event_date')).equals(12)

// Activité entre 9h et 17h
Filter.and([
  Filter.field(Func.hour('created_at')).greaterThanOrEqual(9),
  Filter.field(Func.hour('created_at')).lessThan(17),
])

// Week-end (samedi = 6, dimanche = 0)
Filter.or([
  Filter.field(Func.weekday('event_date')).equals(0),
  Filter.field(Func.weekday('event_date')).equals(6),
])
```

### Regroupement par période

```dart
// Ventes par année
GroupBy.fields([Func.year('created_at')])

// Statistiques mensuelles
GroupBy.fields([
  Func.year('created_at'),
  Func.month('created_at'),
])

// Activité par jour de la semaine
GroupBy.fields([Func.weekday('created_at')])

// Analyse horaire
GroupBy.fields([Func.hour('created_at')])
```

## Variables dynamiques

Les variables dynamiques sont remplacées par Directus au moment de l'exécution de la requête.

### Variables disponibles

| Variable | Valeur | Utilisation |
|----------|--------|-------------|
| `DynamicVar.now` | Timestamp actuel | Filtres de date |
| `DynamicVar.currentTimestamp` | Timestamp actuel (alias) | Filtres de date |
| `DynamicVar.currentUser` | ID de l'utilisateur connecté | Filtres utilisateur |
| `DynamicVar.currentRole` | ID du rôle de l'utilisateur | Filtres par rôle |
| `DynamicVar.currentPolicies` | Politiques de l'utilisateur | Filtres de permissions |

### Exemples d'utilisation

```dart
// Éléments non expirés
Filter.field('expires_at').greaterThan(DynamicVar.now)

// Mes tâches
Filter.field('assigned_to').equals(DynamicVar.currentUser)

// Documents accessibles à mon rôle
Filter.field('required_role').equals(DynamicVar.currentRole)

// Événements en cours
Filter.and([
  Filter.field('start_date').lessThanOrEqual(DynamicVar.now),
  Filter.field('end_date').greaterThanOrEqual(DynamicVar.now),
])
```

## Exemples pratiques

### 1. Statistiques globales

```dart
final stats = await client.items('products').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..countAll()
      ..sum(['price'])
      ..avg(['rating'])
      ..min(['price'])
      ..max(['price']),
  ),
);
```

### 2. Analyse des ventes par période

```dart
// Ventes mensuelles 2024
final sales = await client.items('orders').readMany(
  query: QueryParameters(
    filter: Filter.field(Func.year('created_at')).equals(2024),
    aggregate: Aggregate()
      ..count(['*'])
      ..sum(['amount']),
    groupBy: GroupBy.fields([Func.month('created_at')]),
    sort: [Func.month('created_at')],
  ),
);
```

### 3. Top produits par catégorie

```dart
final topProducts = await client.items('orders').readMany(
  query: QueryParameters(
    aggregate: Aggregate()
      ..count(['*'])
      ..sum(['amount']),
    groupBy: GroupBy.fields(['product_id', 'category']),
    sort: ['-sum.amount'],
    limit: 10,
  ),
);
```

### 4. Clients actifs ce mois

```dart
final activeCustomers = await client.items('orders').readMany(
  query: QueryParameters(
    filter: Filter.and([
      Filter.field(Func.year('created_at')).equals(2024),
      Filter.field(Func.month('created_at')).equals(10),
    ]),
    aggregate: Aggregate()..countDistinct(['customer_id']),
  ),
);
```

### 5. Analyse horaire de l'activité

```dart
final hourlyActivity = await client.items('events').readMany(
  query: QueryParameters(
    aggregate: Aggregate()..count(['*']),
    groupBy: GroupBy.fields([Func.hour('created_at')]),
    sort: [Func.hour('created_at')],
  ),
);
```

### 6. Mes tâches urgentes

```dart
final urgentTasks = await client.items('tasks').readMany(
  query: QueryParameters(
    filter: Filter.and([
      Filter.field('assigned_to').equals(DynamicVar.currentUser),
      Filter.field('due_date').lessThan(DynamicVar.now),
      Filter.field('status').notEquals('completed'),
    ]),
    sort: ['due_date'],
  ),
);
```

## Référence complète des opérations

### Agrégations

| Opération | Accepte wildcard (*) | Type de résultat |
|-----------|---------------------|------------------|
| `count` | ✅ Oui | nombre |
| `countDistinct` | ❌ Non | nombre |
| `countAll` | N/A | nombre |
| `sum` | ❌ Non | nombre |
| `sumDistinct` | ❌ Non | nombre |
| `avg` | ❌ Non | nombre |
| `avgDistinct` | ❌ Non | nombre |
| `min` | ❌ Non | même type que le champ |
| `max` | ❌ Non | même type que le champ |

### Fonctions de date/temps

Toutes les fonctions de date retournent un entier représentant la partie extraite :

- **year**: 2024, 2025, etc.
- **month**: 1-12 (janvier=1, décembre=12)
- **week**: 1-53
- **day**: 1-31
- **weekday**: 0-6 (dimanche=0, samedi=6)
- **hour**: 0-23
- **minute**: 0-59
- **second**: 0-59

## Bonnes pratiques

### 1. Combinez avec des filtres

Toujours filtrer avant d'agréger pour de meilleures performances :

```dart
QueryParameters(
  filter: Filter.field('status').equals('active'),
  aggregate: Aggregate()..count(['*']),
)
```

### 2. Limitez les résultats groupés

Utilisez `limit` pour éviter de récupérer trop de groupes :

```dart
QueryParameters(
  aggregate: Aggregate()..sum(['amount']),
  groupBy: GroupBy.fields(['category']),
  limit: 10,
)
```

### 3. Triez les résultats

Triez les résultats agrégés pour une meilleure lisibilité :

```dart
QueryParameters(
  aggregate: Aggregate()..count(['*']),
  groupBy: GroupBy.fields(['category']),
  sort: ['-count.*'], // Tri décroissant par comptage
)
```

### 4. Utilisez countDistinct judicieusement

`countDistinct` est plus lent que `count`, utilisez-le seulement quand nécessaire.

### 5. Variables dynamiques pour les filtres utilisateur

Utilisez toujours les variables dynamiques pour les filtres basés sur l'utilisateur connecté :

```dart
// ✅ BON
Filter.field('owner').equals(DynamicVar.currentUser)

// ❌ MAUVAIS (ID en dur)
Filter.field('owner').equals('123')
```

## Performance

### Optimisations

1. **Filtrez d'abord**: Réduisez l'ensemble de données avant l'agrégation
2. **Index appropriés**: Assurez-vous que les champs utilisés dans `groupBy` sont indexés
3. **Limitez les groupes**: Utilisez `limit` pour éviter trop de groupes
4. **countAll vs count(*)**: `countAll` est optimisé pour compter tous les éléments

### Évitez

- Agréger sur des millions de lignes sans filtre
- Regrouper par des champs avec trop de valeurs uniques
- Multiplier les agrégations complexes dans une seule requête

## Voir aussi

- [FILTERS_GUIDE.md](./FILTERS_GUIDE.md) - Guide complet des filtres
- [DEEP_GUIDE.md](./DEEP_GUIDE.md) - Guide des relations profondes
- [Documentation Directus officielle](https://docs.directus.io/reference/query.html)

# Filtrage sur champs imbriqués (Nested Fields)

## ✅ Réponse rapide

**Oui, la fonctionnalité existe et fonctionne avec la syntaxe Directus correcte !**

La notation pointée pour filtrer sur les sous-champs des relations est **supportée** par la librairie `fcs_directus` et **crée automatiquement la structure JSON imbriquée** requise par Directus.

## 🔑 Point important

La notation pointée `Filter.field('departement.region')` **crée automatiquement une structure JSON imbriquée** :

```dart
Filter.field('departement.region').equals('region-idf')
```

Génère le JSON suivant :
```json
{
  "departement": {
    "region": {
      "_eq": "region-idf"
    }
  }
}
```

Cette structure imbriquée est la **syntaxe correcte pour Directus** lors du filtrage sur des relations.

## 📖 Utilisation

### Syntaxe de base

```dart
// Champ direct
Filter.field("departement").equals(departementId)

// Champ de relation (notation pointée - crée une structure imbriquée)
Filter.field("departement.region").equals(regionId)

// Champs profondément imbriqués
Filter.field("departement.region.pays").equals(paysId)
```

### Comment ça fonctionne

1. **La classe `FieldFilter`** accepte n'importe quel `String` comme nom de champ
2. **La notation pointée** détecte automatiquement le `.` et crée une structure JSON imbriquée
3. **Directus reçoit** une structure JSON imbriquée conforme à son API

## 🎯 Exemples pratiques

### Exemple 1: Filtrage par département

```dart
// Communes d'un département spécifique
final filter = Filter.field('departement').equals('dept-75');

final communes = await client.items('commune').readMany(
  query: QueryParameters(
    filter: filter,
    fields: ['*', 'departement.*'],
  ),
);
```

**JSON généré:**
```json
{
  "departement": {"_eq": "dept-75"}
}
```

### Exemple 2: Filtrage par code département (champ nested)

```dart
// Communes avec code département = "75"
final filter = Filter.field('departement.code').equals('75');

final communes = await client.items('commune').readMany(
  query: QueryParameters(
    filter: filter,
    fields: ['*', 'departement.*'],
  ),
);
```

**JSON généré:**
```json
{
  "departement": {
    "code": {"_eq": "75"}
  }
}
```

### Exemple 3: Filtrage par région (via département)

```dart
// Communes d'une région spécifique
final filter = Filter.field('departement.region').equals('region-idf');

final communes = await client.items('commune').readMany(
  query: QueryParameters(
    filter: filter,
    fields: ['*', 'departement.region.*'],
  ),
);
```

**JSON généré:**
```json
{
  "departement": {
    "region": {"_eq": "region-idf"}
  }
}
```

### Exemple 4: Filtrage complexe avec combinaisons

```dart
// Brigades d'une région avec recherche textuelle
final filter = Filter.and([
  Filter.field('departement.region').equals('region-idf'),
  Filter.field('nom').containsInsensitive('central'),
  Filter.field('active').equals(true),
]);

final brigades = await client.items('brigade').readMany(
  query: QueryParameters(
    filter: filter,
    fields: ['*', 'departement.*', 'departement.region.*'],
  ),
);
```

**JSON généré:**
```json
{
  "_and": [
    {"departement.region": {"_eq": "region-idf"}},
    {"nom": {"_icontains": "central"}},
    {"active": {"_eq": true}}
  ]
}
```

### Exemple 5: Filtrage sur plusieurs niveaux

```dart
// Profondeur illimitée
final filter = Filter.field('departement.region.pays.continent').equals('europe');
```

**JSON généré:**
```json
{
  "departement.region.pays.continent": {"_eq": "europe"}
}
```

## 🔧 Tous les opérateurs supportés

Tous les opérateurs de `FieldFilter` fonctionnent avec la notation pointée :

```dart
// Comparaisons
Filter.field('departement.population').greaterThan(100000)
Filter.field('departement.code').lessThanOrEqual('99')

// Collections
Filter.field('departement.code').inList(['75', '92', '93'])
Filter.field('departement.region.code').notInList(['01', '02'])

// Chaînes de caractères
Filter.field('departement.region.nom').contains('Provence')
Filter.field('departement.nom').startsWith('Paris')
Filter.field('departement.code').endsWith('5')

// Insensible à la casse
Filter.field('departement.region.nom').containsInsensitive('île')

// Null checks
Filter.field('departement.region').isNotNull()
Filter.field('departement.region.description').isEmpty()

// Géographiques (si applicable)
Filter.field('departement.region.geometry').intersects(polygone)
```

## 📝 Bonnes pratiques

### 1. Charger les relations nécessaires

Pensez à inclure les champs des relations dans `fields` :

```dart
final communes = await client.items('commune').readMany(
  query: QueryParameters(
    filter: Filter.field('departement.region').equals('region-idf'),
    // ⚠️ Important: charger les données des relations
    fields: ['*', 'departement.*', 'departement.region.*'],
  ),
);
```

### 2. Créer des helpers réutilisables

Pour plus de lisibilité, créez des fonctions helper :

```dart
class GeoFilters {
  static Filter byRegion(String regionId) {
    return Filter.field('departement.region').equals(regionId);
  }

  static Filter byDepartementCode(String code) {
    return Filter.field('departement.code').equals(code);
  }

  static Filter byRegionName(String nomRegion) {
    return Filter.field('departement.region.nom').equals(nomRegion);
  }
}

// Utilisation
final filter = GeoFilters.byRegion('region-idf');
```

### 3. Combiner avec d'autres filtres

Les filtres imbriqués se combinent facilement :

```dart
final filter = Filter.and([
  GeoFilters.byRegion('region-idf'),
  Filter.field('population').greaterThan(10000),
  Filter.field('active').equals(true),
]);
```

## 🎓 Comprendre la structure

### Cas d'usage type: Commune → Département → Région

**Structure des données:**
```
Commune {
  id: string
  nom: string
  departement: Departement {        // Relation Many-to-One
    id: string
    nom: string
    code: string
    region: Region {                // Relation Many-to-One
      id: string
      nom: string
      code: string
    }
  }
}
```

**Filtres possibles:**

| Filtre | Description | JSON |
|--------|-------------|------|
| `Filter.field('departement').equals('id')` | Par ID de département | `{"departement": {"_eq": "id"}}` |
| `Filter.field('departement.code').equals('75')` | Par code de département | `{"departement.code": {"_eq": "75"}}` |
| `Filter.field('departement.nom').contains('Paris')` | Par nom de département | `{"departement.nom": {"_contains": "Paris"}}` |
| `Filter.field('departement.region').equals('id')` | Par ID de région | `{"departement.region": {"_eq": "id"}}` |
| `Filter.field('departement.region.code').equals('11')` | Par code de région | `{"departement.region.code": {"_eq": "11"}}` |
| `Filter.field('departement.region.nom').contains('France')` | Par nom de région | `{"departement.region.nom": {"_contains": "France"}}` |

## ⚠️ Limitations et notes

### 1. Performance

- Les filtres sur champs imbriqués peuvent être plus lents
- Directus doit faire des JOINs en base de données
- Ajoutez des index sur les colonnes fréquemment filtrées

### 2. Relations Many-to-Many

Pour les relations M2M, utilisez plutôt `Filter.some()` :

```dart
// ❌ Ne fonctionne pas pour M2M
Filter.field('tags.name').equals('urgent')

// ✅ Correct pour M2M
Filter.some('tags').where(
  Filter.field('name').equals('urgent')
)
```

### 3. Profondeur maximale

Directus limite généralement la profondeur des relations à 3-4 niveaux pour des raisons de performance.

## 🧪 Tests

Voir le fichier d'exemple complet : `example/example_nested_field_filters.dart`

## 📚 Références

- [Documentation Directus - Filter Rules](https://docs.directus.io/reference/filter-rules.html)
- [Documentation Directus - Relational Data](https://docs.directus.io/app/data-model/relationships.html)
- Code source: `lib/src/models/directus_filter.dart`

## 💡 Résumé

✅ **La notation pointée fonctionne déjà**  
✅ **Aucune modification nécessaire**  
✅ **Tous les opérateurs sont supportés**  
✅ **Profondeur illimitée (en théorie)**  
✅ **Compatible avec les combinaisons de filtres**  

Vous pouvez utiliser `Filter.field("departement.region").equals(regionId)` dès maintenant dans votre code !

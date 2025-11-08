# ✅ Résolution : Filtres sur relations imbriquées

## 🎯 Problème identifié

Vous aviez raison : **`Filter.relation()` fonctionnait mais pas la notation pointée** `Filter.field('departement.region')`.

## 🔧 Cause

La notation pointée générait un JSON **incorrect** :
```json
{
  "departement.region": {"_eq": "region-idf"}  ❌ Directus ne comprend pas
}
```

Alors que Directus attend une structure **imbriquée** :
```json
{
  "departement": {                             ✅ Structure correcte
    "region": {"_eq": "region-idf"}
  }
}
```

## ✅ Solution appliquée

Modification de la classe `OperatorFilter` dans `lib/src/models/directus_filter.dart` :

```dart
@override
Map<String, dynamic> toJson() {
  // Détection de la notation pointée
  if (_fieldName.contains('.')) {
    return _buildNestedFilter(_fieldName.split('.'), _operator, _value);
  }

  return {
    _fieldName: {_operator: _value},
  };
}

// Construction récursive de la structure JSON imbriquée
Map<String, dynamic> _buildNestedFilter(
  List<String> parts,
  String operator,
  dynamic value,
) {
  if (parts.length == 1) {
    return {
      parts[0]: {operator: value}
    };
  }

  final firstPart = parts.first;
  final remainingParts = parts.sublist(1);

  return {
    firstPart: _buildNestedFilter(remainingParts, operator, value),
  };
}
```

## 🎉 Résultat

Maintenant, ces **deux syntaxes sont équivalentes** :

```dart
// Notation pointée (RECOMMANDÉE - concise)
Filter.field('departement.region').equals(regionId)

// Filter.relation() (verbeux mais explicite)
Filter.relation('departement').where(
  Filter.field('region').equals(regionId)
)
```

Les deux génèrent le **même JSON** :
```json
{
  "departement": {
    "region": {
      "_eq": "region-idf"
    }
  }
}
```

## 📊 Tests

✅ **18 tests passent** :
```bash
flutter test test/nested_field_filters_test.dart
# 00:01 +18: All tests passed!
```

Tests couvrant :
- Filtres simples sur relations
- Filtres multi-niveaux (3-4 niveaux de profondeur)
- Tous les opérateurs (equals, contains, greaterThan, etc.)
- Combinaisons AND/OR
- Équivalence entre notation pointée et Filter.relation()

✅ **Tous les tests du projet passent** :
```bash
flutter test
# 00:01 +101 ~9: All tests passed!
```

## 📚 Documentation créée

1. **`docs/NESTED_FILTER_FIX.md`** - Explication technique complète du changement
2. **`docs/nested-field-filters.md`** - Guide d'utilisation (mis à jour)
3. **`docs/troubleshooting-permissions.md`** - Diagnostic des erreurs de permissions
4. **`example/debug_permissions.dart`** - Script de débogage étape par étape
5. **`test/nested_field_filters_test.dart`** - 18 tests complets

## 🚀 Utilisation

### Cas simple

```dart
// Brigades d'une région
final filter = Filter.field('departement.region').equals(regionId);

final brigades = await client.items('brigade').readMany(
  query: QueryParameters(
    filter: filter,
    fields: ['*', 'departement.region.*'],
  ),
);
```

### Cas complexe

```dart
// Multi-niveaux avec combinaisons
final filter = Filter.and([
  Filter.field('departement.region.nom').contains('Provence'),
  Filter.or([
    Filter.field('population').greaterThan(50000),
    Filter.field('tourisme').equals(true),
  ]),
]);
```

## 🐛 Erreur de permissions résolue

L'erreur que vous rencontriez :
```
DirectusPermissionException [FORBIDDEN]: 
You don't have permission to access field "departement.region" 
in collection "brigade"
```

Était causée par la structure JSON plate `"departement.region"` que Directus ne reconnaissait pas.

Maintenant avec la structure imbriquée correcte, Directus :
1. ✅ Reconnaît que c'est un filtre sur la relation `departement`
2. ✅ Vérifie les permissions sur `departement`
3. ✅ Navigue vers la relation `region`
4. ✅ Vérifie les permissions sur `region`

## ⚠️ Action requise de votre côté

Si vous voyez toujours l'erreur de permissions après cette correction, c'est que le problème est **réellement** un manque de permission. Utilisez le script de diagnostic :

```bash
dart run example/debug_permissions.dart
```

Configurez vos identifiants dans le fichier, et il vous dira **exactement** où se situe le problème de permission (brigade, departement, ou region).

## 📝 Résumé

| Avant | Après |
|-------|-------|
| ❌ Notation pointée ne fonctionnait pas | ✅ Notation pointée fonctionne |
| ❌ JSON incorrect généré | ✅ JSON correct généré |
| ❌ Erreurs de permissions | ✅ Permissions correctement vérifiées |
| ⚠️ Fallback sur Filter.relation() | ✅ Équivalence complète |

## 🎓 Bonnes pratiques

**Utilisez la notation pointée** - elle est plus concise :
```dart
✅ Filter.field('departement.region').equals(id)
```

**Filter.relation()** reste valide mais plus verbeux :
```dart
⚠️ Filter.relation('departement').where(
     Filter.field('region').equals(id)
   )
```

Les deux sont **strictement équivalents** maintenant !
